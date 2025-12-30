/// Models for analytics dashboard AI analysis storage and computed insights.
library;

/// Stored AI analysis result with metadata
class StoredAIAnalysis {
  const StoredAIAnalysis({
    required this.generatedAt,
    required this.dataTimestamp,
    required this.working,
    required this.attention,
    required this.recommendations,
    required this.daysAnalyzed,
  });

  /// When the analysis was generated
  final DateTime generatedAt;

  /// AggregatedUserData.lastUpdated at generation time
  final DateTime dataTimestamp;

  /// What's working well (2-3 points)
  final List<String> working;

  /// What needs attention (2-3 points)
  final List<String> attention;

  /// Actionable recommendations (2-3 points)
  final List<String> recommendations;

  /// Number of days analyzed
  final int daysAnalyzed;

  /// Create empty analysis
  factory StoredAIAnalysis.empty() {
    return StoredAIAnalysis(
      generatedAt: DateTime.now(),
      dataTimestamp: DateTime.now(),
      working: [],
      attention: [],
      recommendations: [],
      daysAnalyzed: 0,
    );
  }

  /// Check if analysis has content
  bool get hasContent =>
      working.isNotEmpty || attention.isNotEmpty || recommendations.isNotEmpty;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt.toIso8601String(),
        'dataTimestamp': dataTimestamp.toIso8601String(),
        'working': working,
        'attention': attention,
        'recommendations': recommendations,
        'daysAnalyzed': daysAnalyzed,
      };

  /// Create from JSON
  factory StoredAIAnalysis.fromJson(Map<String, dynamic> json) {
    return StoredAIAnalysis(
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      dataTimestamp: DateTime.parse(json['dataTimestamp'] as String),
      working: (json['working'] as List<dynamic>).cast<String>(),
      attention: (json['attention'] as List<dynamic>).cast<String>(),
      recommendations: (json['recommendations'] as List<dynamic>).cast<String>(),
      daysAnalyzed: json['daysAnalyzed'] as int,
    );
  }
}

/// Computed trend direction for a metric
enum TrendDirection {
  increasing,
  decreasing,
  stable,
  unknown;

  String get arrow {
    return switch (this) {
      TrendDirection.increasing => '↑',
      TrendDirection.decreasing => '↓',
      TrendDirection.stable => '→',
      TrendDirection.unknown => '',
    };
  }

  String get label {
    return switch (this) {
      TrendDirection.increasing => 'Increasing',
      TrendDirection.decreasing => 'Declining',
      TrendDirection.stable => 'Stable',
      TrendDirection.unknown => 'Not enough data',
    };
  }

  static TrendDirection fromString(String? value) {
    return switch (value) {
      'increasing' => TrendDirection.increasing,
      'decreasing' => TrendDirection.decreasing,
      'stable' => TrendDirection.stable,
      _ => TrendDirection.unknown,
    };
  }
}

/// Summary data for period comparison
class PeriodComparison {
  const PeriodComparison({
    required this.current,
    required this.previous,
    required this.label,
    required this.unit,
  });

  final double current;
  final double previous;
  final String label;
  final String unit;

  /// Calculate percentage change
  double get percentChange {
    if (previous == 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  }

  /// Get trend direction
  TrendDirection get trend {
    final change = percentChange;
    if (change > 10) return TrendDirection.increasing;
    if (change < -10) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  /// Formatted comparison string
  String get formattedChange {
    final change = percentChange.abs();
    final direction = trend == TrendDirection.increasing
        ? '↑'
        : trend == TrendDirection.decreasing
            ? '↓'
            : '→';
    return '$direction ${change.round()}%';
  }
}

/// Metric card data for the new dashboard
class MetricCardData {
  const MetricCardData({
    required this.name,
    required this.iconCodePoint,
    required this.average,
    required this.goal,
    required this.unit,
    required this.trend,
    required this.bestDay,
    required this.bestValue,
    required this.daysHitGoal,
    required this.totalDays,
    required this.color,
  });

  final String name;
  /// Icon code point from Icons class (e.g., Icons.water_drop.codePoint)
  final int iconCodePoint;
  final double average;
  final double goal;
  final String unit;
  final TrendDirection trend;
  final String bestDay;
  final double bestValue;
  final int daysHitGoal;
  final int totalDays;
  final int color;

  /// Calculate goal percentage
  double get goalPercentage => goal > 0 ? (average / goal * 100).clamp(0, 100) : 0;

  /// Get consistency string
  String get consistencyText => '$daysHitGoal/$totalDays days hit goal';
}

/// Nutrition insight data
class NutritionInsightData {
  const NutritionInsightData({
    required this.avgProtein,
    required this.avgCarbs,
    required this.avgFat,
    required this.avgFiber,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatGoal,
    required this.fiberGoal,
    required this.deficiencies,
    required this.topFoods,
    required this.avgMealsPerDay,
    required this.hasFoodData,
  });

  final double avgProtein;
  final double avgCarbs;
  final double avgFat;
  final double avgFiber;
  final double proteinGoal;
  final double carbsGoal;
  final double fatGoal;
  final double fiberGoal;
  final List<NutrientDeficiencyInfo> deficiencies;
  final List<TopFoodEntry> topFoods;
  final double avgMealsPerDay;
  final bool hasFoodData;

  /// Get protein percentage of goal
  double get proteinPercent => proteinGoal > 0 ? (avgProtein / proteinGoal * 100) : 0;
  double get carbsPercent => carbsGoal > 0 ? (avgCarbs / carbsGoal * 100) : 0;
  double get fatPercent => fatGoal > 0 ? (avgFat / fatGoal * 100) : 0;
  double get fiberPercent => fiberGoal > 0 ? (avgFiber / fiberGoal * 100) : 0;
}

/// Nutrient deficiency information
class NutrientDeficiencyInfo {
  const NutrientDeficiencyInfo({
    required this.name,
    required this.avgPercent,
    required this.deficientDays,
    required this.totalDays,
  });

  final String name;
  final double avgPercent;
  final int deficientDays;
  final int totalDays;

  String get description => '$deficientDays/$totalDays days deficient';
}

/// Top food entry
class TopFoodEntry {
  const TopFoodEntry({
    required this.name,
    required this.count,
  });

  final String name;
  final int count;
}

/// Pattern detection data
class PatternInsightData {
  const PatternInsightData({
    required this.mostActiveDays,
    required this.restDays,
    required this.correlations,
    required this.trends,
    required this.hasEnoughData,
  });

  final List<String> mostActiveDays;
  final List<String> restDays;
  final List<CorrelationInsight> correlations;
  final List<TrendInsight> trends;
  final bool hasEnoughData;
}

/// Correlation insight
class CorrelationInsight {
  const CorrelationInsight({
    required this.description,
    required this.isPositive,
  });

  final String description;
  final bool isPositive;
}

/// Trend insight
class TrendInsight {
  const TrendInsight({
    required this.metric,
    required this.direction,
    required this.context,
  });

  final String metric;
  final TrendDirection direction;
  final String? context;
}

