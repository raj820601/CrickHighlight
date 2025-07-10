import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/models/video_model.dart';
import '../../../shared/models/highlight_event.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/logger.dart';

class VideoProcessingService {
  final StorageService _storageService = StorageService.instance;
  final Uuid _uuid = const Uuid();

  Future<String> generateHighlightReel(
    VideoModel originalVideo,
    List<HighlightEvent> events,
  ) async {
    try {
      AppLogger.info('Starting highlight reel generation for ${originalVideo.name}');
      
      if (events.isEmpty) {
        throw Exception('No highlight events found');
      }

      // Create individual highlight clips
      final clipPaths = <String>[];
      for (int i = 0; i < events.length; i++) {
        final event = events[i];
        final clipPath = await _createHighlightClip(originalVideo, event, i);
        if (clipPath != null) {
          clipPaths.add(clipPath);
        }
      }

      if (clipPaths.isEmpty) {
        throw Exception('No highlight clips were created');
      }

      // Merge all clips into final highlight reel
      final finalPath = await _mergeClips(clipPaths, originalVideo.name);
      
      // Clean up temporary clips
      for (final clipPath in clipPaths) {
        final file = File(clipPath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      AppLogger.info('Highlight reel generated successfully: $finalPath');
      return finalPath;

    } catch (e) {
      AppLogger.error('Failed to generate highlight reel', e);
      rethrow;
    }
  }

  Future<String?> _createHighlightClip(
    VideoModel video,
    HighlightEvent event,
    int index,
  ) async {
    try {
      final outputPath = '${_storageService.tempPath}/clip_${index}_${_uuid.v4()}.mp4';
      
      // FFmpeg command to extract clip with fade effects
      final command = '-i "${video.path}" '
          '-ss ${event.startTimeSeconds} '
          '-t ${event.durationSeconds} '
          '-vf "fade=in:0:30,fade=out:${event.durationSeconds - 1}:30" '
          '-af "afade=in:st=0:d=1,afade=out:st=${event.durationSeconds - 1}:d=1" '
          '-c:v libx264 -preset fast -crf 23 '
          '-c:a aac -b:a 128k '
          '"$outputPath"';

      AppLogger.debug('FFmpeg command: $command');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        AppLogger.info('Clip created successfully: clip_$index');
        return outputPath;
      } else {
        final logs = await session.getLogs();
        AppLogger.error('FFmpeg failed for clip $index: ${logs.map((l) => l.getMessage()).join('\n')}');
        return null;
      }
    } catch (e) {
      AppLogger.error('Failed to create clip $index', e);
      return null;
    }
  }

  Future<String> _mergeClips(List<String> clipPaths, String originalVideoName) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${_storageService.highlightsPath}/highlights_${originalVideoName}_$timestamp.mp4';
      
      // Create concat file for FFmpeg
      final concatFilePath = '${_storageService.tempPath}/concat_$timestamp.txt';
      final concatFile = File(concatFilePath);
      
      final concatContent = clipPaths
          .map((path) => "file '$path'")
          .join('\n');
      
      await concatFile.writeAsString(concatContent);

      // FFmpeg command to concatenate clips with transitions
      final command = '-f concat -safe 0 -i "$concatFilePath" '
          '-c:v libx264 -preset medium -crf 20 '
          '-c:a aac -b:a 192k '
          '-movflags +faststart '
          '"$outputPath"';

      AppLogger.debug('FFmpeg merge command: $command');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      // Clean up concat file
      if (await concatFile.exists()) {
        await concatFile.delete();
      }

      if (ReturnCode.isSuccess(returnCode)) {
        AppLogger.info('Highlight reel merged successfully');
        return outputPath;
      } else {
        final logs = await session.getLogs();
        throw Exception('FFmpeg merge failed: ${logs.map((l) => l.getMessage()).join('\n')}');
      }
    } catch (e) {
      AppLogger.error('Failed to merge clips', e);
      rethrow;
    }
  }

  Future<String> addIntroOutro(String highlightPath, String videoName) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${_storageService.highlightsPath}/final_${videoName}_$timestamp.mp4';
      
      // Add title overlay and transitions
      final command = '-i "$highlightPath" '
          '-vf "drawtext=text=\'Cricket Highlights - $videoName\':'
          'fontsize=24:fontcolor=white:x=(w-text_w)/2:y=50:'
          'enable=\'between(t,0,3)\'" '
          '-c:v libx264 -preset medium -crf 20 '
          '-c:a copy '
          '"$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // Delete intermediate file
        final file = File(highlightPath);
        if (await file.exists()) {
          await file.delete();
        }
        return outputPath;
      } else {
        throw Exception('Failed to add intro/outro');
      }
    } catch (e) {
      AppLogger.error('Failed to add intro/outro', e);
      return highlightPath; // Return original if enhancement fails
    }
  }
}
