import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../shared/models/video_model.dart';
import '../../shared/models/highlight_event.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  StorageService._();

  late Box<VideoModel> _videosBox;
  late Box<HighlightEvent> _eventsBox;
  late Directory _appDirectory;

  Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(VideoModelAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(EventTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(HighlightEventAdapter());
      }

      // Open boxes
      _videosBox = await Hive.openBox<VideoModel>('videos');
      _eventsBox = await Hive.openBox<HighlightEvent>('events');

      // Create app directories
      _appDirectory = await getApplicationDocumentsDirectory();
      await _createDirectories();

      AppLogger.info('Storage service initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize storage service', e);
      rethrow;
    }
  }

  Future<void> _createDirectories() async {
    final directories = [
      AppConstants.videosFolder,
      AppConstants.highlightsFolder,
      AppConstants.tempFolder,
      AppConstants.modelsFolder,
    ];

    for (final dir in directories) {
      final directory = Directory('${_appDirectory.path}/$dir');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }
  }

  // Video operations
  Future<void> saveVideo(VideoModel video) async {
    await _videosBox.put(video.id, video);
    AppLogger.info('Video saved: ${video.name}');
  }

  Future<VideoModel?> getVideo(String id) async {
    return _videosBox.get(id);
  }

  Future<List<VideoModel>> getAllVideos() async {
    return _videosBox.values.toList();
  }

  Future<void> deleteVideo(String id) async {
    final video = await getVideo(id);
    if (video != null) {
      // Delete video file
      final file = File(video.path);
      if (await file.exists()) {
        await file.delete();
      }
      
      // Delete thumbnail if exists
      if (video.thumbnailPath != null) {
        final thumbnail = File(video.thumbnailPath!);
        if (await thumbnail.exists()) {
          await thumbnail.delete();
        }
      }
      
      // Delete from database
      await _videosBox.delete(id);
      
      // Delete associated events
      final events = await getEventsForVideo(id);
      for (final event in events) {
        await _eventsBox.delete(event.id);
      }
      
      AppLogger.info('Video deleted: ${video.name}');
    }
  }

  // Event operations
  Future<void> saveEvent(HighlightEvent event) async {
    await _eventsBox.put(event.id, event);
  }

  Future<List<HighlightEvent>> getEventsForVideo(String videoId) async {
    return _eventsBox.values
        .where((event) => event.videoId == videoId)
        .toList()
      ..sort((a, b) => a.startTimeSeconds.compareTo(b.startTimeSeconds));
  }

  Future<void> deleteEventsForVideo(String videoId) async {
    final events = await getEventsForVideo(videoId);
    for (final event in events) {
      await _eventsBox.delete(event.id);
    }
  }

  // Directory paths
  String get videosPath => '${_appDirectory.path}/${AppConstants.videosFolder}';
  String get highlightsPath => '${_appDirectory.path}/${AppConstants.highlightsFolder}';
  String get tempPath => '${_appDirectory.path}/${AppConstants.tempFolder}';
  String get modelsPath => '${_appDirectory.path}/${AppConstants.modelsFolder}';

  Future<void> dispose() async {
    await _videosBox.close();
    await _eventsBox.close();
  }
}
