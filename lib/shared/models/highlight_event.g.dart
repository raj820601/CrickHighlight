// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'highlight_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventTypeAdapter extends TypeAdapter<EventType> {
  @override
  final int typeId = 1;

  @override
  EventType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EventType.batHit;
      case 1:
        return EventType.wicket;
      case 2:
        return EventType.boundary;
      case 3:
        return EventType.celebration;
      case 4:
        return EventType.crowdCheer;
      case 5:
        return EventType.scoreChange;
      default:
        return EventType.batHit;
    }
  }

  @override
  void write(BinaryWriter writer, EventType obj) {
    switch (obj) {
      case EventType.batHit:
        writer.writeByte(0);
        break;
      case EventType.wicket:
        writer.writeByte(1);
        break;
      case EventType.boundary:
        writer.writeByte(2);
        break;
      case EventType.celebration:
        writer.writeByte(3);
        break;
      case EventType.crowdCheer:
        writer.writeByte(4);
        break;
      case EventType.scoreChange:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HighlightEventAdapter extends TypeAdapter<HighlightEvent> {
  @override
  final int typeId = 2;

  @override
  HighlightEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HighlightEvent(
      id: fields[0] as String,
      videoId: fields[1] as String,
      eventType: fields[2] as EventType,
      startTimeSeconds: fields[3] as int,
      endTimeSeconds: fields[4] as int,
      confidence: fields[5] as double,
      description: fields[6] as String?,
      detectedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HighlightEvent obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.videoId)
      ..writeByte(2)
      ..write(obj.eventType)
      ..writeByte(3)
      ..write(obj.startTimeSeconds)
      ..writeByte(4)
      ..write(obj.endTimeSeconds)
      ..writeByte(5)
      ..write(obj.confidence)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.detectedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HighlightEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
