import 'package:hive/hive.dart';

import 'exercise_models.dart';

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
    // Location fields
    this.locationAddress,
    this.locationCity,
    this.locationCountry,
    this.locationLat,
    this.locationLng,
    this.availableCategories,
    this.categoriesLastUpdated,
    // Exercise settings
    this.fitnessGoalName,
    this.fitnessLevelName,
    this.preferredWorkoutDuration,
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

  // Location fields for Social Activity Discovery
  @HiveField(14)
  String? locationAddress; // Human readable: "Cape Town, South Africa"

  @HiveField(15)
  String? locationCity; // City name: "Cape Town"

  @HiveField(16)
  String? locationCountry; // Country: "South Africa"

  @HiveField(17)
  double? locationLat; // Latitude

  @HiveField(18)
  double? locationLng; // Longitude

  @HiveField(19)
  List<String>? availableCategories; // Filtered categories for this location

  @HiveField(20)
  DateTime? categoriesLastUpdated; // When categories were last filtered

  // Exercise settings
  @HiveField(21)
  String? fitnessGoalName; // Store enum name as string

  @HiveField(22)
  String? fitnessLevelName; // Store enum name as string

  @HiveField(23)
  int? preferredWorkoutDuration; // In minutes

  // Getters for enum conversion
  FitnessGoal? get fitnessGoal => fitnessGoalName != null
      ? FitnessGoal.values.firstWhere(
          (g) => g.name == fitnessGoalName,
          orElse: () => FitnessGoal.stayActive,
        )
      : null;

  FitnessLevel? get fitnessLevel => fitnessLevelName != null
      ? FitnessLevel.values.firstWhere(
          (l) => l.name == fitnessLevelName,
          orElse: () => FitnessLevel.beginner,
        )
      : null;

  /// Get formatted location string
  String? get formattedLocation {
    if (locationCity != null && locationCountry != null) {
      return '$locationCity, $locationCountry';
    }
    return locationAddress;
  }

  /// Check if location is set
  bool get hasLocation => locationCity != null || locationAddress != null;

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
    String? locationAddress,
    String? locationCity,
    String? locationCountry,
    double? locationLat,
    double? locationLng,
    List<String>? availableCategories,
    DateTime? categoriesLastUpdated,
    String? fitnessGoalName,
    String? fitnessLevelName,
    int? preferredWorkoutDuration,
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
      locationAddress: locationAddress ?? this.locationAddress,
      locationCity: locationCity ?? this.locationCity,
      locationCountry: locationCountry ?? this.locationCountry,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      availableCategories: availableCategories ?? this.availableCategories,
      categoriesLastUpdated: categoriesLastUpdated ?? this.categoriesLastUpdated,
      fitnessGoalName: fitnessGoalName ?? this.fitnessGoalName,
      fitnessLevelName: fitnessLevelName ?? this.fitnessLevelName,
      preferredWorkoutDuration: preferredWorkoutDuration ?? this.preferredWorkoutDuration,
    );
  }
}

