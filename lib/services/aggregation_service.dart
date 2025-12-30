import '../data/repositories/daily_log_repository.dart';
import '../data/repositories/exercise_repository.dart';
import '../models/aggregated_data.dart';
import '../models/daily_log.dart';
import '../models/exercise_models.dart';
import '../models/social_models.dart';
import '../models/user_config.dart';

/// Service for computing aggregated data from historical logs.
/// Provides context for AI-powered features.
class AggregationService {
  AggregationService({
    required DailyLogRepository dailyLogRepository,
    required ExerciseRepository exerciseRepository,
  })  : _dailyLogRepository = dailyLogRepository,
        _exerciseRepository = exerciseRepository;

  final DailyLogRepository _dailyLogRepository;
  final ExerciseRepository _exerciseRepository;

  /// Compute aggregated data for the specified number of days
  AggregatedUserData computeAggregates({
    required int days,
    required UserConfig userConfig,
    List<SocialActivity>? socialActivities,
  }) {
    final logs = _dailyLogRepository.getRecentLogs(days);
    final exerciseActivities = _exerciseRepository.getAllActivities();

    // Filter exercise activities to the period
    final now = DateTime.now();
    final periodStart = now.subtract(Duration(days: days));
    final periodActivities = exerciseActivities.where((a) => a.timestamp.isAfter(periodStart)).toList();

    return AggregatedUserData(
      lastUpdated: DateTime.now(),
      daysAnalyzed: days,
      nutrition: _computeNutritionAggregates(logs, userConfig),
      exercise: _computeExerciseAggregates(logs, periodActivities, userConfig),
      social: _computeSocialAggregates(logs, socialActivities, userConfig),
      simpleMetrics: _computeSimpleMetricsAggregates(logs, userConfig),
      patterns: _computePatterns(logs),
    );
  }

  /// Compute nutrition aggregates from logs
  NutritionAggregates _computeNutritionAggregates(
    List<DailyLog> logs,
    UserConfig config,
  ) {
    // Filter to logs with food entries
    final logsWithFood = logs.where((l) => l.foodEntries.isNotEmpty).toList();
    final daysWithData = logsWithFood.length;

    if (daysWithData == 0) {
      return NutritionAggregates.empty();
    }

    // Calculate totals
    double totalCalories = 0, totalProtein = 0, totalCarbs = 0, totalFat = 0, totalFiber = 0;
    int totalMeals = 0;

    // Micronutrient tracking
    final microTotals = <String, double>{
      'vitaminC': 0,
      'vitaminD': 0,
      'vitaminA': 0,
      'vitaminB12': 0,
      'calcium': 0,
      'iron': 0,
      'potassium': 0,
      'magnesium': 0,
      'zinc': 0,
    };

    // Food frequency tracking
    final foodFrequency = <String, int>{};

    // Goal hit tracking
    int calorieGoalHits = 0;
    int proteinGoalHits = 0;

    for (final log in logsWithFood) {
      final nutrition = log.nutritionSummary;

      totalCalories += nutrition.calories;
      totalProtein += nutrition.protein;
      totalCarbs += nutrition.carbs;
      totalFat += nutrition.fat;
      totalFiber += nutrition.fiber;

      // Micronutrients
      microTotals['vitaminC'] = (microTotals['vitaminC'] ?? 0) + nutrition.vitaminC;
      microTotals['vitaminD'] = (microTotals['vitaminD'] ?? 0) + nutrition.vitaminD;
      microTotals['vitaminA'] = (microTotals['vitaminA'] ?? 0) + nutrition.vitaminA;
      microTotals['vitaminB12'] = (microTotals['vitaminB12'] ?? 0) + nutrition.vitaminB12;
      microTotals['calcium'] = (microTotals['calcium'] ?? 0) + nutrition.calcium;
      microTotals['iron'] = (microTotals['iron'] ?? 0) + nutrition.iron;
      microTotals['potassium'] = (microTotals['potassium'] ?? 0) + nutrition.potassium;
      microTotals['magnesium'] = (microTotals['magnesium'] ?? 0) + nutrition.magnesium;
      microTotals['zinc'] = (microTotals['zinc'] ?? 0) + nutrition.zinc;

      // Count meals and track food names
      totalMeals += log.foodEntries.length;
      for (final entry in log.foodEntries) {
        final name = _normalizeFoodName(entry.name);
        foodFrequency[name] = (foodFrequency[name] ?? 0) + 1;
      }

      // Check goal hits (within 10% tolerance)
      final calorieRatio = nutrition.calories / config.calorieGoal;
      if (calorieRatio >= 0.9 && calorieRatio <= 1.1) {
        calorieGoalHits++;
      }

      final proteinRatio = nutrition.protein / config.proteinGoalGrams;
      if (proteinRatio >= 0.9) {
        proteinGoalHits++;
      }
    }

    // Calculate averages
    final avgCalories = totalCalories / daysWithData;
    final avgProtein = totalProtein / daysWithData;
    final avgCarbs = totalCarbs / daysWithData;
    final avgFat = totalFat / daysWithData;
    final avgFiber = totalFiber / daysWithData;
    final avgMealsPerDay = totalMeals / daysWithData;

    // Calculate average micronutrients
    final avgMicronutrients = <String, double>{};
    for (final key in microTotals.keys) {
      avgMicronutrients[key] = microTotals[key]! / daysWithData;
    }

    // Identify consistent deficiencies/excesses
    final consistentDeficiencies = _identifyConsistentDeficiencies(logsWithFood);
    final consistentExcesses = _identifyConsistentExcesses(logsWithFood);

    // Get top foods
    final sortedFoods = foodFrequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topFoods = sortedFoods.take(10).map((e) => e.key).toList();

    // Infer dietary preferences
    final inferredPreferences = _inferDietaryPreferences(avgProtein, avgCarbs, avgFat, avgFiber, topFoods);

    return NutritionAggregates(
      avgCalories: avgCalories,
      avgProtein: avgProtein,
      avgCarbs: avgCarbs,
      avgFat: avgFat,
      avgFiber: avgFiber,
      avgMicronutrients: avgMicronutrients,
      consistentDeficiencies: consistentDeficiencies,
      consistentExcesses: consistentExcesses,
      totalMealsLogged: totalMeals,
      avgMealsPerDay: avgMealsPerDay,
      commonFoods: foodFrequency,
      topFoods: topFoods,
      calorieGoalHitRate: daysWithData > 0 ? calorieGoalHits / daysWithData : 0,
      proteinGoalHitRate: daysWithData > 0 ? proteinGoalHits / daysWithData : 0,
      inferredPreferences: inferredPreferences,
      daysWithData: daysWithData,
    );
  }

