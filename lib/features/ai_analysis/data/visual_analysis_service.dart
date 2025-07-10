import 'dart:io';
import 'dart:typed_data';
import 'dart:isolate';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:image/image.dart' as img;
import '../../../core/services/ml_model_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/video_model.dart';
import '../../../shared/models/highlight_event.dart';

class VisualAnalysisService {
  final MLModelService _mlService = MLModelService.instance;
  final StorageService _storageService = StorageService.instance;

  Future<List<HighlightEvent>> analyzeVideoFrames(VideoModel video) async {
    try {
      AppLogger.info('Starting visual analysis for: ${video.name}');
      
      // Extract frames from video at regular intervals
      final framePaths = await _extractFramesFromVideo(video.path);
      
      // Analyze each frame for cricket events
      final visualEvents = await _analyzeFramesInBatches(framePaths, video.id);
      
      // Convert visual events to highlight events
      final highlightEvents = await _convertVisualToHighlightEvents(visualEvents, video.id);
      
      // Clean up temporary frame files
      await _cleanupFrames(framePaths);
      
      AppLogger.info('Visual analysis completed. Found ${highlightEvents.length} events');
      return highlightEvents;
      
    } catch (e) {
      AppLogger.error('Visual analysis failed', e);
      rethrow;
    }
  }

  Future<List<String>> _extractFramesFromVideo(String videoPath) async {
    final framesDir = '${_storageService.tempPath}/frames_${DateTime.now().millisecondsSinceEpoch}';
    final framesDirFile = Directory(framesDir);
    await framesDirFile.create(recursive: true);
    
    // Extract one frame every 2 seconds
    final command = '-i "$videoPath" -vf "fps=0.5" "$framesDir/frame_%04d.jpg"';
    
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    
    if (!ReturnCode.isSuccess(returnCode)) {
      throw Exception('Failed to extract frames from video');
    }
    
    // Get list of extracted frame files
    final frameFiles = await framesDirFile.list().toList();
    final framePaths = frameFiles
        .where((file) => file.path.endsWith('.jpg'))
        .map((file) => file.path)
        .toList();
    
    framePaths.sort(); // Ensure chronological order
    return framePaths;
  }

  Future<List<VisualEvent>> _analyzeFramesInBatches(List<String> framePaths, String videoId) async {
    final allVisualEvents = <VisualEvent>[];
    const batchSize = 10; // Process 10 frames at a time
    
    for (int i = 0; i < framePaths.length; i += batchSize) {
      final batchEnd = (i + batchSize < framePaths.length) ? i + batchSize : framePaths.length;
      final batch = framePaths.sublist(i, batchEnd);
      
      // Process batch in isolate for better performance
      final batchEvents = await _processBatchInIsolate(batch, i);
      allVisualEvents.addAll(batchEvents);
      
      // Update progress (could emit progress events here)
      final progress = (i + batchSize) / framePaths.length;
      AppLogger.debug('Visual analysis progress: ${(progress * 100).toInt()}%');
    }
    
    return _filterAndMergeVisualEvents(allVisualEvents);
  }

  Future<List<VisualEvent>> _processBatchInIsolate(List<String> framePaths, int startIndex) async {
    final receivePort = ReceivePort();
    
    await Isolate.spawn(_isolateEntryPoint, {
      'sendPort': receivePort.sendPort,
      'framePaths': framePaths,
      'startIndex': startIndex,
    });
    
    final result = await receivePort.first as List<VisualEvent>;
    return result;
  }

  static void _isolateEntryPoint(Map<String, dynamic> params) async {
    final sendPort = params['sendPort'] as SendPort;
    final framePaths = params['framePaths'] as List<String>;
    final startIndex = params['startIndex'] as int;
    
    try {
      final events = <VisualEvent>[];
      
      for (int i = 0; i < framePaths.length; i++) {
        final framePath = framePaths[i];
        final frameEvents = await _analyzeFrame(framePath, startIndex + i);
        events.addAll(frameEvents);
      }
      
      sendPort.send(events);
    } catch (e) {
      sendPort.send(<VisualEvent>[]);
    }
  }

