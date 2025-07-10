import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/models/video_model.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../core/errors/failures.dart';

class VideoUploadRepository {
  final StorageService _storageService = StorageService.instance;
  final Uuid _uuid = const Uuid();

  Future<bool> requestPermissions() async {
    try {
      final status = await Permission.storage.request();
      return status.isGranted;
    } catch (e) {
      AppLogger.error('Permission request failed', e);
      return false;
    }
  }

  Future<VideoModel?> pickAndSaveVideo() async {
    try {
      // Check permissions
      if (!await requestPermissions()) {
        throw const PermissionFailure('Storage permission denied');
      }

      // Pick video file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = File(result.files.first.path!);
      final fileName = result.files.first.name;
      
      // Validate video format
      final extension = fileName.split('.').last.toLowerCase();
      if (!AppConstants.supportedVideoFormats.contains(extension)) {
        throw const VideoProcessingFailure('Unsupported video format');
      }

      // Get video duration (simplified - in real app you'd use FFmpeg)
      final fileStat = await file.stat();
      final durationSeconds = await _getVideoDuration(file.path);
      
      // Validate video length
      if (durationSeconds < AppConstants.minVideoLengthSeconds) {
        throw const VideoProcessingFailure('Video too short');
      }
      
      if (durationSeconds > AppConstants.maxVideoLengthMinutes * 60) {
        throw const VideoProcessingFailure('Video too long');
      }

      // Generate unique ID and copy to app directory
      final videoId = _uuid.v4();
      final newFileName = '${videoId}_$fileName';
      final destinationPath = '${_storageService.videosPath}/$newFileName';
      
      await file.copy(destinationPath);

      // Generate thumbnail
      final thumbnailPath = await _generateThumbnail(destinationPath, videoId);

      // Create video model
      final video = VideoModel(
        id: videoId,
        name: fileName,
        path: destinationPath,
        durationSeconds: durationSeconds,
        fileSizeBytes: fileStat.size,
        createdAt: DateTime.now(),
        thumbnailPath: thumbnailPath,
      );

      // Save to storage
      await _storageService.saveVideo(video);

      AppLogger.info('Video uploaded successfully: $fileName');
      return video;

    } catch (e) {
      AppLogger.error('Video upload failed', e);
      if (e is Failure) rethrow;
      throw VideoProcessingFailure('Failed to upload video: $e');
    }
  }

  Future<int> _getVideoDuration(String path) async {
    // Simplified duration calculation
    // In real implementation, use FFmpeg to get accurate duration
    try {
      final file = File(path);
      final size = await file.length();
      // Rough estimation: 1MB per minute for standard quality
      return (size / (1024 * 1024)).round() * 60;
    } catch (e) {
      AppLogger.warning('Could not determine video duration, using default');
      return 1800; // 30 minutes default
    }
  }

  Future<String?> _generateThumbnail(String videoPath, String videoId) async {
    try {
      final thumbnailPath = '${_storageService.videosPath}/thumb_$videoId.jpg';
      
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 75,
      );

      return thumbnail;
    } catch (e) {
      AppLogger.warning('Failed to generate thumbnail', e);
      return null;
    }
  }
}
