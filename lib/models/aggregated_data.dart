/// Aggregated user data computed from historical logs.
/// Updated when underlying data changes, provides context for AI features.
library;

/// Aggregated user data computed from historical logs
/// Updated when underlying data changes
class AggregatedUserData {
  const AggregatedUserData({
    required this.lastUpdated,
    required this.daysAnalyzed,
    required this.nutrition,
    required this.exercise,
    required this.social,
    required this.simpleMetrics,
    required this.patterns,
  });

  final DateTime lastUpdated;
  final int daysAnalyzed;

  /// Nutrition aggregates
  final NutritionAggregates nutrition;

  /// Exercise aggregates
  final ExerciseAggregates exercise;

  /// Social aggregates
  final SocialAggregates social;

  /// Simple metrics aggregates
  final SimpleMetricsAggregates simpleMetrics;

  /// Patterns & correlations (for future AI insights)
  final PatternData patterns;

  /// Create empty aggregates for new users
  factory AggregatedUserData.empty() {
    return AggregatedUserData(
      lastUpdated: DateTime.now(),
      daysAnalyzed: 0,
      nutrition: NutritionAggregates.empty(),
      exercise: ExerciseAggregates.empty(),
      social: SocialAggregates.empty(),
      simpleMetrics: SimpleMetricsAggregates.empty(),
      patterns: PatternData.empty(),
    );
  }

  /// Check if we have meaningful data
  bool get hasData => daysAnalyzed > 0;

  /// Check if we have enough data for reliable patterns (at least 3 days)
  bool get hasEnoughDataForPatterns => daysAnalyzed >= 3;

