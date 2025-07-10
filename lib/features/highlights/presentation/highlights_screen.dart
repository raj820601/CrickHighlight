import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../shared/models/video_model.dart';
import '../../../shared/models/highlight_event.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/services/storage_service.dart';
import '../../video_processing/data/video_processing_service.dart';

final highlightEventsProvider = FutureProvider.family<List<HighlightEvent>, String>((ref, videoId) async {
  return await StorageService.instance.getEventsForVideo(videoId);
});

final videoProcessingServiceProvider = Provider<VideoProcessingService>((ref) {
  return VideoProcessingService();
});

class HighlightsScreen extends ConsumerStatefulWidget {
  final VideoModel video;

  const HighlightsScreen({super.key, required this.video});

  @override
  ConsumerState<HighlightsScreen> createState() => _HighlightsScreenState();
}

class _HighlightsScreenState extends ConsumerState<HighlightsScreen> {
  VideoPlayerController? _controller;
  bool _isGeneratingHighlights = false;
  String? _generatedHighlightPath;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    _controller = VideoPlayerController.file(
      File(widget.video.path),
    )..initialize().then((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(highlightEventsProvider(widget.video.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Highlights'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Video player
          if (_controller != null && _controller!.value.isInitialized)
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.black,
              child: VideoPlayer(_controller!),
            )
          else
            Container(
              height: 200,
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Video controls
          if (_controller != null && _controller!.value.isInitialized)
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _controller!.value.isPlaying
                            ? _controller!.pause()
                            : _controller!.play();
                      });
                    },
                    icon: Icon(
                      _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                  Expanded(
                    child: VideoProgressIndicator(
                      _controller!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Color(0xFF1B5E20),
                        bufferedColor: Colors.grey,
                        backgroundColor: Colors.grey,
                      ),
                    ),
                  ),
                  Text(
                    '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

          // Highlights list
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.highlight_off, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No highlights found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          'Try re-analyzing the video',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text(
                            'Detected Highlights',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${events.length} events',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),

                    // Events list
                    Expanded(
                      child: ListView.builder(
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return _buildEventCard(event);
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading highlights: $error'),
                  ],
                ),
              ),
            ),
          ),

          // Generate highlights button
          Padding(
            padding: const EdgeInsets.all(16),
            child: eventsAsync.when(
              data: (events) => events.isNotEmpty
                  ? CustomButton(
                      text: _generatedHighlightPath != null 
                          ? 'Play Generated Highlights'
                          : 'Generate Highlight Reel',
                      icon: _generatedHighlightPath != null 
                          ? Icons.play_circle_filled
                          : Icons.movie_creation,
                      isLoading: _isGeneratingHighlights,
                      onPressed: () => _generatedHighlightPath != null
                          ? _playGeneratedHighlights()
                          : _generateHighlights(events),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(HighlightEvent event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getEventColor(event.eventType),
          child: Icon(
            _getEventIcon(event.eventType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(_getEventTitle(event.eventType)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatTime(event.startTimeSeconds)} - ${_formatTime(event.endTimeSeconds)}',
              style: const TextStyle(fontSize: 12),
            ),
            if (event.description != null)
              Text(
                event.description!,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${(event.confidence * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'confidence',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        onTap: () => _seekToEvent(event),
      ),
    );
  }

  void _seekToEvent(HighlightEvent event) {
    if (_controller != null && _controller!.value.isInitialized) {
      _controller!.seekTo(Duration(seconds: event.startTimeSeconds));
      _controller!.play();
    }
  }

  Future<void> _generateHighlights(List<HighlightEvent> events) async {
    setState(() {
      _isGeneratingHighlights = true;
    });

    try {
      final processingService = ref.read(videoProcessingServiceProvider);
      final highlightPath = await processingService.generateHighlightReel(
        widget.video,
        events,
      );

      setState(() {
        _generatedHighlightPath = highlightPath;
        _isGeneratingHighlights = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Highlight reel generated successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGeneratingHighlights = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate highlights: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _playGeneratedHighlights() {
    if (_generatedHighlightPath != null) {
      // Switch to generated highlights video
      _controller?.dispose();
      _controller = VideoPlayerController.file(
        File(_generatedHighlightPath!),
      )..initialize().then((_) {
        setState(() {});
        _controller!.play();
      });
    }
  }

  Color _getEventColor(EventType eventType) {
    switch (eventType) {
      case EventType.batHit:
        return Colors.orange;
      case EventType.wicket:
        return Colors.red;
      case EventType.boundary:
        return Colors.green;
      case EventType.celebration:
        return Colors.purple;
      case EventType.crowdCheer:
        return Colors.blue;
      case EventType.scoreChange:
        return Colors.teal;
    }
  }

  IconData _getEventIcon(EventType eventType) {
    switch (eventType) {
      case EventType.batHit:
        return Icons.sports_cricket;
      case EventType.wicket:
        return Icons.gps_fixed;
      case EventType.boundary:
        return Icons.flag;
      case EventType.celebration:
        return Icons.celebration;
      case EventType.crowdCheer:
        return Icons.people;
      case EventType.scoreChange:
        return Icons.scoreboard;
    }
  }

  String _getEventTitle(EventType eventType) {
    switch (eventType) {
      case EventType.batHit:
        return 'Bat Hit';
      case EventType.wicket:
        return 'Wicket';
      case EventType.boundary:
        return 'Boundary';
      case EventType.celebration:
        return 'Celebration';
      case EventType.crowdCheer:
        return 'Crowd Cheer';
      case EventType.scoreChange:
        return 'Score Change';
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