  static Future<List<VisualEvent>> _analyzeFrame(String framePath, int frameIndex) async {
    try {
      final frameFile = File(framePath);
      final frameBytes = await frameFile.readAsBytes();
      
      // Resize image for ML model
      final image = img.decodeImage(frameBytes);
      if (image == null) return [];
      
      final resizedImage = img.copyResize(image, width: 224, height: 224);
      final imageBytes = Uint8List.fromList(img.encodeJpg(resizedImage));
      
      // Use ML model to analyze frame
      final mlService = MLModelService.instance;
      final events = await mlService.analyzeVideoFrame(imageBytes);
      
      // Add frame timing information
      final frameTime = frameIndex * 2.0; // 2 seconds per frame
      for (final event in events) {
        event.timestamp = DateTime.fromMillisecondsSinceEpoch((frameTime * 1000).round());
      }
      
      return events;
    } catch (e) {
      return [];
    }
  }

  List<VisualEvent> _filterAndMergeVisualEvents(List<VisualEvent> events) {
    if (events.isEmpty) return events;
    
    // Group events by type and merge nearby events
    final groupedEvents = <VisualEventType, List<VisualEvent>>{};
    
    for (final event in events) {
      groupedEvents.putIfAbsent(event.type, () => []).add(event);
    }
    
    final mergedEvents = <VisualEvent>[];
    
    for (final eventGroup in groupedEvents.values) {
      eventGroup.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      VisualEvent? currentEvent;
      for (final event in eventGroup) {
        if (currentEvent == null ||
            event.timestamp.difference(currentEvent.timestamp).inSeconds > 5) {
          if (currentEvent != null) {
            mergedEvents.add(currentEvent);
          }
          currentEvent = event;
        } else if (event.confidence > currentEvent.confidence) {
          currentEvent = event;
        }
      }
      
      if (currentEvent != null) {
        mergedEvents.add(currentEvent);
      }
    }
    
    return mergedEvents;
  }

  Future<List<HighlightEvent>> _convertVisualToHighlightEvents(
    List<VisualEvent> visualEvents,
    String videoId,
  ) async {
    final highlightEvents = <HighlightEvent>[];
    
    for (final visualEvent in visualEvents) {
      final eventType = _mapVisualEventToHighlightEvent(visualEvent.type);
      final startTime = visualEvent.timestamp.millisecondsSinceEpoch ~/ 1000;
      
      final highlightEvent = HighlightEvent(
        id: _generateEventId(),
        videoId: videoId,
        eventType: eventType,
        startTimeSeconds: startTime - 3, // 3 seconds before
        endTimeSeconds: startTime + 12,  // 12 seconds after
        confidence: visualEvent.confidence,
        description: _getVisualEventDescription(visualEvent.type),
        detectedAt: DateTime.now(),
      );
      
      highlightEvents.add(highlightEvent);
    }
    
    return highlightEvents;
  }

  EventType _mapVisualEventToHighlightEvent(VisualEventType visualType) {
    switch (visualType) {
      case VisualEventType.celebration:
        return EventType.celebration;
      case VisualEventType.battingStance:
        return EventType.batHit;
      case VisualEventType.bowlingAction:
        return EventType.wicket;
      case VisualEventType.fieldingAction:
        return EventType.boundary;
      case VisualEventType.wicketFall:
        return EventType.wicket;
    }
  }

  String _getVisualEventDescription(VisualEventType type) {
    switch (type) {
      case VisualEventType.celebration:
        return 'Player celebration detected';
      case VisualEventType.battingStance:
        return 'Batting action detected';
      case VisualEventType.bowlingAction:
        return 'Bowling action detected';
      case VisualEventType.fieldingAction:
        return 'Fielding action detected';
      case VisualEventType.wicketFall:
        return 'Wicket fall detected';
    }
  }

  Future<void> _cleanupFrames(List<String> framePaths) async {
    for (final framePath in framePaths) {
      final file = File(framePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    
    // Also clean up the frames directory
    if (framePaths.isNotEmpty) {
      final framesDir = Directory(File(framePaths.first).parent.path);
      if (await framesDir.exists()) {
        await framesDir.delete(recursive: true);
      }
    }
  }

  String _generateEventId() {
    return 'visual_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (999 * (DateTime.now().microsecond / 1000000))).round()}';
  }
}
