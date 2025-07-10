import 'dart:io';
import 'dart:typed_data';
import 'dart:isolate';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import '../../../core/services/ml_model_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/video_model.dart';
import '../../../shared/models/highlight_event.dart';

class AudioAnalysisService {
  final MLModelService _mlService = MLModelService.instance;
  final StorageService _storageService = StorageService.instance;

  Future<List<HighlightEvent>> analyzeVideoAudio(VideoModel video) async {
    try {
      AppLogger.info('Starting advanced audio analysis for: ${video.name}');
      
      // Extract audio from video
      final audioPath = await _extractAudioFromVideo(video.path);
      
      // Process audio in segments
      final audioEvents = await _processAudioInSegments(audioPath, video.id);
      
      // Convert audio events to highlight events
      final highlightEvents = await _convertToHighlightEvents(audioEvents, video.id);
      
      // Clean up temporary audio file
      final audioFile = File(audioPath);
      if (await audioFile.exists()) {
        await audioFile.delete();
      }
      
      AppLogger.info('Audio analysis completed. Found ${highlightEvents.length} events');
      return highlightEvents;
      
    } catch (e) {
      AppLogger.error('Audio analysis failed', e);
      rethrow;
    }
  }

  Future<String> _extractAudioFromVideo(String videoPath) async {
    final tempAudioPath = '${_storageService.tempPath}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
    
    // Use FFmpeg to extract audio as WAV for processing
    final command = '-i "$videoPath" -vn -acodec pcm_s16le -ar 16000 -ac 1 "$tempAudioPath"';
    
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    
    if (!ReturnCode.isSuccess(returnCode)) {
      throw Exception('Failed to extract audio from video');
    }
    
    return tempAudioPath;
  }

  Future<List<AudioEvent>> _processAudioInSegments(String audioPath, String videoId) async {
    final audioFile = File(audioPath);
    final audioBytes = await audioFile.readAsBytes();
    
    // Convert bytes to Float32List for processing
    final audioData = _convertBytesToFloat32(audioBytes);
    
    // Process in 1-second segments with overlap
    const segmentSize = 16000; // 1 second at 16kHz
    const overlapSize = 1600;  // 0.1 second overlap
    
    final allEvents = <AudioEvent>[];
    
    for (int i = 0; i < audioData.length - segmentSize; i += segmentSize - overlapSize) {
      final segment = audioData.sublist(i, i + segmentSize);
      final segmentEvents = await _mlService.analyzeAudioSegment(segment);
      
      // Adjust timestamps based on segment position
      final timeOffset = i / 16000.0; // Convert samples to seconds
      for (final event in segmentEvents) {
        final adjustedEvent = AudioEvent(
          type: event.type,
          confidence: event.confidence,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            (timeOffset * 1000).round(),
          ),
        );
        allEvents.add(adjustedEvent);
      }
    }
    
    return _filterAndMergeEvents(allEvents);
  }

  Float32List _convertBytesToFloat32(Uint8List bytes) {
    // Convert 16-bit PCM to Float32
    final float32List = Float32List(bytes.length ~/ 2);
    final byteData = ByteData.sublistView(bytes);
    
    for (int i = 0; i < float32List.length; i++) {
      final sample = byteData.getInt16(i * 2, Endian.little);
      float32List[i] = sample / 32768.0; // Normalize to [-1, 1]
    }
    
    return float32List;
  }

  List<AudioEvent> _filterAndMergeEvents(List<AudioEvent> events) {
    if (events.isEmpty) return events;
    
    // Sort events by timestamp
    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final filteredEvents = <AudioEvent>[];
    AudioEvent? lastEvent;
    
    for (final event in events) {
      if (lastEvent == null || 
          event.type != lastEvent.type ||
          event.timestamp.difference(lastEvent.timestamp).inSeconds > 2) {
        filteredEvents.add(event);
        lastEvent = event;
      } else if (event.confidence > lastEvent.confidence) {
        // Replace with higher confidence event
        filteredEvents.removeLast();
        filteredEvents.add(event);
        lastEvent = event;
      }
    }
    
    return filteredEvents;
  }

  Future<List<HighlightEvent>> _convertToHighlightEvents(
    List<AudioEvent> audioEvents,
    String videoId,
  ) async {
    final highlightEvents = <HighlightEvent>[];
    
    for (final audioEvent in audioEvents) {
      final eventType = _mapAudioEventToHighlightEvent(audioEvent.type);
      final startTime = audioEvent.timestamp.millisecondsSinceEpoch ~/ 1000;
      
      final highlightEvent = HighlightEvent(
        id: _generateEventId(),
        videoId: videoId,
        eventType: eventType,
        startTimeSeconds: startTime - 5, // 5 seconds before
        endTimeSeconds: startTime + 10,  // 10 seconds after
        confidence: audioEvent.confidence,
        description: _getAudioEventDescription(audioEvent.type),
        detectedAt: DateTime.now(),
      );
      
      highlightEvents.add(highlightEvent);
    }
    
    return highlightEvents;
  }

  EventType _mapAudioEventToHighlightEvent(AudioEventType audioType) {
    switch (audioType) {
      case AudioEventType.batHit:
        return EventType.batHit;
      case AudioEventType.crowdCheer:
        return EventType.crowdCheer;
      case AudioEventType.wicketSound:
        return EventType.wicket;
      case AudioEventType.commentary:
        return EventType.scoreChange;
      case AudioEventType.ambient:
        return EventType.crowdCheer;
    }
  }

  String _getAudioEventDescription(AudioEventType type) {
    switch (type) {
      case AudioEventType.batHit:
        return 'Bat hitting ball sound detected';
      case AudioEventType.crowdCheer:
        return 'Crowd cheering detected';
      case AudioEventType.wicketSound:
        return 'Wicket fall sound detected';
      case AudioEventType.commentary:
        return 'Commentary excitement detected';
      case AudioEventType.ambient:
        return 'Ambient cricket sounds detected';
    }
  }

  String _generateEventId() {
    return 'audio_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (999 * (DateTime.now().microsecond / 1000000))).round()}';
  }
}
