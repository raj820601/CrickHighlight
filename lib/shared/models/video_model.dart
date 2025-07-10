import 'package:hive/hive.dart';

part 'video_model.g.dart';

@HiveType(typeId: 0)
class VideoModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String path;
  
  @HiveField(3)
  final int durationSeconds;
  
  @HiveField(4)
  final int fileSizeBytes;
  
  @HiveField(5)
  final DateTime createdAt;
  
  @HiveField(6)
  final String? thumbnailPath;
  
  @HiveField(7)
  final bool isAnalyzed;

  VideoModel({
    required this.id,
    required this.name,
    required this.path,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.createdAt,
    this.thumbnailPath,
    this.isAnalyzed = false,
  });

  VideoModel copyWith({
    String? id,
    String? name,
    String? path,
    int? durationSeconds,
    int? fileSizeBytes,
    DateTime? createdAt,
    String? thumbnailPath,
    bool? isAnalyzed,
  }) {
    return VideoModel(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      createdAt: createdAt ?? this.createdAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isAnalyzed: isAnalyzed ?? this.isAnalyzed,
    );
  }
}