  /// Identify nutrients consistently below 70% of recommended
  List<String> _identifyConsistentDeficiencies(List<DailyLog> logs) {
    if (logs.isEmpty) return [];

    final rec = NutritionSummary.recommendedDaily;
    final deficiencyCounts = <String, int>{};
    final threshold = 0.7;

    for (final log in logs) {
      final ns = log.nutritionSummary;

      if (ns.protein < rec.protein * threshold) deficiencyCounts['Protein'] = (deficiencyCounts['Protein'] ?? 0) + 1;
      if (ns.fiber < rec.fiber * threshold) deficiencyCounts['Fiber'] = (deficiencyCounts['Fiber'] ?? 0) + 1;
      if (ns.vitaminC < rec.vitaminC * threshold) deficiencyCounts['Vitamin C'] = (deficiencyCounts['Vitamin C'] ?? 0) + 1;
      if (ns.vitaminD < rec.vitaminD * threshold) deficiencyCounts['Vitamin D'] = (deficiencyCounts['Vitamin D'] ?? 0) + 1;
      if (ns.calcium < rec.calcium * threshold) deficiencyCounts['Calcium'] = (deficiencyCounts['Calcium'] ?? 0) + 1;
      if (ns.iron < rec.iron * threshold) deficiencyCounts['Iron'] = (deficiencyCounts['Iron'] ?? 0) + 1;
      if (ns.potassium < rec.potassium * threshold) deficiencyCounts['Potassium'] = (deficiencyCounts['Potassium'] ?? 0) + 1;
      if (ns.magnesium < rec.magnesium * threshold) deficiencyCounts['Magnesium'] = (deficiencyCounts['Magnesium'] ?? 0) + 1;
      if (ns.vitaminB12 < rec.vitaminB12 * threshold) deficiencyCounts['Vitamin B12'] = (deficiencyCounts['Vitamin B12'] ?? 0) + 1;
    }

    // Return nutrients deficient on 50%+ of days
    final consistentThreshold = logs.length * 0.5;
    return deficiencyCounts.entries
        .where((e) => e.value >= consistentThreshold)
        .map((e) => e.key)
        .toList();
  }

