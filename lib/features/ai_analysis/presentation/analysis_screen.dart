import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/video_model.dart';
import '../../../shared/models/analysis_progress.dart';
import '../../../shared/widgets/custom_button.dart';
import '../data/ai_analysis_service.dart';

final analysisServiceProvider = Provider<AIAnalysisService>((ref) {
  return AIAnalysisService();
});

final analysisProvider = StreamProvider.family<AnalysisProgress, VideoModel>((ref, video) {
  final service = ref.watch(analysisServiceProvider);
  return service.analyzeVideo(video);
});

class AnalysisScreen extends ConsumerWidget {
  final VideoModel video;

  const AnalysisScreen({super.key, required this.video});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(analysisProvider(video));

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analysis'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.video_file, size: 40, color: Color(0xFF1B5E20)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Duration: ${_formatDuration(video.durationSeconds)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Analysis progress
            analysisAsync.when(
              data: (progress) => _buildProgressWidget(context, progress),
              loading: () => _buildLoadingWidget(),
              error: (error, stack) => _buildErrorWidget(context, error.toString()),
            ),

            const Spacer(),

            // Action buttons
            analysisAsync.when(
              data: (progress) {
                if (progress.isCompleted) {
                  return CustomButton(
                    text: 'View Highlights',
                    icon: Icons.play_circle_filled,
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to highlights screen would be implemented here
                    },
                  );
                } else if (progress.error != null) {
                  return CustomButton(
                    text: 'Retry Analysis',
                    icon: Icons.refresh,
                    onPressed: () {
                      ref.invalidate(analysisProvider(video));
                    },
                  );
                } else {
                  return CustomButton(
                    text: 'Cancel Analysis',
                    isOutlined: true,
                    onPressed: () => Navigator.pop(context),
                  );
                }
              },
              loading: () => CustomButton(
                text: 'Cancel',
                isOutlined: true,
                onPressed: () => Navigator.pop(context),
              ),
              error: (error, stack) => CustomButton(
                text: 'Retry',
                onPressed: () => ref.invalidate(analysisProvider(video)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressWidget(BuildContext context, AnalysisProgress progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          progress.isCompleted ? 'Analysis Complete!' : 'Analyzing Video...',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Progress bar
        LinearProgressIndicator(
          value: progress.progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            progress.error != null 
                ? Colors.red 
                : progress.isCompleted 
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(progress.progress * 100).toInt()}% Complete',
          style: TextStyle(color: Colors.grey[600]),
        ),

        const SizedBox(height: 24),

        // Current stage
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      progress.isCompleted 
                          ? Icons.check_circle 
                          : progress.error != null
                              ? Icons.error
                              : Icons.analytics,
                      color: progress.isCompleted 
                          ? const Color(0xFF4CAF50)
                          : progress.error != null
                              ? Colors.red
                              : const Color(0xFF1B5E20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      progress.currentStage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (progress.message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    progress.message!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
                if (progress.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${progress.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        ),

        if (progress.isCompleted) ...[
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analysis Results',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('✓ Audio events detected'),
                  Text('✓ Video highlights identified'),
                  Text('✓ Timeline generated'),
                  Text('✓ Ready for highlight creation'),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return const Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Initializing AI analysis...'),
      ],
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    return Column(
      children: [
        const Icon(Icons.error, size: 60, color: Colors.red),
        const SizedBox(height: 16),
        const Text(
          'Analysis Failed',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          error,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${remainingSeconds}s';
    } else {
      return '${minutes}m ${remainingSeconds}s';
    }
  }
}
