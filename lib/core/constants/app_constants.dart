class AppConstants {
  // App Info
  static const String appName = 'Cricket Highlights';
  static const String appVersion = '1.0.0';
  
  // Video Processing
  static const int maxVideoLengthMinutes = 180; // 3 hours
  static const int minVideoLengthSeconds = 30;
  static const List<String> supportedVideoFormats = ['mp4', 'mov', 'avi'];
  
  // AI Analysis
  static const double audioSpikeThreshold = 0.7;
  static const int analysisWindowSeconds = 5;
  static const int highlightBufferSeconds = 10;
  
  // Storage
  static const String videosFolder = 'cricket_videos';
  static const String highlightsFolder = 'highlights';
  static const String tempFolder = 'temp';
  static const String modelsFolder = 'models';
  
  // Database
  static const String databaseName = 'cricket_highlights.db';
  static const int databaseVersion = 1;
}

class AppColors {
  static const int primaryColor = 0xFF1B5E20;
  static const int secondaryColor = 0xFF4CAF50;
  static const int accentColor = 0xFFFF6F00;
  static const int backgroundColor = 0xFFF5F5F5;
  static const int surfaceColor = 0xFFFFFFFF;
  static const int errorColor = 0xFFD32F2F;
}
