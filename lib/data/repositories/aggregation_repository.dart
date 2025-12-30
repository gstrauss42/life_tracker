import 'dart:convert';
import 'package:hive/hive.dart';

import '../../models/aggregated_data.dart';

/// Repository for storing and retrieving aggregated user data.
/// Aggregates are stored as JSON in Hive for persistence.
abstract class AggregationRepository {
  /// Get the current aggregated data, or null if not yet computed
  AggregatedUserData? getAggregates();

  /// Save aggregated data
  Future<void> saveAggregates(AggregatedUserData data);

  /// Check if aggregates exist
  bool hasAggregates();

  /// Clear aggregates (for testing/reset)
  Future<void> clear();
}

/// Hive implementation of AggregationRepository
class HiveAggregationRepository implements AggregationRepository {
  final Box<String> _box;

  static const String _aggregatesKey = 'aggregates';

  HiveAggregationRepository(this._box);

  @override
  AggregatedUserData? getAggregates() {
    final json = _box.get(_aggregatesKey);
    if (json == null) return null;

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return _fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveAggregates(AggregatedUserData data) async {
    final json = jsonEncode(_toJson(data));
    await _box.put(_aggregatesKey, json);
  }

  @override
  bool hasAggregates() {
    return _box.containsKey(_aggregatesKey);
  }

  @override
  Future<void> clear() async {
    await _box.delete(_aggregatesKey);
  }

  /// Convert AggregatedUserData to JSON
  Map<String, dynamic> _toJson(AggregatedUserData data) {
    return {
      'lastUpdated': data.lastUpdated.toIso8601String(),
      'daysAnalyzed': data.daysAnalyzed,
      'nutrition': _nutritionToJson(data.nutrition),
      'exercise': _exerciseToJson(data.exercise),
      'social': _socialToJson(data.social),
      'simpleMetrics': _simpleMetricsToJson(data.simpleMetrics),
      'patterns': _patternsToJson(data.patterns),
    };
  }

  /// Convert JSON to AggregatedUserData
  AggregatedUserData _fromJson(Map<String, dynamic> json) {
    return AggregatedUserData(
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      daysAnalyzed: json['daysAnalyzed'] as int,
      nutrition: _nutritionFromJson(json['nutrition'] as Map<String, dynamic>),
      exercise: _exerciseFromJson(json['exercise'] as Map<String, dynamic>),
      social: _socialFromJson(json['social'] as Map<String, dynamic>),
      simpleMetrics: _simpleMetricsFromJson(json['simpleMetrics'] as Map<String, dynamic>),
      patterns: _patternsFromJson(json['patterns'] as Map<String, dynamic>),
    );
  }

  // Nutrition serialization
  Map<String, dynamic> _nutritionToJson(NutritionAggregates n) => {
        'avgCalories': n.avgCalories,
        'avgProtein': n.avgProtein,
        'avgCarbs': n.avgCarbs,
        'avgFat': n.avgFat,
        'avgFiber': n.avgFiber,
        'avgMicronutrients': n.avgMicronutrients,
        'consistentDeficiencies': n.consistentDeficiencies,
        'consistentExcesses': n.consistentExcesses,
        'totalMealsLogged': n.totalMealsLogged,
        'avgMealsPerDay': n.avgMealsPerDay,
        'commonFoods': n.commonFoods,
        'topFoods': n.topFoods,
        'calorieGoalHitRate': n.calorieGoalHitRate,
        'proteinGoalHitRate': n.proteinGoalHitRate,
        'inferredPreferences': n.inferredPreferences,
        'daysWithData': n.daysWithData,
      };

  NutritionAggregates _nutritionFromJson(Map<String, dynamic> json) => NutritionAggregates(
        avgCalories: (json['avgCalories'] as num).toDouble(),
        avgProtein: (json['avgProtein'] as num).toDouble(),
        avgCarbs: (json['avgCarbs'] as num).toDouble(),
        avgFat: (json['avgFat'] as num).toDouble(),
        avgFiber: (json['avgFiber'] as num).toDouble(),
        avgMicronutrients: (json['avgMicronutrients'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
        consistentDeficiencies: (json['consistentDeficiencies'] as List<dynamic>).cast<String>(),
        consistentExcesses: (json['consistentExcesses'] as List<dynamic>).cast<String>(),
        totalMealsLogged: json['totalMealsLogged'] as int,
        avgMealsPerDay: (json['avgMealsPerDay'] as num).toDouble(),
        commonFoods: (json['commonFoods'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as int)),
        topFoods: (json['topFoods'] as List<dynamic>).cast<String>(),
        calorieGoalHitRate: (json['calorieGoalHitRate'] as num).toDouble(),
        proteinGoalHitRate: (json['proteinGoalHitRate'] as num).toDouble(),
        inferredPreferences: (json['inferredPreferences'] as List<dynamic>).cast<String>(),
        daysWithData: json['daysWithData'] as int,
      );

  // Exercise serialization
  Map<String, dynamic> _exerciseToJson(ExerciseAggregates e) => {
        'totalWorkoutsLogged': e.totalWorkoutsLogged,
        'totalMinutesExercised': e.totalMinutesExercised,
        'avgMinutesPerDay': e.avgMinutesPerDay,
        'avgMinutesPerWorkout': e.avgMinutesPerWorkout,
        'exerciseGoalHitRate': e.exerciseGoalHitRate,
        'currentStreak': e.currentStreak,
        'longestStreak': e.longestStreak,
        'activeDaysOfWeek': e.activeDaysOfWeek,
        'workoutTypeFrequency': e.workoutTypeFrequency,
        'preferredWorkoutTypes': e.preferredWorkoutTypes,
        'fitnessGoal': e.fitnessGoal,
        'fitnessLevel': e.fitnessLevel,
        'preferredDuration': e.preferredDuration,
        'daysWithData': e.daysWithData,
      };

  ExerciseAggregates _exerciseFromJson(Map<String, dynamic> json) => ExerciseAggregates(
        totalWorkoutsLogged: json['totalWorkoutsLogged'] as int,
        totalMinutesExercised: json['totalMinutesExercised'] as int,
        avgMinutesPerDay: (json['avgMinutesPerDay'] as num).toDouble(),
        avgMinutesPerWorkout: (json['avgMinutesPerWorkout'] as num).toDouble(),
        exerciseGoalHitRate: (json['exerciseGoalHitRate'] as num).toDouble(),
        currentStreak: json['currentStreak'] as int,
        longestStreak: json['longestStreak'] as int,
        activeDaysOfWeek: (json['activeDaysOfWeek'] as List<dynamic>).cast<int>(),
        workoutTypeFrequency: (json['workoutTypeFrequency'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as int)),
        preferredWorkoutTypes: (json['preferredWorkoutTypes'] as List<dynamic>).cast<String>(),
        fitnessGoal: json['fitnessGoal'] as String?,
        fitnessLevel: json['fitnessLevel'] as String?,
        preferredDuration: json['preferredDuration'] as int?,
        daysWithData: json['daysWithData'] as int,
      );

  // Social serialization
  Map<String, dynamic> _socialToJson(SocialAggregates s) => {
        'totalActivitiesLogged': s.totalActivitiesLogged,
        'totalMinutesSocial': s.totalMinutesSocial,
        'avgMinutesPerDay': s.avgMinutesPerDay,
        'socialGoalHitRate': s.socialGoalHitRate,
        'categoryFrequency': s.categoryFrequency,
        'preferredCategories': s.preferredCategories,
        'currentLocation': s.currentLocation,
        'visitedPlaceTypes': s.visitedPlaceTypes,
        'daysWithData': s.daysWithData,
      };

  SocialAggregates _socialFromJson(Map<String, dynamic> json) => SocialAggregates(
        totalActivitiesLogged: json['totalActivitiesLogged'] as int,
        totalMinutesSocial: json['totalMinutesSocial'] as int,
        avgMinutesPerDay: (json['avgMinutesPerDay'] as num).toDouble(),
        socialGoalHitRate: (json['socialGoalHitRate'] as num).toDouble(),
        categoryFrequency: (json['categoryFrequency'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as int)),
        preferredCategories: (json['preferredCategories'] as List<dynamic>).cast<String>(),
        currentLocation: json['currentLocation'] as String?,
        visitedPlaceTypes: (json['visitedPlaceTypes'] as List<dynamic>).cast<String>(),
        daysWithData: json['daysWithData'] as int,
      );

  // Simple metrics serialization
  Map<String, dynamic> _simpleMetricsToJson(SimpleMetricsAggregates m) => {
        'avgWaterLiters': m.avgWaterLiters,
        'waterGoalHitRate': m.waterGoalHitRate,
        'avgSunlightMinutes': m.avgSunlightMinutes,
        'sunlightGoalHitRate': m.sunlightGoalHitRate,
        'avgSleepHours': m.avgSleepHours,
        'sleepGoalHitRate': m.sleepGoalHitRate,
        'minSleep': m.minSleep,
        'maxSleep': m.maxSleep,
        'daysWithData': m.daysWithData,
      };

  SimpleMetricsAggregates _simpleMetricsFromJson(Map<String, dynamic> json) => SimpleMetricsAggregates(
        avgWaterLiters: (json['avgWaterLiters'] as num).toDouble(),
        waterGoalHitRate: (json['waterGoalHitRate'] as num).toDouble(),
        avgSunlightMinutes: (json['avgSunlightMinutes'] as num).toDouble(),
        sunlightGoalHitRate: (json['sunlightGoalHitRate'] as num).toDouble(),
        avgSleepHours: (json['avgSleepHours'] as num).toDouble(),
        sleepGoalHitRate: (json['sleepGoalHitRate'] as num).toDouble(),
        minSleep: (json['minSleep'] as num).toDouble(),
        maxSleep: (json['maxSleep'] as num).toDouble(),
        daysWithData: json['daysWithData'] as int,
      );

  // Patterns serialization
  Map<String, dynamic> _patternsToJson(PatternData p) => {
        'exerciseByDayOfWeek': p.exerciseByDayOfWeek.map((k, v) => MapEntry(k.toString(), v)),
        'caloriesByDayOfWeek': p.caloriesByDayOfWeek.map((k, v) => MapEntry(k.toString(), v)),
        'sleepByDayOfWeek': p.sleepByDayOfWeek.map((k, v) => MapEntry(k.toString(), v)),
        'sleepExerciseCorrelation': p.sleepExerciseCorrelation,
        'exerciseCaloriesCorrelation': p.exerciseCaloriesCorrelation,
        'exerciseTrend': p.exerciseTrend,
        'nutritionTrend': p.nutritionTrend,
        'sleepTrend': p.sleepTrend,
      };

  PatternData _patternsFromJson(Map<String, dynamic> json) => PatternData(
        exerciseByDayOfWeek: (json['exerciseByDayOfWeek'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(int.parse(k), (v as num).toDouble())),
        caloriesByDayOfWeek: (json['caloriesByDayOfWeek'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(int.parse(k), (v as num).toDouble())),
        sleepByDayOfWeek: (json['sleepByDayOfWeek'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(int.parse(k), (v as num).toDouble())),
        sleepExerciseCorrelation: (json['sleepExerciseCorrelation'] as num?)?.toDouble(),
        exerciseCaloriesCorrelation: (json['exerciseCaloriesCorrelation'] as num?)?.toDouble(),
        exerciseTrend: json['exerciseTrend'] as String?,
        nutritionTrend: json['nutritionTrend'] as String?,
        sleepTrend: json['sleepTrend'] as String?,
      );
}


