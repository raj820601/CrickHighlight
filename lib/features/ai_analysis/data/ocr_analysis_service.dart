import 'dart:io';
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:image/image.dart' as img;
import '../../../core/services/ml_model_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/video_model.dart';
import '../../../shared/models/highlight_event.dart';

class OCRAnalysisService {
  final MLModelService _mlService = MLModelService.instance;
  final StorageService _storageService = StorageService.instance;

  Future<List<HighlightEvent>> analyzeScoreboards(VideoModel video) async {
    try {
      AppLogger.info('Starting scoreboard OCR analysis for: ${video.name}');
      
      // Extract frames specifically for scoreboard detection
      final scoreboardFrames = await _extractScoreboardFrames(video.path);
      
      // Analyze scoreboards for score changes
      final scoreChanges = await _detectScoreChanges(scoreboardFrames);
      
      // Convert to highlight events
      final highlightEvents = await _convertScoreChangesToEvents(scoreChanges, video.id);
      
      // Clean up temporary files
      await _cleanupScoreboardFrames(scoreboardFrames);
      
      AppLogger.info('OCR analysis completed. Found ${highlightEvents.length} score changes');
      return highlightEvents;
      
    } catch (e) {
      AppLogger.error('OCR analysis failed', e);
      rethrow;
    }
  }

  Future<List<ScoreboardFrame>> _extractScoreboardFrames(String videoPath) async {
    final framesDir = '${_storageService.tempPath}/scoreboard_${DateTime.now().millisecondsSinceEpoch}';
    final framesDirFile = Directory(framesDir);
    await framesDirFile.create(recursive: true);
    
    // Extract frames every 10 seconds for scoreboard analysis
    final command = '-i "$videoPath" -vf "fps=0.1" "$framesDir/scoreboard_%04d.jpg"';
    
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    
    if (!ReturnCode.isSuccess(returnCode)) {
      throw Exception('Failed to extract scoreboard frames');
    }
    
    // Process extracted frames
    final frameFiles = await framesDirFile.list().toList();
    final scoreboardFrames = <ScoreboardFrame>[];
    
    for (int i = 0; i < frameFiles.length; i++) {
      final file = frameFiles[i];
      if (file.path.endsWith('.jpg')) {
        final timestamp = i * 10.0; // 10 seconds per frame
        scoreboardFrames.add(ScoreboardFrame(
          path: file.path,
          timestamp: timestamp,
        ));
      }
    }
    
    scoreboardFrames.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return scoreboardFrames;
  }

  Future<List<ScoreChange>> _detectScoreChanges(List<ScoreboardFrame> frames) async {
    final scoreChanges = <ScoreChange>[];
    ScoreboardData? previousScore;
    
    for (final frame in frames) {
      try {
        final scoreboardData = await _extractScoreFromFrame(frame);
        
        if (previousScore != null && scoreboardData != null) {
          final change = _compareScores(previousScore, scoreboardData);
          if (change != null) {
            change.timestamp = frame.timestamp;
            scoreChanges.add(change);
          }
        }
        
        if (scoreboardData != null) {
          previousScore = scoreboardData;
        }
      } catch (e) {
        AppLogger.warning('Failed to process scoreboard frame: ${frame.path}');
      }
    }
    
    return scoreChanges;
  }

  Future<ScoreboardData?> _extractScoreFromFrame(ScoreboardFrame frame) async {
    try {
      final frameFile = File(frame.path);
      final frameBytes = await frameFile.readAsBytes();
      
      // Preprocess image for better OCR
      final image = img.decodeImage(frameBytes);
      if (image == null) return null;
      
      // Crop to likely scoreboard area (top portion of frame)
      final croppedImage = img.copyCrop(
        image,
        x: 0,
        y: 0,
        width: image.width,
        height: (image.height * 0.3).round(),
      );
      
      // Enhance contrast for better OCR
      final enhancedImage = img.contrast(croppedImage, contrast: 150);
      final processedBytes = Uint8List.fromList(img.encodeJpg(enhancedImage));
      
      // Use ML model for OCR
      final ocrResults = await _mlService.analyzeScoreboard(processedBytes);
      
      // Parse OCR results to extract score information
      return _parseScoreFromOCR(ocrResults);
      
    } catch (e) {
      AppLogger.error('Failed to extract score from frame', e);
      return null;
    }
  }