  /// Identify nutrients consistently above 150% of recommended
  List<String> _identifyConsistentExcesses(List<DailyLog> logs) {
    if (logs.isEmpty) return [];

    final rec = NutritionSummary.recommendedDaily;
    final excessCounts = <String, int>{};
    final threshold = 1.5;

    for (final log in logs) {
      final ns = log.nutritionSummary;

      if (ns.calories > rec.calories * threshold) excessCounts['Calories'] = (excessCounts['Calories'] ?? 0) + 1;
      if (ns.sugar > rec.sugar * threshold) excessCounts['Sugar'] = (excessCounts['Sugar'] ?? 0) + 1;
      if (ns.sodium > rec.sodium * threshold) excessCounts['Sodium'] = (excessCounts['Sodium'] ?? 0) + 1;
      if (ns.fat > rec.fat * threshold) excessCounts['Fat'] = (excessCounts['Fat'] ?? 0) + 1;
    }

    // Return nutrients in excess on 50%+ of days
    final consistentThreshold = logs.length * 0.5;
    return excessCounts.entries
        .where((e) => e.value >= consistentThreshold)
        .map((e) => e.key)
        .toList();
  }

  /// Infer dietary preferences from eating patterns
  List<String> _inferDietaryPreferences(
    double avgProtein,
    double avgCarbs,
    double avgFat,
    double avgFiber,
    List<String> topFoods,
  ) {
    final preferences = <String>[];
    final rec = NutritionSummary.recommendedDaily;

    // Macro-based inferences
    if (avgProtein > rec.protein * 1.2) {
      preferences.add('high protein');
    } else if (avgProtein < rec.protein * 0.7) {
      preferences.add('low protein');
    }

    if (avgCarbs < rec.carbs * 0.5) {
      preferences.add('low carb');
    } else if (avgCarbs > rec.carbs * 1.2) {
      preferences.add('high carb');
    }

    if (avgFiber > rec.fiber * 1.2) {
      preferences.add('high fiber');
    }

    if (avgFat > rec.fat * 1.2) {
      preferences.add('higher fat');
    } else if (avgFat < rec.fat * 0.6) {
      preferences.add('low fat');
    }

    // Food-based inferences
    final topFoodsLower = topFoods.map((f) => f.toLowerCase()).toList();
    final meatKeywords = ['chicken', 'beef', 'steak', 'pork', 'meat', 'bacon', 'sausage'];
    final vegKeywords = ['salad', 'vegetable', 'veggie', 'tofu', 'bean', 'lentil'];
    final dairyKeywords = ['milk', 'cheese', 'yogurt', 'dairy'];

    final hasMeat = topFoodsLower.any((f) => meatKeywords.any((k) => f.contains(k)));
    final hasVeg = topFoodsLower.any((f) => vegKeywords.any((k) => f.contains(k)));
    final hasDairy = topFoodsLower.any((f) => dairyKeywords.any((k) => f.contains(k)));

    if (!hasMeat && hasVeg) {
      preferences.add('vegetarian-leaning');
    }
    if (!hasDairy) {
      preferences.add('possibly dairy-free');
    }

    return preferences;
  }

  /// Normalize food name for frequency counting
  String _normalizeFoodName(String name) {
    // Lowercase and remove quantities/weights
    var normalized = name.toLowerCase().trim();
    // Remove leading numbers and units
    normalized = normalized.replaceFirst(RegExp(r'^\d+\s*(g|kg|ml|oz|cup|tbsp|tsp)?\s*'), '');
    // Capitalize first letter
    if (normalized.isNotEmpty) {
      normalized = normalized[0].toUpperCase() + normalized.substring(1);
    }
    return normalized;
  }

