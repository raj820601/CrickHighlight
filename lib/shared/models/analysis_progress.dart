class AnalysisProgress {
  final String videoId;
  final String currentStage;
  final double progress;
  final String? message;
  final bool isCompleted;
  final String? error;

  const AnalysisProgress({
    required this.videoId,
    required this.currentStage,
    required this.progress,
    this.message,
    this.isCompleted = false,
    this.error,
  });

  AnalysisProgress copyWith({
    String? videoId,
    String? currentStage,
    double? progress,
    String? message,
    bool? isCompleted,
    String? error,
  }) {
    return AnalysisProgress(
      videoId: videoId ?? this.videoId,
      currentStage: currentStage ?? this.currentStage,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error ?? this.error,
    );
  }
}
