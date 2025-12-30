import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/analytics_repository.dart';
import '../models/aggregated_data.dart';
import '../models/analytics_models.dart';
import '../models/daily_log.dart';
import '../models/user_config.dart';
import '../services/analytics_service.dart';
import 'aggregation_provider.dart';
import 'repository_providers.dart';
import 'user_config_provider.dart';

/// Provider for the analytics repository
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return ref.watch(analyticsRepositoryProviderImpl);
});

/// Provider for the analytics service
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final config = ref.watch(userConfigProvider);
  return AnalyticsService(
    apiKey: config.aiApiKey,
    provider: config.aiProvider,
  );
});

/// State for AI analysis
class AIAnalysisState {
  const AIAnalysisState({
    this.analysis,
    this.isLoading = false,
    this.error,
    this.canRegenerate = false,
  });

  final StoredAIAnalysis? analysis;
  final bool isLoading;
  final String? error;
  final bool canRegenerate;

  AIAnalysisState copyWith({
    StoredAIAnalysis? analysis,
    bool? isLoading,
    String? error,
    bool? canRegenerate,
  }) {
    return AIAnalysisState(
      analysis: analysis ?? this.analysis,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      canRegenerate: canRegenerate ?? this.canRegenerate,
    );
  }
}

/// Notifier for AI analysis state
class AIAnalysisNotifier extends Notifier<AIAnalysisState> {
  @override
  AIAnalysisState build() {
    // Load existing analysis from repository
    final repository = ref.watch(analyticsRepositoryProvider);
    final analysis = repository.getAnalysis();
    
    // Check if regeneration is needed
    final aggregates = ref.watch(aggregatedDataProvider);
    final canRegenerate = aggregates != null && 
        repository.needsRegeneration(aggregates.lastUpdated);
    
    return AIAnalysisState(
      analysis: analysis,
      canRegenerate: canRegenerate,
    );
  }

