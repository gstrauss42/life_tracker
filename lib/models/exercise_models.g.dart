// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseActivityAdapter extends TypeAdapter<ExerciseActivity> {
  @override
  final int typeId = 3;

  @override
  ExerciseActivity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseActivity(
      id: fields[0] as String,
      name: fields[1] as String,
      durationMinutes: fields[2] as int,
      timestamp: fields[3] as DateTime,
      notes: fields[4] as String?,
      workoutId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseActivity obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.durationMinutes)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.workoutId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseActivityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
