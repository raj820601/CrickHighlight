abstract class Failure {
  final String message;
  const Failure(this.message);
}

class VideoProcessingFailure extends Failure {
  const VideoProcessingFailure(super.message);
}

class AIAnalysisFailure extends Failure {
  const AIAnalysisFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}
