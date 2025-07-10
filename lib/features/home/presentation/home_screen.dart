import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/video_card.dart';
import '../../../shared/models/video_model.dart';
import '../../../core/services/storage_service.dart';
import '../../video_upload/presentation/video_upload_provider.dart';
import '../../ai_analysis/presentation/analysis_screen.dart';
import '../../highlights/presentation/highlights_screen.dart';
import '../../settings/presentation/settings_screen.dart';

final videosProvider = FutureProvider<List<VideoModel>>((ref) async {
  return await StorageService.instance.getAllVideos();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(videosProvider);
    final uploadState = ref.watch(videoUploadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cricket Highlights'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1B5E20),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI-Powered Cricket\nHighlight Generator',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload your cricket videos and let AI create amazing highlights automatically',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Upload Video',
                  icon: Icons.upload_file,
                  backgroundColor: const Color(0xFF4CAF50),
                  isLoading: uploadState.isUploading,
                  onPressed: () => _uploadVideo(ref),
                ),
              ],
            ),
          ),

          // Videos list
          Expanded(
            child: videosAsync.when(
              data: (videos) {
                if (videos.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No videos uploaded yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Upload your first cricket video to get started',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(videosProvider);
                  },
                  child: ListView.builder(
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final video = videos[index];
                      return VideoCard(
                        video: video,
                        onTap: () => _openVideoDetails(context, video),
                        onAnalyze: () => _analyzeVideo(context, video),
                        onDelete: () => _deleteVideo(context, ref, video),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(videosProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Show upload success message
      bottomSheet: uploadState.uploadedVideo != null
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF4CAF50),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Video uploaded: ${uploadState.uploadedVideo!.name}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(videoUploadProvider.notifier).clearUploadedVideo();
                      ref.invalidate(videosProvider);
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  void _uploadVideo(WidgetRef ref) {
    ref.read(videoUploadProvider.notifier).uploadVideo();
  }

  void _openVideoDetails(BuildContext context, VideoModel video) {
    if (video.isAnalyzed) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HighlightsScreen(video: video),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please analyze the video first to view highlights'),
        ),
      );
    }
  }

  void _analyzeVideo(BuildContext context, VideoModel video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisScreen(video: video),
      ),
    );
  }

  void _deleteVideo(BuildContext context, WidgetRef ref, VideoModel video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: Text('Are you sure you want to delete "${video.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await StorageService.instance.deleteVideo(video.id);
              ref.invalidate(videosProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Video deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
