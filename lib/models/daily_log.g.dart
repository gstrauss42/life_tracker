// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyLogAdapter extends TypeAdapter<DailyLog> {
  @override
  final int typeId = 0;

  @override
  DailyLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyLog(
      date: fields[0] as String,
      waterLiters: fields[1] as double,
      exerciseMinutes: fields[2] as int,
      sunlightMinutes: fields[3] as int,
      sleepHours: fields[4] as double,
      foodEntries: (fields[5] as List?)?.cast<FoodEntry>(),
      notes: fields[6] as String,
      socialMinutes: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DailyLog obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.waterLiters)
      ..writeByte(2)
      ..write(obj.exerciseMinutes)
      ..writeByte(3)
      ..write(obj.sunlightMinutes)
      ..writeByte(4)
      ..write(obj.sleepHours)
      ..writeByte(5)
      ..write(obj.foodEntries)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.socialMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FoodEntryAdapter extends TypeAdapter<FoodEntry> {
  @override
  final int typeId = 1;

  @override
  FoodEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodEntry(
      id: fields[0] as String,
      name: fields[1] as String,
      timestamp: fields[2] as DateTime,
      originalInput: fields[20] as String?,
      calories: fields[3] as double?,
      protein: fields[4] as double?,
      carbs: fields[5] as double?,
      fat: fields[6] as double?,
      healthScore: fields[7] as double?,
      imagePath: fields[8] as String?,
      aiAnalysis: fields[9] as String?,
      fiber: fields[10] as double?,
      sugar: fields[11] as double?,
      sodium: fields[12] as double?,
      vitaminC: fields[13] as double?,
      vitaminD: fields[14] as double?,
      calcium: fields[15] as double?,
      iron: fields[16] as double?,
      potassium: fields[17] as double?,
      servingSize: fields[18] as double?,
      servingUnit: fields[19] as String?,
      vitaminA: fields[21] as double?,
      vitaminE: fields[22] as double?,
      vitaminK: fields[23] as double?,
      vitaminB1: fields[24] as double?,
      vitaminB2: fields[25] as double?,
      vitaminB3: fields[26] as double?,
      vitaminB6: fields[27] as double?,
      vitaminB12: fields[28] as double?,
      folate: fields[29] as double?,
      magnesium: fields[30] as double?,
      zinc: fields[31] as double?,
      phosphorus: fields[32] as double?,
      selenium: fields[33] as double?,
      iodine: fields[34] as double?,
      omega3: fields[35] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, FoodEntry obj) {
    writer
      ..writeByte(36)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.calories)
      ..writeByte(4)
      ..write(obj.protein)
      ..writeByte(5)
      ..write(obj.carbs)
      ..writeByte(6)
      ..write(obj.fat)
      ..writeByte(7)
      ..write(obj.healthScore)
      ..writeByte(8)
      ..write(obj.imagePath)
      ..writeByte(9)
      ..write(obj.aiAnalysis)
      ..writeByte(10)
      ..write(obj.fiber)
      ..writeByte(11)
      ..write(obj.sugar)
      ..writeByte(12)
      ..write(obj.sodium)
      ..writeByte(13)
      ..write(obj.vitaminC)
      ..writeByte(14)
      ..write(obj.vitaminD)
      ..writeByte(15)
      ..write(obj.calcium)
      ..writeByte(16)
      ..write(obj.iron)
      ..writeByte(17)
      ..write(obj.potassium)
      ..writeByte(18)
      ..write(obj.servingSize)
      ..writeByte(19)
      ..write(obj.servingUnit)
      ..writeByte(20)
      ..write(obj.originalInput)
      ..writeByte(21)
      ..write(obj.vitaminA)
      ..writeByte(22)
      ..write(obj.vitaminE)
      ..writeByte(23)
      ..write(obj.vitaminK)
      ..writeByte(24)
      ..write(obj.vitaminB1)
      ..writeByte(25)
      ..write(obj.vitaminB2)
      ..writeByte(26)
      ..write(obj.vitaminB3)
      ..writeByte(27)
      ..write(obj.vitaminB6)
      ..writeByte(28)
      ..write(obj.vitaminB12)
      ..writeByte(29)
      ..write(obj.folate)
      ..writeByte(30)
      ..write(obj.magnesium)
      ..writeByte(31)
      ..write(obj.zinc)
      ..writeByte(32)
      ..write(obj.phosphorus)
      ..writeByte(33)
      ..write(obj.selenium)
      ..writeByte(34)
      ..write(obj.iodine)
      ..writeByte(35)
      ..write(obj.omega3);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
