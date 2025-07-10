import 'package:hive/hive.dart';

part 'highlight_event.g.dart';

@HiveType(typeId: 1)
enum EventType {
  @HiveField(0)
  batHit,
  @HiveField(1)
  wicket,
  @HiveField(2)
  boundary,
  @HiveField(3)
  celebration,
  @HiveField(4)
  crowdCheer,
  @HiveField(5)
  scoreChange,
}

@HiveType(typeId: 2)
class HighlightEvent extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String videoId;
  
  @HiveField(2)
  final EventType eventType;
  
  @HiveField(3)
  final int startTimeSeconds;
  
  @HiveField(4)
  final int endTimeSeconds;
  
  @HiveField(5)
  final double confidence;
  
  @HiveField(6)
  final String? description;
  
  @HiveField(7)
  final DateTime detectedAt;

  HighlightEvent({
    required this.id,
    required this.videoId,
    required this.eventType,
    required this.startTimeSeconds,
    required this.endTimeSeconds,
    required this.confidence,
    this.description,
    required this.detectedAt,
  });

  int get durationSeconds => endTimeSeconds - startTimeSeconds;
}
