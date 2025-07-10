import 'dart:io';
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../../shared/models/video_model.dart';
import '../../../shared/models/highlight_event.dart';
import '../../../shared/models/analysis_progress.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/ml_model_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import 'audio_analysis_service.dart';
import 'visual_analysis_service.dart';
import 'ocr_analysis_service.dart';

class AIAnalysisService {
  final StorageService _storageService = StorageService.instance;
  final MLModelService _mlService = MLModelService.instance;
  final AudioAnalysisService _audioService = AudioAnalysisService();
  final VisualAnalysisService _visualService = VisualAnalysisService();
  final OCRAnalysisService _ocrService = OCRAnalysisService();
  final Uuid _uuid = const Uuid();

  Stream<AnalysisProgress> analyzeVideo(VideoModel video) async* {
    try {
      AppLogger.info('Starting comprehensive AI analysis for video: ${video.name}');
      
      // Initialize ML models if not already done
      yield AnalysisProgress(
        videoId: video.id,
        currentStage: 'Initializing AI Models',
        progress: 0.0,
        message: 'Loading TensorFlow Lite models...',
      );

      await _ensureModelsInitialized();

      // Stage 1: Audio Analysis (30% of progress)
      yield AnalysisProgress(
        videoId: video.id,
        currentStage: 'Audio Analysis',
        progress: 0.05,
        message: 'Extracting and analyzing audio for cricket sounds...',
      );

      final audioEvents = await _audioService.analyzeVideoAudio(video);
      
      yield AnalysisProgress(
        videoId: video.id,
        currentStage: 'Audio Analysis',
        progress: 0.3,
        message: 'Found ${audioEvents.length} audio-based events',
      );

      // Stage 2: Visual Analysis (30% of progress)
      yield AnalysisProgress(
        videoId: video.id,
        currentStage: 'Visual Analysis',
        progress: 0.3,
        message: 'Analyzing video frames for player actions and celebrations...',
      );

      final visualEvents = await _visualService.analyzeVideoFrames(video);
      
      yield AnalysisProgress(
        videoId: video.id,
        currentStage: 'Visual Analysis',
        progress: 0.6,
        message: 'Found ${visualEvents.length} visual events',
      );

      // Stage 3: OCR Analysis (20% of progress)
      yield AnalysisProgress(
        videoId: video.id,
        currentStage: 'Scoreboard Analysis',
        progress: 0.6,
        message: 'Analyzing scoreboards for score changes...',
      );

      final ocrEvents = await _ocrService.analyzeScoreboards(video);
      
      yield AnalysisProgress(
        videoId: video.id,
        currentStage: 'Scoreboard Analysis',
        progress: 0.8,
        message: 'Found ${ocrEvents.length} score changes',
      );

      // Stage 4: Event Fusion and Post-processing (20% of progress)
      yield AnalysisProgress(
        videoId: video.id,
        currentStage: 'Event Processing',
        progress: 0.8,
        message: 'Combining and filtering all detected events...',
      );

      final allEvents = [...audioEvents, ...visualEvents, ...ocrEvents];
      final fusedEvents = await _fuseAndFilterEvents(allEvents, video);
      
      yield AnalysisProgress(
        videoId: video.id,
        currentStage: 'Event Processing',
        progress: 0.9,
        message: 'Generated ${fusedEvents.length} high-confidence highlight events',
      );

      // Stage 5: Save Results
      yield AnalysisProgress(
        videoId: video.id,
        currentStage: 'Saving Results',
        progress: 0.9,
        message: 'Saving analysis results to database...',
      );

      // Clear any existing events for this video
      await _storageService.deleteEventsForVideo(video.id);

      // Save new events
      for (final event in fusedEvents) {
        await _storageService.saveEvent(event);
      }

      // Update video as analyzed
      final updatedVideo = video.copyWith(isAnalyzed: true);
      await _storageService.saveVideo(updatedVideo);

      yield AnalysisProgress(
        videoId: video.id,
        currentStage: 'Complete',
        progress: 1.0,
        message: 'AI analysis completed successfully! Found ${fusedEvents.length} highlight moments.',
        isCompleted: true,
      );

      AppLogger.info('Comprehensive AI analysis completed for video: ${video.name}');

    } catch (e) {
      AppLogger.error('AI analysis failed', e);
      yield AnalysisProgress(
        videoId: video.id,
        currentStage: 'Error',
        progress: 0.0,
        error: 'Analysis failed: ${e.toString()}',
      );
    }
  }

  Future<void> _ensureModelsInitialized() async {
    try {
      // Initialize ML models if not already done
      await _mlService.initialize();
    } catch (e) {
      AppLogger.warning('ML models initialization failed, using fallback methods');
      // Continue with fallback analysis methods
    }
  }

