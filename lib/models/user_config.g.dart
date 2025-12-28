// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserConfigAdapter extends TypeAdapter<UserConfig> {
  @override
  final int typeId = 2;

  @override
  UserConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserConfig(
      waterGoalLiters: fields[0] as double,
      exerciseGoalMinutes: fields[1] as int,
      sunlightGoalMinutes: fields[2] as int,
      sleepGoalHours: fields[3] as double,
      waterIncrementLiters: fields[4] as double,
      exerciseIncrementMinutes: fields[5] as int,
      sunlightIncrementMinutes: fields[6] as int,
      sleepIncrementHours: fields[7] as double,
      aiApiKey: fields[8] as String?,
      aiProvider: fields[9] as String,
      socialGoalMinutes: fields[10] as int,
      socialIncrementMinutes: fields[11] as int,
      proteinGoalGrams: fields[12] as double,
      calorieGoal: fields[13] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserConfig obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.waterGoalLiters)
      ..writeByte(1)
      ..write(obj.exerciseGoalMinutes)
      ..writeByte(2)
      ..write(obj.sunlightGoalMinutes)
      ..writeByte(3)
      ..write(obj.sleepGoalHours)
      ..writeByte(4)
      ..write(obj.waterIncrementLiters)
      ..writeByte(5)
      ..write(obj.exerciseIncrementMinutes)
      ..writeByte(6)
      ..write(obj.sunlightIncrementMinutes)
      ..writeByte(7)
      ..write(obj.sleepIncrementHours)
      ..writeByte(8)
      ..write(obj.aiApiKey)
      ..writeByte(9)
      ..write(obj.aiProvider)
      ..writeByte(10)
      ..write(obj.socialGoalMinutes)
      ..writeByte(11)
      ..write(obj.socialIncrementMinutes)
      ..writeByte(12)
      ..write(obj.proteinGoalGrams)
      ..writeByte(13)
      ..write(obj.calorieGoal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
