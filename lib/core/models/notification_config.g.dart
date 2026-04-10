// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationConfigAdapter extends TypeAdapter<NotificationConfig> {
  @override
  final int typeId = 1;

  @override
  NotificationConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationConfig(
      enabled: fields[0] as bool,
      activeDays: (fields[1] as List).cast<int>(),
      startHour: fields[2] as int,
      endHour: fields[3] as int,
      frequencyPerDay: fields[4] as int,
      bellSoundId: fields[5] as String,
      dailyGathaEnabled: fields[6] as bool,
      dailyGathaHour: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationConfig obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.enabled)
      ..writeByte(1)
      ..write(obj.activeDays)
      ..writeByte(2)
      ..write(obj.startHour)
      ..writeByte(3)
      ..write(obj.endHour)
      ..writeByte(4)
      ..write(obj.frequencyPerDay)
      ..writeByte(5)
      ..write(obj.bellSoundId)
      ..writeByte(6)
      ..write(obj.dailyGathaEnabled)
      ..writeByte(7)
      ..write(obj.dailyGathaHour);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