  Future<List<HighlightEvent>> _fuseAndFilterEvents(
    List<HighlightEvent> allEvents,
    VideoModel video,
  ) async {
    if (allEvents.isEmpty) return [];

    // Sort events by start time
    allEvents.sort((a, b) => a.startTimeSeconds.compareTo(b.startTimeSeconds));

    final fusedEvents = <HighlightEvent>[];
    
    // Group nearby events and apply fusion logic
    for (final event in allEvents) {
      final nearbyEvents = fusedEvents.where((existing) =>
          (event.startTimeSeconds - existing.startTimeSeconds).abs() < 30 &&
          _areEventsRelated(event.eventType, existing.eventType)
      ).toList();

      if (nearbyEvents.isEmpty) {
        // No nearby related events, add as new event
        if (event.confidence >= _getMinConfidenceThreshold(event.eventType)) {
          fusedEvents.add(event);
        }
      } else {
        // Fuse with nearby events
        final bestNearbyEvent = nearbyEvents.reduce((a, b) => 
            a.confidence > b.confidence ? a : b);
        
        if (event.confidence > bestNearbyEvent.confidence) {
          // Replace with higher confidence event
          fusedEvents.remove(bestNearbyEvent);
          fusedEvents.add(_createFusedEvent(event, bestNearbyEvent));
        } else {
          // Enhance existing event with additional information
          final enhancedEvent = _enhanceEvent(bestNearbyEvent, event);
          final index = fusedEvents.indexOf(bestNearbyEvent);
          fusedEvents[index] = enhancedEvent;
        }
      }
    }

    // Apply final filtering and ranking
    final filteredEvents = _applyFinalFiltering(fusedEvents, video);
    
    return filteredEvents;
  }

  bool _areEventsRelated(EventType type1, EventType type2) {
    // Define which event types are related and can be fused
    const relatedGroups = [
      {EventType.batHit, EventType.boundary, EventType.crowdCheer},
      {EventType.wicket, EventType.celebration},
      {EventType.scoreChange, EventType.boundary, EventType.wicket},
    ];

    for (final group in relatedGroups) {
      if (group.contains(type1) && group.contains(type2)) {
        return true;
      }
    }

    return type1 == type2;
  }

  double _getMinConfidenceThreshold(EventType eventType) {
    // Different confidence thresholds for different event types
    switch (eventType) {
      case EventType.wicket:
        return 0.8; // High threshold for wickets
      case EventType.boundary:
        return 0.7; // High threshold for boundaries
      case EventType.batHit:
        return 0.6; // Medium threshold for bat hits
      case EventType.celebration:
        return 0.65; // Medium threshold for celebrations
      case EventType.crowdCheer:
        return 0.5; // Lower threshold for crowd reactions
      case EventType.scoreChange:
        return 0.75; // High threshold for score changes
    }
  }

  HighlightEvent _createFusedEvent(HighlightEvent primary, HighlightEvent secondary) {
    return HighlightEvent(
      id: primary.id,
      videoId: primary.videoId,
      eventType: _selectBestEventType(primary.eventType, secondary.eventType),
      startTimeSeconds: min(primary.startTimeSeconds, secondary.startTimeSeconds),
      endTimeSeconds: max(primary.endTimeSeconds, secondary.endTimeSeconds),
      confidence: (primary.confidence + secondary.confidence) / 2,
      description: '${primary.description} + ${secondary.description}',
      detectedAt: primary.detectedAt,
    );
  }

  HighlightEvent _enhanceEvent(HighlightEvent existing, HighlightEvent additional) {
    return HighlightEvent(
      id: existing.id,
      videoId: existing.videoId,
      eventType: existing.eventType,
      startTimeSeconds: min(existing.startTimeSeconds, additional.startTimeSeconds),
      endTimeSeconds: max(existing.endTimeSeconds, additional.endTimeSeconds),
      confidence: max(existing.confidence, additional.confidence),
      description: '${existing.description} (enhanced with ${additional.eventType.name})',
      detectedAt: existing.detectedAt,
    );
  }

  EventType _selectBestEventType(EventType type1, EventType type2) {
    // Priority order for event types when fusing
    const priority = [
      EventType.wicket,
      EventType.boundary,
      EventType.celebration,
      EventType.batHit,
      EventType.scoreChange,
      EventType.crowdCheer,
    ];

    final index1 = priority.indexOf(type1);
    final index2 = priority.indexOf(type2);

    if (index1 == -1 && index2 == -1) return type1;
    if (index1 == -1) return type2;
    if (index2 == -1) return type1;

    return index1 < index2 ? type1 : type2;
  }

  List<HighlightEvent> _applyFinalFiltering(List<HighlightEvent> events, VideoModel video) {
    // Remove events that are too close to the start or end of the video
    final filteredEvents = events.where((event) =>
        event.startTimeSeconds >= 10 &&
        event.endTimeSeconds <= video.durationSeconds - 10
    ).toList();

    // Sort by confidence and limit to top events
    filteredEvents.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    // Limit to maximum number of highlights based on video length
    final maxHighlights = _calculateMaxHighlights(video.durationSeconds);
    
    return filteredEvents.take(maxHighlights).toList();
  }

  int _calculateMaxHighlights(int videoDurationSeconds) {
    // Calculate reasonable number of highlights based on video length
    final minutes = videoDurationSeconds / 60;
    
    if (minutes < 30) return 5;
    if (minutes < 60) return 8;
    if (minutes < 120) return 12;
    return 15; // Maximum highlights for very long videos
  }
}
