import 'package:flutter/material.dart';

import '../../models/models.dart';
import 'draggable_progress_card.dart';
import 'nutrition_score_card.dart';

/// Configuration for a single tracking metric.
class TrackingMetric {
  const TrackingMetric({
    required this.title,
    required this.icon,
    required this.color,
    required this.unit,
    required this.step,
    required this.getValue,
    required this.getGoal,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String unit;
  final double step;
  final double Function(DailyLog log) getValue;
  final double Function(UserConfig config) getGoal;
}

/// Standard tracking metrics used across the app.
class TrackingMetrics {
  TrackingMetrics._();

  static const water = TrackingMetric(
    title: 'Water',
    icon: Icons.water_drop,
    color: Color(0xFF29B6F6),
    unit: 'L',
    step: 0.25,
    getValue: _getWater,
    getGoal: _getWaterGoal,
  );

  static const exercise = TrackingMetric(
    title: 'Exercise',
    icon: Icons.fitness_center,
    color: Color(0xFFEF5350),
    unit: 'min',
    step: 5,
    getValue: _getExercise,
    getGoal: _getExerciseGoal,
  );

  static const sunlight = TrackingMetric(
    title: 'Sunlight',
    icon: Icons.wb_sunny,
    color: Color(0xFFFFB300),
    unit: 'min',
    step: 5,
    getValue: _getSunlight,
    getGoal: _getSunlightGoal,
  );

  static const sleep = TrackingMetric(
    title: 'Sleep',
    icon: Icons.bedtime,
    color: Color(0xFF7E57C2),
    unit: 'hrs',
    step: 0.5,
    getValue: _getSleep,
    getGoal: _getSleepGoal,
  );

  static const social = TrackingMetric(
    title: 'Social',
    icon: Icons.people,
    color: Color(0xFF26A69A),
    unit: 'min',
    step: 5,
    getValue: _getSocial,
    getGoal: _getSocialGoal,
  );

  static List<TrackingMetric> get all => [water, exercise, sunlight, sleep, social];

  // Value getters
  static double _getWater(DailyLog log) => log.waterLiters;
  static double _getExercise(DailyLog log) => log.exerciseMinutes.toDouble();
  static double _getSunlight(DailyLog log) => log.sunlightMinutes.toDouble();
  static double _getSleep(DailyLog log) => log.sleepHours;
  static double _getSocial(DailyLog log) => log.socialMinutes.toDouble();

  // Goal getters
  static double _getWaterGoal(UserConfig config) => config.waterGoalLiters;
  static double _getExerciseGoal(UserConfig config) => config.exerciseGoalMinutes.toDouble();
  static double _getSunlightGoal(UserConfig config) => config.sunlightGoalMinutes.toDouble();
  static double _getSleepGoal(UserConfig config) => config.sleepGoalHours;
  static double _getSocialGoal(UserConfig config) => config.socialGoalMinutes.toDouble();
}

/// Grid of progress tracking cards.
class TrackingGrid extends StatelessWidget {
  const TrackingGrid({
    super.key,
    required this.log,
    required this.config,
    required this.onMetricChanged,
    required this.onFoodTap,
  });

  final DailyLog log;
  final UserConfig config;
  final void Function(TrackingMetric metric, double value) onMetricChanged;
  final VoidCallback onFoodTap;

  // Card sizing constraints
  static const double _minCardWidth = 180;
  static const double _maxCardWidth = 240;
  static const double _cardHeight = 138;
  static const double _spacing = 10;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        
        // Calculate optimal number of columns based on available width
        // Aim for cards between min and max width
        int columns = (availableWidth / _minCardWidth).floor().clamp(2, 6);
        
        // Calculate actual card width given the columns
        final totalSpacing = (columns - 1) * _spacing;
        final cardWidth = ((availableWidth - totalSpacing) / columns).clamp(_minCardWidth, _maxCardWidth);
        
        // If cards are at max width, we might fit more columns
        // Recalculate to center the grid nicely
        final actualTotalWidth = (cardWidth * columns) + totalSpacing;
        final horizontalPadding = (availableWidth - actualTotalWidth) / 2;

        // Build all cards: metrics + food card
        final cards = <Widget>[
          // Slider-based metric cards
          ...TrackingMetrics.all.map((metric) {
            return SizedBox(
              width: cardWidth,
              height: _cardHeight,
              child: DraggableProgressCard(
                title: metric.title,
                icon: metric.icon,
                color: metric.color,
                currentValue: metric.getValue(log),
                goalValue: metric.getGoal(config),
                unit: metric.unit,
                step: metric.step,
                onChanged: (value) => onMetricChanged(metric, value),
              ),
            );
          }),
          // Food/Nutrition card (tappable, no slider)
          SizedBox(
            width: cardWidth,
            height: _cardHeight,
            child: NutritionScoreCard(
              log: log,
              config: config,
              onTap: onFoodTap,
            ),
          ),
        ];

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding.clamp(0, double.infinity)),
          child: Wrap(
            spacing: _spacing,
            runSpacing: _spacing,
            children: cards,
          ),
        );
      },
    );
  }
}

