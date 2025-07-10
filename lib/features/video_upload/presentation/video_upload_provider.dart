import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/video_model.dart';
import '../data/video_upload_repository.dart';
import '../../../core/utils/logger.dart';

final videoUploadRepositoryProvider = Provider<VideoUploadRepository>((ref) {
  return VideoUploadRepository();
});

final videoUploadProvider = StateNotifierProvider<VideoUploadNotifier, VideoUploadState>((ref) {
  final repository = ref.watch(videoUploadRepositoryProvider);
  return VideoUploadNotifier(repository);
});

class VideoUploadState {
  final bool isUploading;
  final VideoModel? uploadedVideo;
  final String? error;

  const VideoUploadState({
    this.isUploading = false,
    this.uploadedVideo,
    this.error,
  });

  VideoUploadState copyWith({
    bool? isUploading,
    VideoModel? uploadedVideo,
    String? error,
  }) {
    return VideoUploadState(
      isUploading: isUploading ?? this.isUploading,
      uploadedVideo: uploadedVideo ?? this.uploadedVideo,
      error: error,
    );
  }
}

class VideoUploadNotifier extends StateNotifier<VideoUploadState> {
  final VideoUploadRepository _repository;

  VideoUploadNotifier(this._repository) : super(const VideoUploadState());

  Future<void> uploadVideo() async {
    try {
      state = state.copyWith(isUploading: true, error: null);
      
      final video = await _repository.pickAndSaveVideo();
      
      if (video != null) {
        state = state.copyWith(
          isUploading: false,
          uploadedVideo: video,
        );
        AppLogger.info('Video upload completed: ${video.name}');
      } else {
        state = state.copyWith(isUploading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );
      AppLogger.error('Video upload failed', e);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearUploadedVideo() {
    state = state.copyWith(uploadedVideo: null);
  }
}
