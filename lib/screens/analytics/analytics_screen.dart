import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../data/data.dart';

/// Analytics screen - view trends and historical data.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _selectedDays = 7;
  List<DailyLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    final repository = ref.read(dailyLogRepositoryProvider);
    setState(() => _logs = repository.getRecentLogs(_selectedDays));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final config = ref.watch(userConfigProvider);

    final stats = _calculateStats(config);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildTimeRangeSelector(context),
            const SizedBox(height: 24),
            _buildSummaryCards(context, stats),
            const SizedBox(height: 28),
            _buildSectionTitle(theme, 'Progress Over Time'),
            const SizedBox(height: 12),
            _buildMainChart(context, config),
            const SizedBox(height: 28),
            _buildSectionTitle(theme, 'Average by Metric'),
            const SizedBox(height: 12),
            _buildMetricAveragesGrid(context, config, stats),
            const SizedBox(height: 28),
            _buildSectionTitle(theme, 'Streaks & Achievements'),
            const SizedBox(height: 12),
            _buildStreaksSection(context, config),
            const SizedBox(height: 28),
            _buildSectionTitle(theme, 'Nutrition Insights'),
            const SizedBox(height: 12),
            _buildNutritionInsights(context),
          ],
        ),
      ),
    );
  }

  _Stats _calculateStats(UserConfig config) {
    if (_logs.isEmpty) {
      return _Stats.empty();
    }

    final avgWater = _logs.map((l) => l.waterLiters).reduce((a, b) => a + b) / _logs.length;
    final avgExercise = _logs.map((l) => l.exerciseMinutes).reduce((a, b) => a + b) ~/ _logs.length;
    final avgSunlight = _logs.map((l) => l.sunlightMinutes).reduce((a, b) => a + b) ~/ _logs.length;
    final avgSleep = _logs.map((l) => l.sleepHours).reduce((a, b) => a + b) / _logs.length;

    double calcCompletion(DailyLog log) {
      final water = (log.waterLiters / config.waterGoalLiters).clamp(0.0, 1.0);
      final exercise = (log.exerciseMinutes / config.exerciseGoalMinutes).clamp(0.0, 1.0);
      final sunlight = (log.sunlightMinutes / config.sunlightGoalMinutes).clamp(0.0, 1.0);
      final sleep = (log.sleepHours / config.sleepGoalHours).clamp(0.0, 1.0);
      return (water + exercise + sunlight + sleep) / 4;
    }

    final avgCompletion = _logs.map(calcCompletion).reduce((a, b) => a + b) / _logs.length;
    final perfectDays = _logs.where((l) => calcCompletion(l) >= 1.0).length;

    int currentStreak = 0;
    for (final log in _logs.reversed) {
      if (calcCompletion(log) >= 0.5) {
        currentStreak++;
      } else {
        break;
      }
    }

    return _Stats(
      avgWater: avgWater,
      avgExercise: avgExercise,
      avgSunlight: avgSunlight,
      avgSleep: avgSleep,
      avgCompletion: avgCompletion,
      perfectDays: perfectDays,
      currentStreak: currentStreak,
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Track your progress over time',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        FilledButton.tonalIcon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export feature coming soon!')),
            );
          },
          icon: const Icon(Icons.download, size: 16),
          label: const Text('Export'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [7, 14, 30, 90].map((days) {
          return _buildTimeRangeChip(context, '${days}D', days);
        }).toList(),
      ),
    );
  }

  Widget _buildTimeRangeChip(BuildContext context, String label, int days) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = _selectedDays == days;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (value) {
          setState(() => _selectedDays = days);
          _loadLogs();
        },
        selectedColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurface.withValues(alpha: 0.6),
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        side: BorderSide.none,
        showCheckmark: false,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, _Stats stats) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Average Completion',
            value: '${(stats.avgCompletion * 100).toInt()}%',
            icon: Icons.pie_chart_outline,
            color: const Color(0xFF4CAF50),
            subtitle: 'Last $_selectedDays days',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Current Streak',
            value: '${stats.currentStreak} days',
            icon: Icons.local_fire_department,
            color: const Color(0xFFFF9800),
            subtitle: '>50% completion',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Days Tracked',
            value: '${_logs.length}',
            icon: Icons.calendar_today_outlined,
            color: const Color(0xFF2196F3),
            subtitle: 'This period',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Perfect Days',
            value: '${stats.perfectDays}',
            icon: Icons.emoji_events_outlined,
            color: const Color(0xFF9C27B0),
            subtitle: '100% completion',
          ),
        ),
      ],
    );
  }

  Widget _buildMainChart(BuildContext context, UserConfig config) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_logs.isEmpty) {
      return _buildEmptyState(theme, colorScheme, Icons.show_chart, 'No data yet', 'Start tracking to see your trends');
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Container(
        height: 260,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Completion %',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _logs.map((log) {
                  final completion = _getLogCompletion(log, config);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: completion,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            log.date.substring(8),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getLogCompletion(DailyLog log, UserConfig config) {
    final water = (log.waterLiters / config.waterGoalLiters).clamp(0.0, 1.0);
    final exercise = (log.exerciseMinutes / config.exerciseGoalMinutes).clamp(0.0, 1.0);
    final sunlight = (log.sunlightMinutes / config.sunlightGoalMinutes).clamp(0.0, 1.0);
    final sleep = (log.sleepHours / config.sleepGoalHours).clamp(0.0, 1.0);
    return (water + exercise + sunlight + sleep) / 4;
  }

  Widget _buildMetricAveragesGrid(BuildContext context, UserConfig config, _Stats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _MetricAverageCard(
          title: 'Water',
          icon: Icons.water_drop,
          color: const Color(0xFF29B6F6),
          value: '${stats.avgWater.toStringAsFixed(1)} L',
          goal: 'Goal: ${config.waterGoalLiters} L',
          progress: stats.avgWater / config.waterGoalLiters,
        ),
        _MetricAverageCard(
          title: 'Exercise',
          icon: Icons.fitness_center,
          color: const Color(0xFFEF5350),
          value: '${stats.avgExercise} min',
          goal: 'Goal: ${config.exerciseGoalMinutes} min',
          progress: stats.avgExercise / config.exerciseGoalMinutes,
        ),
        _MetricAverageCard(
          title: 'Sunlight',
          icon: Icons.wb_sunny,
          color: const Color(0xFFFFB300),
          value: '${stats.avgSunlight} min',
          goal: 'Goal: ${config.sunlightGoalMinutes} min',
          progress: stats.avgSunlight / config.sunlightGoalMinutes,
        ),
        _MetricAverageCard(
          title: 'Sleep',
          icon: Icons.bedtime,
          color: const Color(0xFF7E57C2),
          value: '${stats.avgSleep.toStringAsFixed(1)} hrs',
          goal: 'Goal: ${config.sleepGoalHours} hrs',
          progress: stats.avgSleep / config.sleepGoalHours,
        ),
      ],
    );
  }

  Widget _buildStreaksSection(BuildContext context, UserConfig config) {
    int calcStreak(double Function(DailyLog) getValue, double goal) {
      int streak = 0;
      for (final log in _logs.reversed) {
        if (getValue(log) >= goal) {
          streak++;
        } else {
          break;
        }
      }
      return streak;
    }

    return _StreaksCard(
      waterStreak: calcStreak((l) => l.waterLiters, config.waterGoalLiters),
      exerciseStreak: calcStreak((l) => l.exerciseMinutes.toDouble(), config.exerciseGoalMinutes.toDouble()),
      sunlightStreak: calcStreak((l) => l.sunlightMinutes.toDouble(), config.sunlightGoalMinutes.toDouble()),
      sleepStreak: calcStreak((l) => l.sleepHours, config.sleepGoalHours),
    );
  }

  Widget _buildNutritionInsights(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    int totalFoodEntries = _logs.fold(0, (sum, log) => sum + log.foodEntries.length);

    if (totalFoodEntries == 0) {
      return _buildEmptyState(theme, colorScheme, Icons.restaurant, 'No nutrition data yet', 'Log food to see AI-powered nutrition insights');
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.restaurant, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalFoodEntries meals logged',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'In the last $_selectedDays days',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme, IconData icon, String title, String subtitle) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          children: [
            Icon(icon, size: 36, color: colorScheme.onSurface.withValues(alpha: 0.25)),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stats {
  final double avgWater;
  final int avgExercise;
  final int avgSunlight;
  final double avgSleep;
  final double avgCompletion;
  final int perfectDays;
  final int currentStreak;

  const _Stats({
    required this.avgWater,
    required this.avgExercise,
    required this.avgSunlight,
    required this.avgSleep,
    required this.avgCompletion,
    required this.perfectDays,
    required this.currentStreak,
  });

  factory _Stats.empty() => const _Stats(
        avgWater: 0,
        avgExercise: 0,
        avgSunlight: 0,
        avgSleep: 0,
        avgCompletion: 0,
        perfectDays: 0,
        currentStreak: 0,
      );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricAverageCard extends StatelessWidget {
  const _MetricAverageCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.value,
    required this.goal,
    required this.progress,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String value;
  final String goal;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    goal,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.35),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 3,
                    backgroundColor: color.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  Text(
                    '${(progress.clamp(0.0, 1.0) * 100).toInt()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 9,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreaksCard extends StatelessWidget {
  const _StreaksCard({
    required this.waterStreak,
    required this.exerciseStreak,
    required this.sunlightStreak,
    required this.sleepStreak,
  });

  final int waterStreak;
  final int exerciseStreak;
  final int sunlightStreak;
  final int sleepStreak;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            _StreakItem(title: 'Water', icon: Icons.water_drop, color: const Color(0xFF29B6F6), streak: waterStreak),
            _buildDivider(colorScheme),
            _StreakItem(title: 'Exercise', icon: Icons.fitness_center, color: const Color(0xFFEF5350), streak: exerciseStreak),
            _buildDivider(colorScheme),
            _StreakItem(title: 'Sunlight', icon: Icons.wb_sunny, color: const Color(0xFFFFB300), streak: sunlightStreak),
            _buildDivider(colorScheme),
            _StreakItem(title: 'Sleep', icon: Icons.bedtime, color: const Color(0xFF7E57C2), streak: sleepStreak),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Container(
      width: 1,
      height: 48,
      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }
}

class _StreakItem extends StatelessWidget {
  const _StreakItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.streak,
  });

  final String title;
  final IconData icon;
  final Color color;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            '$streak days',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