  /// Generate complete AI context string for all aggregates
  String toAIContext() {
    final buffer = StringBuffer();
    buffer.writeln('=== User Health Data Summary (${daysAnalyzed} days analyzed) ===');
    buffer.writeln('Last updated: ${lastUpdated.toIso8601String()}');
    buffer.writeln();

    if (nutrition.hasData) {
      buffer.writeln(nutrition.toAIContext());
    }

    if (exercise.hasData) {
      buffer.writeln(exercise.toAIContext());
    }

    if (social.hasData) {
      buffer.writeln(social.toAIContext());
    }

    // Simple metrics summary
    buffer.writeln('Daily Metrics Summary:');
    buffer.writeln('- Water: ${simpleMetrics.avgWaterLiters.toStringAsFixed(1)}L avg, ${(simpleMetrics.waterGoalHitRate * 100).round()}% goal hit rate');
    buffer.writeln('- Sunlight: ${simpleMetrics.avgSunlightMinutes.round()} min avg, ${(simpleMetrics.sunlightGoalHitRate * 100).round()}% goal hit rate');
    buffer.writeln('- Sleep: ${simpleMetrics.avgSleepHours.toStringAsFixed(1)} hrs avg (range: ${simpleMetrics.minSleep.toStringAsFixed(1)}-${simpleMetrics.maxSleep.toStringAsFixed(1)}), ${(simpleMetrics.sleepGoalHitRate * 100).round()}% goal hit rate');
    buffer.writeln();

    // Patterns
    if (patterns.hasPatterns) {
      buffer.writeln('Detected Patterns:');
      if (patterns.exerciseTrend != null) {
        buffer.writeln('- Exercise trend: ${patterns.exerciseTrend}');
      }
      if (patterns.sleepTrend != null) {
        buffer.writeln('- Sleep trend: ${patterns.sleepTrend}');
      }
      if (patterns.nutritionTrend != null) {
        buffer.writeln('- Nutrition trend: ${patterns.nutritionTrend}');
      }
      if (patterns.sleepExerciseCorrelation != null && patterns.sleepExerciseCorrelation!.abs() > 0.3) {
        buffer.writeln('- Sleep-exercise correlation: ${patterns.sleepExerciseCorrelation!.toStringAsFixed(2)}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}

/// Nutrition data aggregated over time period
class NutritionAggregates {
  const NutritionAggregates({
    required this.avgCalories,
    required this.avgProtein,
    required this.avgCarbs,
    required this.avgFat,
    required this.avgFiber,
    required this.avgMicronutrients,
    required this.consistentDeficiencies,
    required this.consistentExcesses,
    required this.totalMealsLogged,
    required this.avgMealsPerDay,
    required this.commonFoods,
    required this.topFoods,
    required this.calorieGoalHitRate,
    required this.proteinGoalHitRate,
    required this.inferredPreferences,
    required this.daysWithData,
  });

  // Averages
  final double avgCalories;
  final double avgProtein;
  final double avgCarbs;
  final double avgFat;
  final double avgFiber;

  // Micronutrient averages (key ones)
  final Map<String, double> avgMicronutrients;

  // Deficiency tracking
  final List<String> consistentDeficiencies;
  final List<String> consistentExcesses;

  // Meal patterns
  final int totalMealsLogged;
  final double avgMealsPerDay;
  final Map<String, int> commonFoods;
  final List<String> topFoods;

  // Goal performance
  final double calorieGoalHitRate;
  final double proteinGoalHitRate;

  // Dietary preferences (inferred from logged foods)
  final List<String> inferredPreferences;

  // Days with actual data
  final int daysWithData;

  factory NutritionAggregates.empty() {
    return const NutritionAggregates(
      avgCalories: 0,
      avgProtein: 0,
      avgCarbs: 0,
      avgFat: 0,
      avgFiber: 0,
      avgMicronutrients: {},
      consistentDeficiencies: [],
      consistentExcesses: [],
      totalMealsLogged: 0,
      avgMealsPerDay: 0,
      commonFoods: {},
      topFoods: [],
      calorieGoalHitRate: 0,
      proteinGoalHitRate: 0,
      inferredPreferences: [],
      daysWithData: 0,
    );
  }

  bool get hasData => totalMealsLogged > 0;

  /// Generate AI context string for nutrition-related prompts
  String toAIContext() {
    if (!hasData) return '';

    final buffer = StringBuffer();
    buffer.writeln("User's eating patterns (last $daysWithData days with food logged):");
    buffer.writeln('- Average daily calories: ${avgCalories.round()} kcal');
    buffer.writeln('- Average macros: ${avgProtein.round()}g protein, ${avgCarbs.round()}g carbs, ${avgFat.round()}g fat');

    if (topFoods.isNotEmpty) {
      buffer.writeln('- Common foods they enjoy: ${topFoods.take(5).join(', ')}');
    }

    if (consistentDeficiencies.isNotEmpty) {
      buffer.writeln('- Consistent deficiencies: ${consistentDeficiencies.join(', ')}');
    }

    if (consistentExcesses.isNotEmpty) {
      buffer.writeln('- Consistently exceeds: ${consistentExcesses.join(', ')}');
    }

    if (inferredPreferences.isNotEmpty) {
      buffer.writeln('- Dietary tendencies: ${inferredPreferences.join(', ')}');
    }

    buffer.writeln('- Calorie goal hit rate: ${(calorieGoalHitRate * 100).round()}%');
    buffer.writeln('- Protein goal hit rate: ${(proteinGoalHitRate * 100).round()}%');

    return buffer.toString();
  }
}

/// Exercise data aggregated over time period
class ExerciseAggregates {
  const ExerciseAggregates({
    required this.totalWorkoutsLogged,
    required this.totalMinutesExercised,
    required this.avgMinutesPerDay,
    required this.avgMinutesPerWorkout,
    required this.exerciseGoalHitRate,
    required this.currentStreak,
    required this.longestStreak,
    required this.activeDaysOfWeek,
    required this.workoutTypeFrequency,
    required this.preferredWorkoutTypes,
    required this.fitnessGoal,
    required this.fitnessLevel,
    required this.preferredDuration,
    required this.daysWithData,
  });

  // Volume
  final int totalWorkoutsLogged;
  final int totalMinutesExercised;
  final double avgMinutesPerDay;
  final double avgMinutesPerWorkout;

  // Consistency
  final double exerciseGoalHitRate;
  final int currentStreak;
  final int longestStreak;
  final List<int> activeDaysOfWeek; // 1=Mon, 7=Sun

  // Workout types
  final Map<String, int> workoutTypeFrequency;
  final List<String> preferredWorkoutTypes;

  // User settings context
  final String? fitnessGoal;
  final String? fitnessLevel;
  final int? preferredDuration;

  // Days with actual data
  final int daysWithData;

  factory ExerciseAggregates.empty() {
    return const ExerciseAggregates(
      totalWorkoutsLogged: 0,
      totalMinutesExercised: 0,
      avgMinutesPerDay: 0,
      avgMinutesPerWorkout: 0,
      exerciseGoalHitRate: 0,
      currentStreak: 0,
      longestStreak: 0,
      activeDaysOfWeek: [],
      workoutTypeFrequency: {},
      preferredWorkoutTypes: [],
      fitnessGoal: null,
      fitnessLevel: null,
      preferredDuration: null,
      daysWithData: 0,
    );
  }

  bool get hasData => totalWorkoutsLogged > 0;

  /// Format active days for display
  String formatActiveDays() {
    if (activeDaysOfWeek.isEmpty) return 'No consistent pattern';

    const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return activeDaysOfWeek.map((d) => dayNames[d]).join(', ');
  }

  /// Generate AI context string for exercise-related prompts
  String toAIContext() {
    if (!hasData) return '';

    final buffer = StringBuffer();
    buffer.writeln("User's exercise history (last $totalWorkoutsLogged workouts):");
    buffer.writeln('- Average workout duration: ${avgMinutesPerWorkout.round()} min');

    if (preferredWorkoutTypes.isNotEmpty) {
      buffer.writeln('- Preferred workout types: ${preferredWorkoutTypes.join(', ')}');
    }

    if (activeDaysOfWeek.isNotEmpty) {
      buffer.writeln('- Most active days: ${formatActiveDays()}');
    }

    buffer.writeln('- Current streak: $currentStreak days');
    buffer.writeln('- Goal hit rate: ${(exerciseGoalHitRate * 100).round()}%');

    if (fitnessGoal != null) {
      buffer.writeln('- Fitness goal: $fitnessGoal');
    }
    if (fitnessLevel != null) {
      buffer.writeln('- Fitness level: $fitnessLevel');
    }

    return buffer.toString();
  }
}

/// Social activity aggregated over time period
class SocialAggregates {
  const SocialAggregates({
    required this.totalActivitiesLogged,
    required this.totalMinutesSocial,
    required this.avgMinutesPerDay,
    required this.socialGoalHitRate,
    required this.categoryFrequency,
    required this.preferredCategories,
    required this.currentLocation,
    required this.visitedPlaceTypes,
    required this.daysWithData,
  });

  // Volume
  final int totalActivitiesLogged;
  final int totalMinutesSocial;
  final double avgMinutesPerDay;

  // Consistency
  final double socialGoalHitRate;

  // Category preferences
  final Map<String, int> categoryFrequency;
  final List<String> preferredCategories;

  // Location context
  final String? currentLocation;
  final List<String> visitedPlaceTypes;

  // Days with actual data
  final int daysWithData;

  factory SocialAggregates.empty() {
    return const SocialAggregates(
      totalActivitiesLogged: 0,
      totalMinutesSocial: 0,
      avgMinutesPerDay: 0,
      socialGoalHitRate: 0,
      categoryFrequency: {},
      preferredCategories: [],
      currentLocation: null,
      visitedPlaceTypes: [],
      daysWithData: 0,
    );
  }

  bool get hasData => totalActivitiesLogged > 0 || totalMinutesSocial > 0;

  /// Generate AI context string for social-related prompts
  String toAIContext() {
    if (!hasData) return '';

    final buffer = StringBuffer();
    buffer.writeln("User's social preferences:");

    if (preferredCategories.isNotEmpty) {
      buffer.writeln('- Favorite activity types: ${preferredCategories.take(3).join(', ')}');
    }

    buffer.writeln('- Total activities logged: $totalActivitiesLogged');
    buffer.writeln('- Average social time per day: ${avgMinutesPerDay.round()} min');
    buffer.writeln('- Social goal hit rate: ${(socialGoalHitRate * 100).round()}%');

    if (currentLocation != null) {
      buffer.writeln('- Current location: $currentLocation');
    }

    return buffer.toString();
  }
}

/// Simple daily metrics aggregated
class SimpleMetricsAggregates {
  const SimpleMetricsAggregates({
    required this.avgWaterLiters,
    required this.waterGoalHitRate,
    required this.avgSunlightMinutes,
    required this.sunlightGoalHitRate,
    required this.avgSleepHours,
    required this.sleepGoalHitRate,
    required this.minSleep,
    required this.maxSleep,
    required this.daysWithData,
  });

  // Water
  final double avgWaterLiters;
  final double waterGoalHitRate;

  // Sunlight
  final double avgSunlightMinutes;
  final double sunlightGoalHitRate;

  // Sleep
  final double avgSleepHours;
  final double sleepGoalHitRate;
  final double minSleep;
  final double maxSleep;

  // Days with actual data
  final int daysWithData;

  factory SimpleMetricsAggregates.empty() {
    return const SimpleMetricsAggregates(
      avgWaterLiters: 0,
      waterGoalHitRate: 0,
      avgSunlightMinutes: 0,
      sunlightGoalHitRate: 0,
      avgSleepHours: 0,
      sleepGoalHitRate: 0,
      minSleep: 0,
      maxSleep: 0,
      daysWithData: 0,
    );
  }

  bool get hasData => daysWithData > 0;
}

/// Detected patterns and correlations
class PatternData {
  const PatternData({
    required this.exerciseByDayOfWeek,
    required this.caloriesByDayOfWeek,
    required this.sleepByDayOfWeek,
    this.sleepExerciseCorrelation,
    this.exerciseCaloriesCorrelation,
    this.exerciseTrend,
    this.nutritionTrend,
    this.sleepTrend,
  });

  // Day-of-week patterns (1=Mon -> avg value)
  final Map<int, double> exerciseByDayOfWeek;
  final Map<int, double> caloriesByDayOfWeek;
  final Map<int, double> sleepByDayOfWeek;

  // Simple correlations (computed if enough data)
  final double? sleepExerciseCorrelation;
  final double? exerciseCaloriesCorrelation;

  // Trends
  final String? exerciseTrend; // "increasing", "decreasing", "stable"
  final String? nutritionTrend;
  final String? sleepTrend;

  factory PatternData.empty() {
    return const PatternData(
      exerciseByDayOfWeek: {},
      caloriesByDayOfWeek: {},
      sleepByDayOfWeek: {},
    );
  }

  bool get hasPatterns =>
      exerciseByDayOfWeek.isNotEmpty ||
      caloriesByDayOfWeek.isNotEmpty ||
      sleepByDayOfWeek.isNotEmpty;

  /// Get the most active day of the week
  int? get mostActiveDay {
    if (exerciseByDayOfWeek.isEmpty) return null;
    var maxDay = exerciseByDayOfWeek.keys.first;
    for (final day in exerciseByDayOfWeek.keys) {
      if (exerciseByDayOfWeek[day]! > exerciseByDayOfWeek[maxDay]!) {
        maxDay = day;
      }
    }
    return maxDay;
  }

  /// Get the highest calorie day of the week
  int? get highestCalorieDay {
    if (caloriesByDayOfWeek.isEmpty) return null;
    var maxDay = caloriesByDayOfWeek.keys.first;
    for (final day in caloriesByDayOfWeek.keys) {
      if (caloriesByDayOfWeek[day]! > caloriesByDayOfWeek[maxDay]!) {
        maxDay = day;
      }
    }
    return maxDay;
  }
}

