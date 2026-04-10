// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimerSessionAdapter extends TypeAdapter<TimerSession> {
  @override
  final int typeId = 0;

  @override
  TimerSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimerSession(
      id: fields[0] as String,
      startedAt: fields[1] as DateTime,
      durationSeconds: fields[2] as int,
      targetSeconds: fields[3] as int?,
      completed: fields[4] as bool,
      soundId: fields[5] as String,
      intervalSeconds: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, TimerSession obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startedAt)
      ..writeByte(2)
      ..write(obj.durationSeconds)
      ..writeByte(3)
      ..write(obj.targetSeconds)
      ..writeByte(4)
      ..write(obj.completed)
      ..writeByte(5)
      ..write(obj.soundId)
      ..writeByte(6)
      ..write(obj.intervalSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
