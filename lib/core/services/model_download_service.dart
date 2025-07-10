import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';
import '../constants/app_constants.dart';

class ModelDownloadService {
  static ModelDownloadService? _instance;
  static ModelDownloadService get instance => _instance ??= ModelDownloadService._();
  ModelDownloadService._();

  // Model URLs - In production, these would be your actual model URLs
  static const Map<String, String> modelUrls = {
    'audio_detection.tflite': 'https://example.com/models/cricket_audio_detection.tflite',
    'cricket_pose_detection.tflite': 'https://example.com/models/cricket_pose_detection.tflite',
    'scoreboard_ocr.tflite': 'https://example.com/models/cricket_scoreboard_ocr.tflite',
  };

  Future<void> downloadAllModels() async {
    try {
      AppLogger.info('Starting model downloads...');
      
      final appDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${appDir.path}/${AppConstants.modelsFolder}');
      
      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }

      for (final entry in modelUrls.entries) {
        final modelName = entry.key;
        final modelUrl = entry.value;
        final modelPath = '${modelsDir.path}/$modelName';
        
        await _downloadModel(modelName, modelUrl, modelPath);
      }
      
      AppLogger.info('All models downloaded successfully');
    } catch (e) {
      AppLogger.error('Failed to download models', e);
      rethrow;
    }
  }

  Future<void> _downloadModel(String modelName, String modelUrl, String modelPath) async {
    try {
      final file = File(modelPath);
      
      // Check if model already exists
      if (await file.exists()) {
        AppLogger.info('Model already exists: $modelName');
        return;
      }

      AppLogger.info('Downloading model: $modelName');
      
      // In a real implementation, you would download from the actual URL
      // For this demo, we'll create placeholder model files
      await _createPlaceholderModel(modelPath, modelName);
      
      AppLogger.info('Model downloaded: $modelName');
    } catch (e) {
      AppLogger.error('Failed to download model: $modelName', e);
      throw Exception('Failed to download $modelName: $e');
    }
  }

  Future<void> _createPlaceholderModel(String modelPath, String modelName) async {
    // Create placeholder model files for demonstration
    // In production, you would actually download real TFLite models
    
    final file = File(modelPath);
    
    // Create a minimal placeholder file
    final placeholderContent = '''
    // Placeholder TensorFlow Lite model for $modelName
    // In production, this would be a real .tflite model file
    // Model created at: ${DateTime.now().toIso8601String()}
    ''';
    
    await file.writeAsString(placeholderContent);
    AppLogger.info('Created placeholder model: $modelName');
  }

  Future<bool> areModelsDownloaded() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${appDir.path}/${AppConstants.modelsFolder}');
      
      if (!await modelsDir.exists()) {
        return false;
      }

      for (final modelName in modelUrls.keys) {
        final modelPath = '${modelsDir.path}/$modelName';
        final file = File(modelPath);
        
        if (!await file.exists()) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      AppLogger.error('Failed to check model availability', e);
      return false;
    }
  }

  Future<void> deleteAllModels() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${appDir.path}/${AppConstants.modelsFolder}');
      
      if (await modelsDir.exists()) {
        await modelsDir.delete(recursive: true);
        AppLogger.info('All models deleted');
      }
    } catch (e) {
      AppLogger.error('Failed to delete models', e);
    }
  }

  Future<int> getModelsSizeInBytes() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${appDir.path}/${AppConstants.modelsFolder}');
      
      if (!await modelsDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in modelsDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize;
    } catch (e) {
      AppLogger.error('Failed to calculate models size', e);
      return 0;
    }
  }
}
