import 'package:hive/hive.dart';

part 'user_config.g.dart';

/// User preferences and daily goals.
@HiveType(typeId: 2)
class UserConfig extends HiveObject {
  UserConfig({
    this.waterGoalLiters = 2.5,
    this.exerciseGoalMinutes = 30,
    this.sunlightGoalMinutes = 20,
    this.sleepGoalHours = 8.0,
    this.waterIncrementLiters = 0.25,
    this.exerciseIncrementMinutes = 5,
    this.sunlightIncrementMinutes = 5,
    this.sleepIncrementHours = 0.5,
    this.aiApiKey,
    this.aiProvider = 'openai',
    this.socialGoalMinutes = 20,
    this.socialIncrementMinutes = 5,
    this.proteinGoalGrams = 50,
    this.calorieGoal = 2000,
  });

  // Daily goals
  @HiveField(0)
  double waterGoalLiters;

  @HiveField(1)
  int exerciseGoalMinutes;

  @HiveField(2)
  int sunlightGoalMinutes;

  @HiveField(3)
  double sleepGoalHours;

  // Increment amounts for +/- buttons
  @HiveField(4)
  double waterIncrementLiters;

  @HiveField(5)
  int exerciseIncrementMinutes;

  @HiveField(6)
  int sunlightIncrementMinutes;

  @HiveField(7)
  double sleepIncrementHours;

  // AI configuration
  @HiveField(8)
  String? aiApiKey;

  @HiveField(9)
  String aiProvider; // 'openai', 'anthropic', etc.

  // Social interaction goal
  @HiveField(10)
  int socialGoalMinutes;

  @HiveField(11)
  int socialIncrementMinutes;

  // Nutrition goals
  @HiveField(12)
  double proteinGoalGrams;

  @HiveField(13)
  int calorieGoal;

  UserConfig copyWith({
    double? waterGoalLiters,
    int? exerciseGoalMinutes,
    int? sunlightGoalMinutes,
    double? sleepGoalHours,
    double? waterIncrementLiters,
    int? exerciseIncrementMinutes,
    int? sunlightIncrementMinutes,
    double? sleepIncrementHours,
    String? aiApiKey,
    String? aiProvider,
    int? socialGoalMinutes,
    int? socialIncrementMinutes,
    double? proteinGoalGrams,
    int? calorieGoal,
  }) {
    return UserConfig(
      waterGoalLiters: waterGoalLiters ?? this.waterGoalLiters,
      exerciseGoalMinutes: exerciseGoalMinutes ?? this.exerciseGoalMinutes,
      sunlightGoalMinutes: sunlightGoalMinutes ?? this.sunlightGoalMinutes,
      sleepGoalHours: sleepGoalHours ?? this.sleepGoalHours,
      waterIncrementLiters: waterIncrementLiters ?? this.waterIncrementLiters,
      exerciseIncrementMinutes: exerciseIncrementMinutes ?? this.exerciseIncrementMinutes,
      sunlightIncrementMinutes: sunlightIncrementMinutes ?? this.sunlightIncrementMinutes,
      sleepIncrementHours: sleepIncrementHours ?? this.sleepIncrementHours,
      aiApiKey: aiApiKey ?? this.aiApiKey,
      aiProvider: aiProvider ?? this.aiProvider,
      socialGoalMinutes: socialGoalMinutes ?? this.socialGoalMinutes,
      socialIncrementMinutes: socialIncrementMinutes ?? this.socialIncrementMinutes,
      proteinGoalGrams: proteinGoalGrams ?? this.proteinGoalGrams,
      calorieGoal: calorieGoal ?? this.calorieGoal,
    );
  }
}