  /// Generate new AI analysis
  Future<void> generateAnalysis({required int days}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(analyticsServiceProvider);
      final config = ref.read(userConfigProvider);
      final dailyLogRepo = ref.read(dailyLogRepositoryProvider);
      final analyticsRepo = ref.read(analyticsRepositoryProvider);
      
      // Get aggregated data for the period
      final aggregates = ref.read(aggregatedDataForPeriodProvider(days));
      
      // Get recent logs
      final recentLogs = dailyLogRepo.getRecentLogs(days);
      
      // Generate analysis
      final analysis = await service.generateAnalysis(
        aggregates: aggregates,
        recentLogs: recentLogs,
        config: config,
      );
      
      // Save to repository
      await analyticsRepo.saveAnalysis(analysis);
      
      state = AIAnalysisState(
        analysis: analysis,
        isLoading: false,
        canRegenerate: false,
      );
    } catch (e) {
      debugPrint('Error generating AI analysis: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear analysis
  Future<void> clearAnalysis() async {
    final repository = ref.read(analyticsRepositoryProvider);
    await repository.clear();
    state = const AIAnalysisState(canRegenerate: true);
  }
}

/// Provider for AI analysis state
final aiAnalysisProvider = NotifierProvider<AIAnalysisNotifier, AIAnalysisState>(
  AIAnalysisNotifier.new,
);

/// Provider for computed analytics data for a specific period
final analyticsDataProvider = Provider.family<ComputedAnalyticsData, int>((ref, days) {
  final aggregates = ref.watch(aggregatedDataForPeriodProvider(days));
  final config = ref.watch(userConfigProvider);
  final dailyLogRepo = ref.read(dailyLogRepositoryProvider);
  final logs = dailyLogRepo.getRecentLogs(days);
  
  // Compute previous period for comparison
  final previousLogs = dailyLogRepo.getRecentLogs(days * 2).skip(days).take(days).toList();
  
  return ComputedAnalyticsData.compute(
    aggregates: aggregates,
    logs: logs,
    previousLogs: previousLogs,
    config: config,
    days: days,
  );
});

/// Computed analytics data for the dashboard
class ComputedAnalyticsData {
  const ComputedAnalyticsData({
    required this.periodSummary,
    required this.avgCompletion,
    required this.currentStreak,
    required this.daysTracked,
    required this.perfectDays,
    required this.completionTrend,
    required this.streakTrend,
    required this.metricCards,
    required this.nutritionInsights,
    required this.patternInsights,
    required this.streaks,
    required this.hasData,
  });

  final String periodSummary;
  final double avgCompletion;
  final int currentStreak;
  final int daysTracked;
  final int perfectDays;
  final TrendDirection completionTrend;
  final TrendDirection streakTrend;
  final List<MetricCardData> metricCards;
  final NutritionInsightData nutritionInsights;
  final PatternInsightData patternInsights;
  final Map<String, int> streaks; // metric name -> streak days
  final bool hasData;

  factory ComputedAnalyticsData.compute({
    required AggregatedUserData aggregates,
    required List<DailyLog> logs,
    required List<DailyLog> previousLogs,
    required UserConfig config,
    required int days,
  }) {
    if (logs.isEmpty) {
      return ComputedAnalyticsData.empty();
    }

    // Calculate current period stats
    final avgCompletion = _calculateAvgCompletion(logs, config);
    final previousCompletion = previousLogs.isNotEmpty 
        ? _calculateAvgCompletion(previousLogs, config) : null;
    
    // Calculate streaks
    final streaks = _calculateStreaks(logs, config);
    final previousStreaks = previousLogs.isNotEmpty 
        ? _calculateStreaks(previousLogs, config) : null;
    
    // Count perfect days
    final perfectDays = logs.where((log) {
      return _getLogCompletion(log, config) >= 1.0;
    }).length;

    // Determine trends
    final completionTrend = _determineTrend(avgCompletion, previousCompletion);
    final streakTrend = _determineTrend(
      streaks['overall']?.toDouble() ?? 0,
      previousStreaks?['overall']?.toDouble(),
    );

    // Build metric cards
    final metricCards = _buildMetricCards(aggregates, logs, config);

    // Build nutrition insights
    final nutritionInsights = _buildNutritionInsights(aggregates, config);

    // Build pattern insights
    final patternInsights = _buildPatternInsights(aggregates, logs);

    // Calculate period summary
    final focusArea = _findFocusArea(aggregates, config);
    String trendText = '';
    if (previousCompletion != null) {
      if (avgCompletion > previousCompletion + 5) {
        trendText = ', trending ↑ from last period';
      } else if (avgCompletion < previousCompletion - 5) {
        trendText = ', trending ↓ from last period';
      } else {
        trendText = ', stable from last period';
      }
    }
    final periodSummary = 'This period: ${avgCompletion.round()}% avg completion$trendText. Focus area: $focusArea';

    return ComputedAnalyticsData(
      periodSummary: periodSummary,
      avgCompletion: avgCompletion,
      currentStreak: streaks['overall'] ?? 0,
      daysTracked: logs.length,
      perfectDays: perfectDays,
      completionTrend: completionTrend,
      streakTrend: streakTrend,
      metricCards: metricCards,
      nutritionInsights: nutritionInsights,
      patternInsights: patternInsights,
      streaks: streaks,
      hasData: true,
    );
  }

  factory ComputedAnalyticsData.empty() {
    return ComputedAnalyticsData(
      periodSummary: 'Start tracking to see your analytics',
      avgCompletion: 0,
      currentStreak: 0,
      daysTracked: 0,
      perfectDays: 0,
      completionTrend: TrendDirection.unknown,
      streakTrend: TrendDirection.unknown,
      metricCards: [],
      nutritionInsights: NutritionInsightData(
        avgProtein: 0,
        avgCarbs: 0,
        avgFat: 0,
        avgFiber: 0,
        proteinGoal: 50,
        carbsGoal: 275,
        fatGoal: 78,
        fiberGoal: 28,
        deficiencies: [],
        topFoods: [],
        avgMealsPerDay: 0,
        hasFoodData: false,
      ),
      patternInsights: const PatternInsightData(
        mostActiveDays: [],
        restDays: [],
        correlations: [],
        trends: [],
        hasEnoughData: false,
      ),
      streaks: {},
      hasData: false,
    );
  }

  static double _calculateAvgCompletion(List<DailyLog> logs, UserConfig config) {
    if (logs.isEmpty) return 0;
    double total = 0;
    for (final log in logs) {
      total += _getLogCompletion(log, config) * 100;
    }
    return total / logs.length;
  }

  static double _getLogCompletion(DailyLog log, UserConfig config) {
    final water = (log.waterLiters / config.waterGoalLiters).clamp(0.0, 1.0);
    final exercise = (log.exerciseMinutes / config.exerciseGoalMinutes).clamp(0.0, 1.0);
    final sunlight = (log.sunlightMinutes / config.sunlightGoalMinutes).clamp(0.0, 1.0);
    final sleep = (log.sleepHours / config.sleepGoalHours).clamp(0.0, 1.0);
    return (water + exercise + sunlight + sleep) / 4;
  }

  static Map<String, int> _calculateStreaks(List<DailyLog> logs, UserConfig config) {
    int calcStreak(double Function(DailyLog) getValue, double goal) {
      int streak = 0;
      for (final log in logs.reversed) {
        if (getValue(log) >= goal) {
          streak++;
        } else {
          break;
        }
      }
      return streak;
    }

    int calcOverallStreak() {
      int streak = 0;
      for (final log in logs.reversed) {
        if (_getLogCompletion(log, config) >= 0.5) {
          streak++;
        } else {
          break;
        }
      }
      return streak;
    }

    return {
      'water': calcStreak((l) => l.waterLiters, config.waterGoalLiters),
      'exercise': calcStreak((l) => l.exerciseMinutes.toDouble(), config.exerciseGoalMinutes.toDouble()),
      'sunlight': calcStreak((l) => l.sunlightMinutes.toDouble(), config.sunlightGoalMinutes.toDouble()),
      'sleep': calcStreak((l) => l.sleepHours, config.sleepGoalHours),
      'nutrition': calcStreak((l) => l.foodEntries.isNotEmpty ? 1.0 : 0.0, 1.0),
      'social': calcStreak((l) => l.socialMinutes.toDouble(), config.socialGoalMinutes.toDouble()),
      'overall': calcOverallStreak(),
    };
  }

  static TrendDirection _determineTrend(double current, double? previous) {
    if (previous == null) return TrendDirection.unknown;
    final change = previous != 0 ? ((current - previous) / previous) * 100 : 0;
    if (change > 10) return TrendDirection.increasing;
    if (change < -10) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  static String _findFocusArea(AggregatedUserData data, UserConfig config) {
    final sm = data.simpleMetrics;
    final exercise = data.exercise;
    
    final metrics = <String, double>{
      'Water': config.waterGoalLiters > 0 
          ? (sm.avgWaterLiters / config.waterGoalLiters * 100) : 100,
      'Sunlight': config.sunlightGoalMinutes > 0 
          ? (sm.avgSunlightMinutes / config.sunlightGoalMinutes * 100) : 100,
      'Sleep': config.sleepGoalHours > 0 
          ? (sm.avgSleepHours / config.sleepGoalHours * 100) : 100,
      'Exercise': config.exerciseGoalMinutes > 0 
          ? (exercise.avgMinutesPerDay / config.exerciseGoalMinutes * 100) : 100,
    };
    
    final lowestEntry = metrics.entries.reduce((a, b) => a.value < b.value ? a : b);
    return '${lowestEntry.key} (${lowestEntry.value.round()}% of goal)';
  }

  static List<MetricCardData> _buildMetricCards(
    AggregatedUserData aggregates,
    List<DailyLog> logs,
    UserConfig config,
  ) {
    final sm = aggregates.simpleMetrics;
    final exercise = aggregates.exercise;
    final nutrition = aggregates.nutrition;
    final social = aggregates.social;
    final patterns = aggregates.patterns;

    final cards = <MetricCardData>[];

    // Water
    final waterBest = _findBestDay(logs, (l) => l.waterLiters);
    cards.add(MetricCardData(
      name: 'Water',
      iconCodePoint: Icons.water_drop.codePoint,
      average: sm.avgWaterLiters,
      goal: config.waterGoalLiters,
      unit: 'L',
      trend: TrendDirection.fromString(patterns.sleepTrend), // Use sleep trend as proxy
      bestDay: waterBest.$1,
      bestValue: waterBest.$2,
      daysHitGoal: logs.where((l) => l.waterLiters >= config.waterGoalLiters).length,
      totalDays: logs.length,
      color: 0xFF29B6F6,
    ));

    // Sunlight
    final sunlightBest = _findBestDay(logs, (l) => l.sunlightMinutes.toDouble());
    cards.add(MetricCardData(
      name: 'Sunlight',
      iconCodePoint: Icons.wb_sunny.codePoint,
      average: sm.avgSunlightMinutes,
      goal: config.sunlightGoalMinutes.toDouble(),
      unit: 'min',
      trend: TrendDirection.stable,
      bestDay: sunlightBest.$1,
      bestValue: sunlightBest.$2,
      daysHitGoal: logs.where((l) => l.sunlightMinutes >= config.sunlightGoalMinutes).length,
      totalDays: logs.length,
      color: 0xFFFFB300,
    ));

    // Sleep
    final sleepBest = _findBestDay(logs, (l) => l.sleepHours);
    cards.add(MetricCardData(
      name: 'Sleep',
      iconCodePoint: Icons.bedtime.codePoint,
      average: sm.avgSleepHours,
      goal: config.sleepGoalHours,
      unit: 'hrs',
      trend: TrendDirection.fromString(patterns.sleepTrend),
      bestDay: sleepBest.$1,
      bestValue: sleepBest.$2,
      daysHitGoal: logs.where((l) => l.sleepHours >= config.sleepGoalHours * 0.9).length,
      totalDays: logs.length,
      color: 0xFF7E57C2,
    ));

    // Exercise
    final exerciseBest = _findBestDay(logs, (l) => l.exerciseMinutes.toDouble());
    cards.add(MetricCardData(
      name: 'Exercise',
      iconCodePoint: Icons.fitness_center.codePoint,
      average: exercise.avgMinutesPerDay,
      goal: config.exerciseGoalMinutes.toDouble(),
      unit: 'min',
      trend: TrendDirection.fromString(patterns.exerciseTrend),
      bestDay: exerciseBest.$1,
      bestValue: exerciseBest.$2,
      daysHitGoal: logs.where((l) => l.exerciseMinutes >= config.exerciseGoalMinutes).length,
      totalDays: logs.length,
      color: 0xFFEF5350,
    ));

    // Nutrition (if has data)
    if (nutrition.hasData) {
      final nutritionBest = _findBestDay(logs, (l) => l.foodEntries.length.toDouble());
      cards.add(MetricCardData(
        name: 'Nutrition',
        iconCodePoint: Icons.restaurant.codePoint,
        average: nutrition.avgCalories,
        goal: config.calorieGoal.toDouble(),
        unit: 'kcal',
        trend: TrendDirection.fromString(patterns.nutritionTrend),
        bestDay: nutritionBest.$1,
        bestValue: nutritionBest.$2,
        daysHitGoal: logs.where((l) {
          final ratio = l.nutritionSummary.calories / config.calorieGoal;
          return ratio >= 0.9 && ratio <= 1.1;
        }).length,
        totalDays: logs.length,
        color: 0xFFFF6B35,
      ));
    }

    // Social (if has data)
    if (social.hasData) {
      final socialBest = _findBestDay(logs, (l) => l.socialMinutes.toDouble());
      cards.add(MetricCardData(
        name: 'Social',
        iconCodePoint: Icons.people.codePoint,
        average: social.avgMinutesPerDay,
        goal: config.socialGoalMinutes.toDouble(),
        unit: 'min',
        trend: TrendDirection.stable,
        bestDay: socialBest.$1,
        bestValue: socialBest.$2,
        daysHitGoal: logs.where((l) => l.socialMinutes >= config.socialGoalMinutes).length,
        totalDays: logs.length,
        color: 0xFF26A69A,
      ));
    }

    return cards;
  }

  static (String, double) _findBestDay(List<DailyLog> logs, double Function(DailyLog) getValue) {
    if (logs.isEmpty) return ('N/A', 0);
    
    DailyLog? bestLog;
    double bestValue = -1;
    
    for (final log in logs) {
      final value = getValue(log);
      if (value > bestValue) {
        bestValue = value;
        bestLog = log;
      }
    }
    
    if (bestLog == null) return ('N/A', 0);
    
    final date = DateTime.parse(bestLog.date);
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return (days[date.weekday], bestValue);
  }

  static NutritionInsightData _buildNutritionInsights(
    AggregatedUserData aggregates,
    UserConfig config,
  ) {
    final n = aggregates.nutrition;
    final rec = NutritionSummary.recommendedDaily;

    // Build deficiencies
    final deficiencies = <NutrientDeficiencyInfo>[];
    for (final def in n.consistentDeficiencies.take(5)) {
      final avgPercent = switch (def) {
        'Protein' => n.avgProtein / rec.protein * 100,
        'Fiber' => n.avgFiber / rec.fiber * 100,
        'Vitamin C' => (n.avgMicronutrients['vitaminC'] ?? 0) / rec.vitaminC * 100,
        'Vitamin D' => (n.avgMicronutrients['vitaminD'] ?? 0) / rec.vitaminD * 100,
        'Calcium' => (n.avgMicronutrients['calcium'] ?? 0) / rec.calcium * 100,
        'Iron' => (n.avgMicronutrients['iron'] ?? 0) / rec.iron * 100,
        'Potassium' => (n.avgMicronutrients['potassium'] ?? 0) / rec.potassium * 100,
        _ => 50.0,
      };
      deficiencies.add(NutrientDeficiencyInfo(
        name: def,
        avgPercent: avgPercent,
        deficientDays: (n.daysWithData * 0.5).round(), // Approximation
        totalDays: n.daysWithData,
      ));
    }

    // Build top foods
    final topFoods = n.topFoods.take(5).map((name) {
      return TopFoodEntry(
        name: name,
        count: n.commonFoods[name] ?? 0,
      );
    }).toList();

    return NutritionInsightData(
      avgProtein: n.avgProtein,
      avgCarbs: n.avgCarbs,
      avgFat: n.avgFat,
      avgFiber: n.avgFiber,
      proteinGoal: config.proteinGoalGrams,
      carbsGoal: rec.carbs,
      fatGoal: rec.fat,
      fiberGoal: rec.fiber,
      deficiencies: deficiencies,
      topFoods: topFoods,
      avgMealsPerDay: n.avgMealsPerDay,
      hasFoodData: n.hasData,
    );
  }

  static PatternInsightData _buildPatternInsights(
    AggregatedUserData aggregates,
    List<DailyLog> logs,
  ) {
    final patterns = aggregates.patterns;
    
    if (!patterns.hasPatterns || logs.length < 7) {
      return const PatternInsightData(
        mostActiveDays: [],
        restDays: [],
        correlations: [],
        trends: [],
        hasEnoughData: false,
      );
    }

    const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Find most active days (above average exercise)
    final avgExercise = patterns.exerciseByDayOfWeek.values.isNotEmpty
        ? patterns.exerciseByDayOfWeek.values.reduce((a, b) => a + b) / patterns.exerciseByDayOfWeek.length
        : 0;
    final mostActiveDays = patterns.exerciseByDayOfWeek.entries
        .where((e) => e.value > avgExercise * 1.2)
        .map((e) => dayNames[e.key])
        .toList();

    // Find rest days (below average)
    final restDays = patterns.exerciseByDayOfWeek.entries
        .where((e) => e.value < avgExercise * 0.5)
        .map((e) => dayNames[e.key])
        .toList();

    // Build correlations
    final correlations = <CorrelationInsight>[];
    if (patterns.sleepExerciseCorrelation != null && patterns.sleepExerciseCorrelation!.abs() > 0.3) {
      final isPositive = patterns.sleepExerciseCorrelation! > 0;
      correlations.add(CorrelationInsight(
        description: isPositive
            ? 'You sleep better on exercise days'
            : 'Exercise might be affecting your sleep',
        isPositive: isPositive,
      ));
    }
    if (patterns.exerciseCaloriesCorrelation != null && patterns.exerciseCaloriesCorrelation!.abs() > 0.3) {
      final isPositive = patterns.exerciseCaloriesCorrelation! > 0;
      correlations.add(CorrelationInsight(
        description: isPositive
            ? 'You eat more on exercise days'
            : 'You tend to eat less on exercise days',
        isPositive: true, // Both can be fine
      ));
    }

    // Build trends
    final trends = <TrendInsight>[];
    if (patterns.exerciseTrend != null) {
      trends.add(TrendInsight(
        metric: 'Exercise',
        direction: TrendDirection.fromString(patterns.exerciseTrend),
        context: null,
      ));
    }
    if (patterns.sleepTrend != null) {
      trends.add(TrendInsight(
        metric: 'Sleep',
        direction: TrendDirection.fromString(patterns.sleepTrend),
        context: null,
      ));
    }
    if (patterns.nutritionTrend != null) {
      trends.add(TrendInsight(
        metric: 'Nutrition',
        direction: TrendDirection.fromString(patterns.nutritionTrend),
        context: null,
      ));
    }

    return PatternInsightData(
      mostActiveDays: mostActiveDays,
      restDays: restDays,
      correlations: correlations,
      trends: trends,
      hasEnoughData: true,
    );
  }
}

