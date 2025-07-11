import 'package:flutter/material.dart';

void main() {
  runApp(const CricketHighlightsApp());
}

class CricketHighlightsApp extends StatelessWidget {
  const CricketHighlightsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cricket Highlights',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF1B5E20),
        useMaterial3: true,
      ),
      home: const Scaffold(
        appBar: AppBar(
          title: Text('Cricket Highlights'),
          backgroundColor: Color(0xFF1B5E20),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_cricket,
                size: 100,
                color: Color(0xFF1B5E20),
              ),
              SizedBox(height: 20),
              Text(
                'App is building!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'If you see this, the build is working.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