  ScoreboardData? _parseScoreFromOCR(List<OCRResult> ocrResults) {
    try {
      // Look for cricket score patterns
      final scorePatterns = [
        RegExp(r'(\d+)/(\d+)'), // Score/Wickets format
        RegExp(r'(\d+)\s*-\s*(\d+)'), // Score-Wickets format
        RegExp(r'(\d+)\s+for\s+(\d+)'), // Score for Wickets format
      ];
      
      for (final result in ocrResults) {
        for (final pattern in scorePatterns) {
          final match = pattern.firstMatch(result.text);
          if (match != null) {
            final runs = int.tryParse(match.group(1) ?? '');
            final wickets = int.tryParse(match.group(2) ?? '');
            
            if (runs != null && wickets != null) {
              return ScoreboardData(
                runs: runs,
                wickets: wickets,
                confidence: result.confidence,
              );
            }
          }
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  ScoreChange? _compareScores(ScoreboardData previous, ScoreboardData current) {
    // Detect significant score changes
    final runsDiff = current.runs - previous.runs;
    final wicketsDiff = current.wickets - previous.wickets;
    
    if (runsDiff >= 4) {
      // Boundary detected
      return ScoreChange(
        type: ScoreChangeType.boundary,
        previousScore: previous,
        newScore: current,
        runsAdded: runsDiff,
        timestamp: 0, // Will be set by caller
      );
    } else if (wicketsDiff > 0) {
      // Wicket detected
      return ScoreChange(
        type: ScoreChangeType.wicket,
        previousScore: previous,
        newScore: current,
        runsAdded: runsDiff,
        timestamp: 0, // Will be set by caller
      );
    } else if (runsDiff > 0) {
      // Regular runs
      return ScoreChange(
        type: ScoreChangeType.runs,
        previousScore: previous,
        newScore: current,
        runsAdded: runsDiff,
        timestamp: 0, // Will be set by caller
      );
    }
    
    return null;
  }

  Future<List<HighlightEvent>> _convertScoreChangesToEvents(
    List<ScoreChange> scoreChanges,
    String videoId,
  ) async {
    final highlightEvents = <HighlightEvent>[];
    
    for (final change in scoreChanges) {
      final eventType = _mapScoreChangeToEventType(change.type);
      final startTime = change.timestamp.round();
      
      final highlightEvent = HighlightEvent(
        id: _generateEventId(),
        videoId: videoId,
        eventType: eventType,
        startTimeSeconds: startTime - 5,
        endTimeSeconds: startTime + 15,
        confidence: (change.previousScore.confidence + change.newScore.confidence) / 2,
        description: _getScoreChangeDescription(change),
        detectedAt: DateTime.now(),
      );
      
      highlightEvents.add(highlightEvent);
    }
    
    return highlightEvents;
  }

  EventType _mapScoreChangeToEventType(ScoreChangeType changeType) {
    switch (changeType) {
      case ScoreChangeType.boundary:
        return EventType.boundary;
      case ScoreChangeType.wicket:
        return EventType.wicket;
      case ScoreChangeType.runs:
        return EventType.scoreChange;
    }
  }

  String _getScoreChangeDescription(ScoreChange change) {
    switch (change.type) {
      case ScoreChangeType.boundary:
        return 'Boundary scored: +${change.runsAdded} runs';
      case ScoreChangeType.wicket:
        return 'Wicket fallen: ${change.previousScore.runs}/${change.previousScore.wickets} to ${change.newScore.runs}/${change.newScore.wickets}';
      case ScoreChangeType.runs:
        return 'Runs scored: +${change.runsAdded} runs';
    }
  }

  Future<void> _cleanupScoreboardFrames(List<ScoreboardFrame> frames) async {
    for (final frame in frames) {
      final file = File(frame.path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    
    // Clean up directory
    if (frames.isNotEmpty) {
      final framesDir = Directory(File(frames.first.path).parent.path);
      if (await framesDir.exists()) {
        await framesDir.delete(recursive: true);
      }
    }
  }

  String _generateEventId() {
    return 'ocr_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (999 * (DateTime.now().microsecond / 1000000))).round()}';
  }
}

// Data classes for OCR analysis
class ScoreboardFrame {
  final String path;
  final double timestamp;

  ScoreboardFrame({
    required this.path,
    required this.timestamp,
  });
}

class ScoreboardData {
  final int runs;
  final int wickets;
  final double confidence;

  ScoreboardData({
    required this.runs,
    required this.wickets,
    required this.confidence,
  });
}

class ScoreChange {
  final ScoreChangeType type;
  final ScoreboardData previousScore;
  final ScoreboardData newScore;
  final int runsAdded;
  double timestamp;

  ScoreChange({
    required this.type,
    required this.previousScore,
    required this.newScore,
    required this.runsAdded,
    required this.timestamp,
  });
}

enum ScoreChangeType {
  boundary,
  wicket,
  runs,
}
