import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/services/storage_service.dart';
import 'core/utils/logger.dart';
import 'features/home/presentation/home_screen.dart';
import 'core/services/ml_model_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize storage service
    await StorageService.instance.initialize();
    AppLogger.info('Storage service initialized');
    
    // Initialize ML models
    await MLModelService.instance.initialize();
    AppLogger.info('ML models initialized');
    
    AppLogger.info('App initialized successfully');
  } catch (e) {
    AppLogger.error('Failed to initialize app', e);
    // Continue anyway - app can work with fallback methods
  }

  runApp(
    const ProviderScope(
      child: CricketHighlightsApp(),
    ),
  );
}

class CricketHighlightsApp extends StatelessWidget {
  const CricketHighlightsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Cricket Highlights',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.green,
            primaryColor: const Color(0xFF1B5E20),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1B5E20),
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardTheme: CardTheme(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            useMaterial3: true,
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
