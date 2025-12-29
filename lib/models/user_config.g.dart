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
      locationAddress: fields[14] as String?,
      locationCity: fields[15] as String?,
      locationCountry: fields[16] as String?,
      locationLat: fields[17] as double?,
      locationLng: fields[18] as double?,
      availableCategories: (fields[19] as List?)?.cast<String>(),
      categoriesLastUpdated: fields[20] as DateTime?,
      fitnessGoalName: fields[21] as String?,
      fitnessLevelName: fields[22] as String?,
      preferredWorkoutDuration: fields[23] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, UserConfig obj) {
    writer
      ..writeByte(24)
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
      ..write(obj.calorieGoal)
      ..writeByte(14)
      ..write(obj.locationAddress)
      ..writeByte(15)
      ..write(obj.locationCity)
      ..writeByte(16)
      ..write(obj.locationCountry)
      ..writeByte(17)
      ..write(obj.locationLat)
      ..writeByte(18)
      ..write(obj.locationLng)
      ..writeByte(19)
      ..write(obj.availableCategories)
      ..writeByte(20)
      ..write(obj.categoriesLastUpdated)
      ..writeByte(21)
      ..write(obj.fitnessGoalName)
      ..writeByte(22)
      ..write(obj.fitnessLevelName)
      ..writeByte(23)
      ..write(obj.preferredWorkoutDuration);
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