  /// Compute exercise aggregates
  ExerciseAggregates _computeExerciseAggregates(
    List<DailyLog> logs,
    List<ExerciseActivity> activities,
    UserConfig config,
  ) {
    final daysWithExercise = logs.where((l) => l.exerciseMinutes > 0).toList();
    final daysWithData = daysWithExercise.length;

    if (daysWithData == 0 && activities.isEmpty) {
      return ExerciseAggregates.empty();
    }

    // Calculate totals from logs
    int totalMinutes = 0;
    int goalHits = 0;

    // Day of week tracking (1=Mon, 7=Sun)
    final dayOfWeekMinutes = <int, List<int>>{};

    for (final log in logs) {
      totalMinutes += log.exerciseMinutes;

      if (log.exerciseMinutes >= config.exerciseGoalMinutes) {
        goalHits++;
      }

      // Track by day of week
      final date = DateTime.parse(log.date);
      final dayOfWeek = date.weekday; // 1=Mon, 7=Sun
      dayOfWeekMinutes.putIfAbsent(dayOfWeek, () => []);
      dayOfWeekMinutes[dayOfWeek]!.add(log.exerciseMinutes);
    }

    // Calculate streaks
    final streakData = _calculateStreaks(logs, config.exerciseGoalMinutes);

    // Determine active days of week (days with above-average activity)
    final avgByDay = <int, double>{};
    for (final entry in dayOfWeekMinutes.entries) {
      if (entry.value.isNotEmpty) {
        avgByDay[entry.key] = entry.value.reduce((a, b) => a + b) / entry.value.length;
      }
    }
    final overallAvg = daysWithData > 0 ? totalMinutes / logs.length : 0;
    final activeDays = avgByDay.entries
        .where((e) => e.value > overallAvg)
        .map((e) => e.key)
        .toList()
      ..sort();

    // Categorize workout types from activity names
    final workoutTypeFrequency = _categorizeWorkoutTypes(activities);
    final sortedTypes = workoutTypeFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final preferredTypes = sortedTypes.take(3).map((e) => e.key).toList();

    return ExerciseAggregates(
      totalWorkoutsLogged: activities.length,
      totalMinutesExercised: totalMinutes,
      avgMinutesPerDay: logs.isNotEmpty ? totalMinutes / logs.length : 0,
      avgMinutesPerWorkout: activities.isNotEmpty
          ? activities.fold<int>(0, (sum, a) => sum + a.durationMinutes) / activities.length
          : 0,
      exerciseGoalHitRate: logs.isNotEmpty ? goalHits / logs.length : 0,
      currentStreak: streakData.currentStreak,
      longestStreak: streakData.longestStreak,
      activeDaysOfWeek: activeDays,
      workoutTypeFrequency: workoutTypeFrequency,
      preferredWorkoutTypes: preferredTypes,
      fitnessGoal: config.fitnessGoal?.displayName,
      fitnessLevel: config.fitnessLevel?.displayName,
      preferredDuration: config.preferredWorkoutDuration ?? config.exerciseGoalMinutes,
      daysWithData: daysWithData,
    );
  }

  /// Calculate exercise streaks
  ({int currentStreak, int longestStreak}) _calculateStreaks(List<DailyLog> logs, int goalMinutes) {
    if (logs.isEmpty) return (currentStreak: 0, longestStreak: 0);

    // Sort logs by date
    final sortedLogs = logs.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastDate;

    for (final log in sortedLogs) {
      final date = DateTime.parse(log.date);
      final hitGoal = log.exerciseMinutes >= goalMinutes;

      if (hitGoal) {
        if (lastDate == null || date.difference(lastDate).inDays == 1) {
          tempStreak++;
        } else if (date.difference(lastDate).inDays > 1) {
          tempStreak = 1;
        }
        longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
      } else {
        tempStreak = 0;
      }
      lastDate = date;
    }

    // Current streak is tempStreak if the last log is today or yesterday
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    if (sortedLogs.isNotEmpty) {
      final lastLogDate = sortedLogs.last.date;
      if (lastLogDate == todayStr || lastLogDate == yesterdayStr) {
        currentStreak = tempStreak;
      }
    }

    return (currentStreak: currentStreak, longestStreak: longestStreak);
  }

  /// Categorize workout types from activity names
  Map<String, int> _categorizeWorkoutTypes(List<ExerciseActivity> activities) {
    final categories = <String, int>{};

    for (final activity in activities) {
      final category = _inferWorkoutCategory(activity.name);
      categories[category] = (categories[category] ?? 0) + 1;
    }

    return categories;
  }

  /// Infer workout category from activity name
  String _inferWorkoutCategory(String name) {
    final lower = name.toLowerCase();

    if (lower.contains('strength') ||
        lower.contains('weight') ||
        lower.contains('lift') ||
        lower.contains('muscle') ||
        lower.contains('resistance')) {
      return 'Strength';
    }
    if (lower.contains('cardio') ||
        lower.contains('run') ||
        lower.contains('jog') ||
        lower.contains('bike') ||
        lower.contains('cycling') ||
        lower.contains('hiit')) {
      return 'Cardio';
    }
    if (lower.contains('yoga') || lower.contains('stretch') || lower.contains('flexibility')) {
      return 'Yoga/Flexibility';
    }
    if (lower.contains('walk')) {
      return 'Walking';
    }
    if (lower.contains('swim')) {
      return 'Swimming';
    }
    if (lower.contains('sport') || lower.contains('game') || lower.contains('tennis') || lower.contains('basketball')) {
      return 'Sports';
    }
    if (lower.contains('core') || lower.contains('ab')) {
      return 'Core';
    }
    if (lower.contains('full body') || lower.contains('circuit')) {
      return 'Full Body';
    }

    return 'General';
  }

