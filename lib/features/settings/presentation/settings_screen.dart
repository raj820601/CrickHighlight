import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/model_download_service.dart';
import '../../../core/services/ml_model_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/utils/logger.dart';

final modelDownloadProvider = StateNotifierProvider<ModelDownloadNotifier, ModelDownloadState>((ref) {
  return ModelDownloadNotifier();
});

class ModelDownloadState {
  final bool isDownloading;
  final bool areModelsDownloaded;
  final String? error;
  final int modelsSizeBytes;

  const ModelDownloadState({
    this.isDownloading = false,
    this.areModelsDownloaded = false,
    this.error,
    this.modelsSizeBytes = 0,
  });

  ModelDownloadState copyWith({
    bool? isDownloading,
    bool? areModelsDownloaded,
    String? error,
    int? modelsSizeBytes,
  }) {
    return ModelDownloadState(
      isDownloading: isDownloading ?? this.isDownloading,
      areModelsDownloaded: areModelsDownloaded ?? this.areModelsDownloaded,
      error: error,
      modelsSizeBytes: modelsSizeBytes ?? this.modelsSizeBytes,
    );
  }
}

class ModelDownloadNotifier extends StateNotifier<ModelDownloadState> {
  ModelDownloadNotifier() : super(const ModelDownloadState()) {
    _checkModelStatus();
  }

  Future<void> _checkModelStatus() async {
    try {
      final areDownloaded = await ModelDownloadService.instance.areModelsDownloaded();
      final size = await ModelDownloadService.instance.getModelsSizeInBytes();
      
      state = state.copyWith(
        areModelsDownloaded: areDownloaded,
        modelsSizeBytes: size,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> downloadModels() async {
    try {
      state = state.copyWith(isDownloading: true, error: null);
      
      await ModelDownloadService.instance.downloadAllModels();
      
      // Reinitialize ML service with new models
      await MLModelService.instance.initialize();
      
      final size = await ModelDownloadService.instance.getModelsSizeInBytes();
      
      state = state.copyWith(
        isDownloading: false,
        areModelsDownloaded: true,
        modelsSizeBytes: size,
      );
      
      AppLogger.info('Models downloaded and initialized successfully');
    } catch (e) {
      state = state.copyWith(
        isDownloading: false,
        error: e.toString(),
      );
      AppLogger.error('Failed to download models', e);
    }
  }

  Future<void> deleteModels() async {
    try {
      await ModelDownloadService.instance.deleteAllModels();
      
      state = state.copyWith(
        areModelsDownloaded: false,
        modelsSizeBytes: 0,
      );
      
      AppLogger.info('Models deleted successfully');
    } catch (e) {
      state = state.copyWith(error: e.toString());
      AppLogger.error('Failed to delete models', e);
    }
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelState = ref.watch(modelDownloadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Models Section
            const Text(
              'AI Models',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          modelState.areModelsDownloaded 
                              ? Icons.check_circle 
                              : Icons.download,
                          color: modelState.areModelsDownloaded 
                              ? const Color(0xFF4CAF50) 
                              : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                modelState.areModelsDownloaded 
                                    ? 'AI Models Installed' 
                                    : 'AI Models Not Installed',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                modelState.areModelsDownloaded
                                    ? 'Advanced AI analysis enabled'
                                    : 'Download models for better accuracy',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    if (modelState.modelsSizeBytes > 0) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Storage used: ${_formatBytes(modelState.modelsSizeBytes)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    if (!modelState.areModelsDownloaded)
                      CustomButton(
                        text: 'Download AI Models',
                        icon: Icons.download,
                        isLoading: modelState.isDownloading,
                        onPressed: () => _downloadModels(context, ref),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'Reinstall Models',
                              icon: Icons.refresh,
                              isOutlined: true,
                              isLoading: modelState.isDownloading,
                              onPressed: () => _reinstallModels(context, ref),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              text: 'Delete Models',
                              icon: Icons.delete,
                              backgroundColor: Colors.red,
                              onPressed: () => _deleteModels(context, ref),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            if (modelState.error != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          modelState.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Model Information Section
            const Text(
              'Model Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildModelInfoCard(
              'Audio Detection Model',
              'Detects cricket sounds like bat hits, crowd cheers, and wicket falls',
              Icons.audiotrack,
            ),
            
            const SizedBox(height: 8),
            
            _buildModelInfoCard(
              'Pose Detection Model',
              'Identifies player actions, celebrations, and cricket poses',
              Icons.accessibility_new,
            ),
            
            const SizedBox(height: 8),
            
            _buildModelInfoCard(
              'Scoreboard OCR Model',
              'Reads scoreboards to detect score changes and boundaries',
              Icons.scoreboard,
            ),

            const Spacer(),

            // App Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Cricket Highlights Generator',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI-powered cricket highlight detection using TensorFlow Lite',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelInfoCard(String title, String description, IconData icon) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1B5E20),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  void _downloadModels(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download AI Models'),
        content: const Text(
          'This will download AI models for better cricket event detection. '
          'The download size is approximately 50MB. Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(modelDownloadProvider.notifier).downloadModels();
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _reinstallModels(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reinstall AI Models'),
        content: const Text(
          'This will delete existing models and download fresh copies. Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(modelDownloadProvider.notifier).deleteModels();
              await ref.read(modelDownloadProvider.notifier).downloadModels();
            },
            child: const Text('Reinstall'),
          ),
        ],
      ),
    );
  }

  void _deleteModels(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete AI Models'),
        content: const Text(
          'This will delete all AI models and free up storage space. '
          'The app will use basic detection methods. Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(modelDownloadProvider.notifier).deleteModels();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}