  /// Compute social aggregates
  SocialAggregates _computeSocialAggregates(
    List<DailyLog> logs,
    List<SocialActivity>? activities,
    UserConfig config,
  ) {
    final daysWithSocial = logs.where((l) => l.socialMinutes > 0).toList();
    final daysWithData = daysWithSocial.length;

    // Calculate totals from logs
    int totalMinutes = 0;
    int goalHits = 0;

    for (final log in logs) {
      totalMinutes += log.socialMinutes;
      if (log.socialMinutes >= config.socialGoalMinutes) {
        goalHits++;
      }
    }

    // Calculate category frequency from activities (if available)
    final categoryFrequency = <String, int>{};
    final visitedTypes = <String>[];

    if (activities != null) {
      for (final activity in activities) {
        final categoryName = activity.category.name;
        categoryFrequency[categoryName] = (categoryFrequency[categoryName] ?? 0) + 1;
        if (!visitedTypes.contains(categoryName)) {
          visitedTypes.add(categoryName);
        }
      }
    }

    // Get preferred categories
    final sortedCategories = categoryFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final preferredCategories = sortedCategories.take(5).map((e) => e.key).toList();

    return SocialAggregates(
      totalActivitiesLogged: activities?.length ?? 0,
      totalMinutesSocial: totalMinutes,
      avgMinutesPerDay: logs.isNotEmpty ? totalMinutes / logs.length : 0,
      socialGoalHitRate: logs.isNotEmpty ? goalHits / logs.length : 0,
      categoryFrequency: categoryFrequency,
      preferredCategories: preferredCategories,
      currentLocation: config.formattedLocation,
      visitedPlaceTypes: visitedTypes,
      daysWithData: daysWithData,
    );
  }

  /// Compute simple metrics aggregates
  SimpleMetricsAggregates _computeSimpleMetricsAggregates(
    List<DailyLog> logs,
    UserConfig config,
  ) {
    if (logs.isEmpty) {
      return SimpleMetricsAggregates.empty();
    }

    // Calculate totals and extremes
    double totalWater = 0, totalSunlight = 0, totalSleep = 0;
    int waterGoalHits = 0, sunlightGoalHits = 0, sleepGoalHits = 0;
    double minSleep = double.infinity, maxSleep = 0;
    int daysWithData = 0;

    for (final log in logs) {
      // Check if this day has any data
      final hasData = log.waterLiters > 0 || log.sunlightMinutes > 0 || log.sleepHours > 0;
      if (hasData) daysWithData++;

      totalWater += log.waterLiters;
      totalSunlight += log.sunlightMinutes;
      totalSleep += log.sleepHours;

      if (log.waterLiters >= config.waterGoalLiters) waterGoalHits++;
      if (log.sunlightMinutes >= config.sunlightGoalMinutes) sunlightGoalHits++;
      if (log.sleepHours >= config.sleepGoalHours * 0.9) sleepGoalHits++; // 90% tolerance for sleep

      if (log.sleepHours > 0) {
        if (log.sleepHours < minSleep) minSleep = log.sleepHours;
        if (log.sleepHours > maxSleep) maxSleep = log.sleepHours;
      }
    }

    final count = logs.length;

    return SimpleMetricsAggregates(
      avgWaterLiters: count > 0 ? totalWater / count : 0,
      waterGoalHitRate: count > 0 ? waterGoalHits / count : 0,
      avgSunlightMinutes: count > 0 ? totalSunlight / count : 0,
      sunlightGoalHitRate: count > 0 ? sunlightGoalHits / count : 0,
      avgSleepHours: count > 0 ? totalSleep / count : 0,
      sleepGoalHitRate: count > 0 ? sleepGoalHits / count : 0,
      minSleep: minSleep == double.infinity ? 0 : minSleep,
      maxSleep: maxSleep,
      daysWithData: daysWithData,
    );
  }

  /// Compute patterns and correlations
  PatternData _computePatterns(List<DailyLog> logs) {
    if (logs.length < 3) {
      return PatternData.empty();
    }

    // Day-of-week averages
    final exerciseByDay = <int, List<double>>{};
    final caloriesByDay = <int, List<double>>{};
    final sleepByDay = <int, List<double>>{};

    for (final log in logs) {
      final date = DateTime.parse(log.date);
      final dayOfWeek = date.weekday;

      exerciseByDay.putIfAbsent(dayOfWeek, () => []);
      caloriesByDay.putIfAbsent(dayOfWeek, () => []);
      sleepByDay.putIfAbsent(dayOfWeek, () => []);

      exerciseByDay[dayOfWeek]!.add(log.exerciseMinutes.toDouble());
      caloriesByDay[dayOfWeek]!.add(log.nutritionSummary.calories);
      sleepByDay[dayOfWeek]!.add(log.sleepHours);
    }

    // Calculate averages
    final exerciseAvgByDay = <int, double>{};
    final caloriesAvgByDay = <int, double>{};
    final sleepAvgByDay = <int, double>{};

    for (final entry in exerciseByDay.entries) {
      if (entry.value.isNotEmpty) {
        exerciseAvgByDay[entry.key] = entry.value.reduce((a, b) => a + b) / entry.value.length;
      }
    }
    for (final entry in caloriesByDay.entries) {
      if (entry.value.isNotEmpty) {
        caloriesAvgByDay[entry.key] = entry.value.reduce((a, b) => a + b) / entry.value.length;
      }
    }
    for (final entry in sleepByDay.entries) {
      if (entry.value.isNotEmpty) {
        sleepAvgByDay[entry.key] = entry.value.reduce((a, b) => a + b) / entry.value.length;
      }
    }

    // Calculate trends (compare first half to second half)
    final exerciseTrend = _calculateTrend(logs.map((l) => l.exerciseMinutes.toDouble()).toList());
    final nutritionTrend = _calculateTrend(logs.map((l) => l.nutritionSummary.calories).toList());
    final sleepTrend = _calculateTrend(logs.map((l) => l.sleepHours).toList());

    // Simple correlations (only if we have enough data)
    double? sleepExerciseCorr;
    double? exerciseCaloriesCorr;

    if (logs.length >= 7) {
      sleepExerciseCorr = _calculateCorrelation(
        logs.map((l) => l.sleepHours).toList(),
        logs.map((l) => l.exerciseMinutes.toDouble()).toList(),
      );
      exerciseCaloriesCorr = _calculateCorrelation(
        logs.map((l) => l.exerciseMinutes.toDouble()).toList(),
        logs.map((l) => l.nutritionSummary.calories).toList(),
      );
    }

    return PatternData(
      exerciseByDayOfWeek: exerciseAvgByDay,
      caloriesByDayOfWeek: caloriesAvgByDay,
      sleepByDayOfWeek: sleepAvgByDay,
      sleepExerciseCorrelation: sleepExerciseCorr,
      exerciseCaloriesCorrelation: exerciseCaloriesCorr,
      exerciseTrend: exerciseTrend,
      nutritionTrend: nutritionTrend,
      sleepTrend: sleepTrend,
    );
  }

  /// Calculate trend by comparing first half to second half
  String? _calculateTrend(List<double> values) {
    if (values.length < 4) return null;

    final midpoint = values.length ~/ 2;
    final firstHalf = values.sublist(0, midpoint);
    final secondHalf = values.sublist(midpoint);

    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    final percentChange = firstAvg > 0 ? ((secondAvg - firstAvg) / firstAvg) * 100 : 0;

    if (percentChange > 10) return 'increasing';
    if (percentChange < -10) return 'decreasing';
    return 'stable';
  }

  /// Calculate Pearson correlation coefficient
  double? _calculateCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 3) return null;

    final n = x.length;
    final meanX = x.reduce((a, b) => a + b) / n;
    final meanY = y.reduce((a, b) => a + b) / n;

    double numerator = 0;
    double sumSqX = 0;
    double sumSqY = 0;

    for (int i = 0; i < n; i++) {
      final dx = x[i] - meanX;
      final dy = y[i] - meanY;
      numerator += dx * dy;
      sumSqX += dx * dx;
      sumSqY += dy * dy;
    }

    final denominator = (sumSqX * sumSqY);
    if (denominator <= 0) return null;

    final correlation = numerator / (denominator.abs() > 0 ? denominator.abs() : 1);
    return correlation.isNaN ? null : correlation.clamp(-1.0, 1.0);
  }
}


