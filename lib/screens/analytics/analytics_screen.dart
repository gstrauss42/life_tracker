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
  final Set<String> _selectedMetrics = {'Water', 'Sleep', 'Exercise'};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final analyticsData = ref.watch(analyticsDataProvider(_selectedDays));
    final aiAnalysisState = ref.watch(aiAnalysisProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildPeriodSelectorWithSummary(context, analyticsData),
            const SizedBox(height: 24),
            _buildSectionTitle(theme, 'Metrics'),
            const SizedBox(height: 12),
            _buildMetricCards(context, analyticsData),
            const SizedBox(height: 28),
            _buildSectionTitle(theme, 'Trends'),
            const SizedBox(height: 12),
            _buildTrendsChart(context, analyticsData),
            if (analyticsData.nutritionInsights.hasFoodData) ...[
              const SizedBox(height: 28),
              _buildSectionTitle(theme, 'Nutrition Breakdown'),
              const SizedBox(height: 12),
              _buildNutritionInsights(context, analyticsData),
            ],
            if (analyticsData.patternInsights.hasEnoughData) ...[
              const SizedBox(height: 28),
              _buildSectionTitle(theme, 'Patterns'),
              const SizedBox(height: 12),
              _buildPatternsSection(context, analyticsData),
            ],
            const SizedBox(height: 28),
            _buildSectionTitle(theme, 'AI Analysis'),
            const SizedBox(height: 12),
            _buildAIAnalysisSection(context, aiAnalysisState),
            const SizedBox(height: 28),
            _buildStreaksCompact(context, analyticsData),
            const SizedBox(height: 20),
          ],
        ),
      ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 400;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
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
                isNarrow ? 'Track progress' : 'Insights from your tracking data',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonalIcon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export feature coming soon!')),
            );
          },
          icon: Icon(Icons.download, size: isNarrow ? 14 : 16),
          label: Text(isNarrow ? '' : 'Export'),
          style: FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 10 : 14,
              vertical: isNarrow ? 8 : 10,
            ),
            textStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelectorWithSummary(BuildContext context, ComputedAnalyticsData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Period selector
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [7, 14, 30, 90].map((days) {
                return _buildTimeRangeChip(context, '${days}D', days);
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Summary bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.insights, size: 18, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.periodSummary,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildMetricCards(BuildContext context, ComputedAnalyticsData data) {
    if (data.metricCards.isEmpty) {
      return _buildEmptyState(
        Theme.of(context),
        Theme.of(context).colorScheme,
        Icons.bar_chart,
        'No metrics data',
        'Start tracking to see your metrics',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWide = width >= 600;

        if (isWide) {
          // 2 columns
          final List<Widget> rows = [];
          for (int i = 0; i < data.metricCards.length; i += 2) {
            rows.add(Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _MetricCard(data: data.metricCards[i])),
                const SizedBox(width: 12),
                if (i + 1 < data.metricCards.length)
                  Expanded(child: _MetricCard(data: data.metricCards[i + 1]))
                else
                  const Expanded(child: SizedBox()),
              ],
            ));
            if (i + 2 < data.metricCards.length) {
              rows.add(const SizedBox(height: 12));
            }
          }
          return Column(children: rows);
        }

        // Single column
        return Column(
          children: [
            for (int i = 0; i < data.metricCards.length; i++) ...[
              _MetricCard(data: data.metricCards[i]),
              if (i < data.metricCards.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTrendsChart(BuildContext context, ComputedAnalyticsData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final config = ref.watch(userConfigProvider);
    final dailyLogRepo = ref.read(dailyLogRepositoryProvider);
    final allLogs = dailyLogRepo.getRecentLogs(_selectedDays);
    
    // Filter out today's data - trends should show historical data only
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final logs = allLogs.where((log) => log.date != todayStr).toList();

    // Need at least 2 days of historical data to show meaningful trends
    if (logs.length < 2) {
      return _buildEmptyState(
        theme,
        colorScheme,
        Icons.show_chart,
        'Not enough data',
        'Log at least 2 days to see trends',
      );
    }

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
            // Metric selector chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChartMetricChip('Water', const Color(0xFF29B6F6)),
                _buildChartMetricChip('Sleep', const Color(0xFF7E57C2)),
                _buildChartMetricChip('Exercise', const Color(0xFFEF5350)),
                _buildChartMetricChip('Sunlight', const Color(0xFFFFB300)),
              ],
            ),
            const SizedBox(height: 20),
            // Chart
            SizedBox(
              height: 200,
              child: _buildLineChart(logs, config, colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartMetricChip(String metric, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedMetrics.contains(metric);

    return FilterChip(
      label: Text(metric),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedMetrics.add(metric);
          } else if (_selectedMetrics.length > 1) {
            _selectedMetrics.remove(metric);
          }
        });
      },
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : colorScheme.onSurface.withValues(alpha: 0.6),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(
        color: isSelected ? color.withValues(alpha: 0.5) : colorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildLineChart(List<DailyLog> logs, UserConfig config, ColorScheme colorScheme) {
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: _TrendChartPainter(
        logs: logs,
        config: config,
        selectedMetrics: _selectedMetrics,
        colorScheme: colorScheme,
      ),
    );
  }

  Widget _buildNutritionInsights(BuildContext context, ComputedAnalyticsData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nutrition = data.nutritionInsights;

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
            // Macros section
            Text(
              'Macros (avg daily)',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            _buildMacroRow('Protein', nutrition.avgProtein, nutrition.proteinGoal, 'g', nutrition.proteinPercent, const Color(0xFFEF5350)),
            const SizedBox(height: 8),
            _buildMacroRow('Carbs', nutrition.avgCarbs, nutrition.carbsGoal, 'g', nutrition.carbsPercent, const Color(0xFFFFB300)),
            const SizedBox(height: 8),
            _buildMacroRow('Fat', nutrition.avgFat, nutrition.fatGoal, 'g', nutrition.fatPercent, const Color(0xFF29B6F6)),
            const SizedBox(height: 8),
            _buildMacroRow('Fiber', nutrition.avgFiber, nutrition.fiberGoal, 'g', nutrition.fiberPercent, const Color(0xFF66BB6A)),
            
            if (nutrition.deficiencies.isNotEmpty) ...[
              const SizedBox(height: 20),
              Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                'Attention Needed',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              ...nutrition.deficiencies.take(3).map((def) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 16, color: colorScheme.error.withValues(alpha: 0.7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${def.name} - ${def.avgPercent.round()}% of goal (${def.description})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            
            if (nutrition.topFoods.isNotEmpty) ...[
              const SizedBox(height: 20),
              Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                'Top Foods Logged',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: nutrition.topFoods.map((food) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${food.name} (${food.count}x)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            
            const SizedBox(height: 16),
            Text(
              'Meals: ${nutrition.avgMealsPerDay.toStringAsFixed(1)}/day avg',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRow(String name, double value, double goal, String unit, double percent, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isGood = percent >= 90 && percent <= 110;

    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            name,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (percent / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 90,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${value.round()}$unit',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${percent.round()}%)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isGood ? const Color(0xFF4CAF50) : colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              if (isGood)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.check_circle, size: 14, color: Color(0xFF4CAF50)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatternsSection(BuildContext context, ComputedAnalyticsData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final patterns = data.patternInsights;

    if (!patterns.hasEnoughData) {
      return _buildEmptyState(
        theme,
        colorScheme,
        Icons.auto_graph,
        'Not enough data',
        'Log more days to see patterns emerge',
      );
    }

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
            // Day-of-week patterns
            if (patterns.mostActiveDays.isNotEmpty || patterns.restDays.isNotEmpty) ...[
              Text(
                'Day-of-week',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              if (patterns.mostActiveDays.isNotEmpty)
                _buildPatternItem('Most active: ${patterns.mostActiveDays.join(", ")}', Icons.trending_up, const Color(0xFF4CAF50)),
              if (patterns.restDays.isNotEmpty)
                _buildPatternItem('Rest days: ${patterns.restDays.join(", ")}', Icons.bedtime, const Color(0xFF7E57C2)),
            ],
            
            if (patterns.correlations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Correlations found',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              ...patterns.correlations.map((corr) {
                return _buildPatternItem(
                  corr.description,
                  corr.isPositive ? Icons.thumb_up : Icons.info_outline,
                  corr.isPositive ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                );
              }),
            ],
            
            if (patterns.trends.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Trends',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              ...patterns.trends.map((trend) {
                final color = switch (trend.direction) {
                  TrendDirection.increasing => const Color(0xFF4CAF50),
                  TrendDirection.decreasing => const Color(0xFFEF5350),
                  _ => colorScheme.onSurface.withValues(alpha: 0.5),
                };
                return _buildPatternItem(
                  '${trend.metric}: ${trend.direction.arrow} ${trend.direction.label}',
                  Icons.trending_flat,
                  color,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPatternItem(String text, IconData icon, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysisSection(BuildContext context, AIAnalysisState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final config = ref.watch(userConfigProvider);
    final hasApiKey = config.aiApiKey != null && config.aiApiKey!.isNotEmpty;

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.auto_awesome, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI Analysis',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!hasApiKey)
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Set your API key in Settings to use AI analysis')),
                      );
                    },
                    child: const Text('Setup'),
                  )
                else if (state.analysis == null || state.canRegenerate)
                  FilledButton.tonal(
                    onPressed: state.isLoading
                        ? null
                        : () {
                            ref.read(aiAnalysisProvider.notifier).generateAnalysis(days: _selectedDays);
                          },
                    child: state.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(state.analysis == null ? 'Generate' : 'Regenerate'),
                  )
                else
                  IconButton(
                    onPressed: () {
                      ref.read(aiAnalysisProvider.notifier).generateAnalysis(days: _selectedDays);
                    },
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Regenerate analysis',
                  ),
              ],
            ),
            
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Error generating analysis. Please try again.',
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (state.analysis != null && state.analysis!.hasContent) ...[
              const SizedBox(height: 16),
              
              // What's Working
              if (state.analysis!.working.isNotEmpty) ...[
                _buildAISection(
                  title: "What's Working",
                  items: state.analysis!.working,
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(height: 16),
              ],
              
              // Needs Attention
              if (state.analysis!.attention.isNotEmpty) ...[
                _buildAISection(
                  title: 'Needs Attention',
                  items: state.analysis!.attention,
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFFF9800),
                ),
                const SizedBox(height: 16),
              ],
              
              // Recommendations
              if (state.analysis!.recommendations.isNotEmpty) ...[
                _buildAISection(
                  title: 'Recommendations',
                  items: state.analysis!.recommendations,
                  icon: Icons.lightbulb_outline,
                  color: const Color(0xFF2196F3),
                ),
                const SizedBox(height: 12),
              ],
              
              // Timestamp
              Text(
                'Generated: ${_formatTimestamp(state.analysis!.generatedAt)} • Based on ${state.analysis!.daysAnalyzed} days of data',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ] else if (!hasApiKey) ...[
              const SizedBox(height: 12),
              Text(
                'Configure your AI API key in Settings to get personalized insights.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'Generate an AI analysis to get personalized insights based on your tracking data.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAISection({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5))),
                Expanded(
                  child: Text(
                    item,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    
    return '${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStreaksCompact(BuildContext context, ComputedAnalyticsData data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(
            'Streaks:',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _buildStreakChip(Icons.water_drop, const Color(0xFF29B6F6), data.streaks['water'] ?? 0),
                _buildStreakChip(Icons.fitness_center, const Color(0xFFEF5350), data.streaks['exercise'] ?? 0),
                _buildStreakChip(Icons.wb_sunny, const Color(0xFFFFB300), data.streaks['sunlight'] ?? 0),
                _buildStreakChip(Icons.bedtime, const Color(0xFF7E57C2), data.streaks['sleep'] ?? 0),
                _buildStreakChip(Icons.restaurant, const Color(0xFFFF6B35), data.streaks['nutrition'] ?? 0),
                _buildStreakChip(Icons.people, const Color(0xFF26A69A), data.streaks['social'] ?? 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakChip(IconData icon, Color color, int days) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = days > 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isActive ? color : colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        const SizedBox(width: 3),
        Text(
          '${days}d',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Overview card with trend indicator
/// Metric card with detailed information
class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final MetricCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = Color(data.color);

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
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    IconData(data.iconCodePoint, fontFamily: 'MaterialIcons'),
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${data.goalPercentage.round()}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Value row
            Text(
              '${data.average.toStringAsFixed(1)}${data.unit} avg / ${data.goal.toStringAsFixed(1)}${data.unit} goal',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 10),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (data.goalPercentage / 100).clamp(0.0, 1.0),
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            // Details row
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Trend',
                    '${data.trend.arrow} ${data.trend.label}',
                    data.trend == TrendDirection.increasing
                        ? const Color(0xFF4CAF50)
                        : data.trend == TrendDirection.decreasing
                            ? const Color(0xFFEF5350)
                            : null,
                    theme,
                    colorScheme,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Best day',
                    '${data.bestDay} (${data.bestValue.toStringAsFixed(1)}${data.unit})',
                    null,
                    theme,
                    colorScheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Consistency',
                    data.consistencyText,
                    null,
                    theme,
                    colorScheme,
                  ),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, Color? valueColor, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.4),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: valueColor ?? colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Custom painter for the trend chart
class _TrendChartPainter extends CustomPainter {
  _TrendChartPainter({
    required this.logs,
    required this.config,
    required this.selectedMetrics,
    required this.colorScheme,
  });

  final List<DailyLog> logs;
  final UserConfig config;
  final Set<String> selectedMetrics;
  final ColorScheme colorScheme;

  static const _metricColors = {
    'Water': Color(0xFF29B6F6),
    'Sleep': Color(0xFF7E57C2),
    'Exercise': Color(0xFFEF5350),
    'Sunlight': Color(0xFFFFB300),
  };

  @override
  void paint(Canvas canvas, Size size) {
    if (logs.isEmpty) return;

    final padding = const EdgeInsets.only(left: 40, right: 10, top: 10, bottom: 25);
    final chartRect = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.left - padding.right,
      size.height - padding.top - padding.bottom,
    );

    // Draw grid
    _drawGrid(canvas, chartRect);

    // Draw lines for each selected metric
    for (final metric in selectedMetrics) {
      final color = _metricColors[metric] ?? colorScheme.primary;
      final (values, maxValue, goal) = _getMetricValues(metric);
      _drawLine(canvas, chartRect, values, maxValue, color, goal);
    }

    // Draw x-axis labels
    _drawXAxisLabels(canvas, chartRect);

    // Draw y-axis labels (for primary metric)
    if (selectedMetrics.isNotEmpty) {
      final (_, maxValue, _) = _getMetricValues(selectedMetrics.first);
      _drawYAxisLabels(canvas, chartRect, maxValue);
    }
  }

  (List<double>, double, double) _getMetricValues(String metric) {
    final values = <double>[];
    double maxValue = 0;
    double goal = 0;

    for (final log in logs) {
      double value = 0;
      switch (metric) {
        case 'Water':
          value = log.waterLiters;
          goal = config.waterGoalLiters;
        case 'Sleep':
          value = log.sleepHours;
          goal = config.sleepGoalHours;
        case 'Exercise':
          value = log.exerciseMinutes.toDouble();
          goal = config.exerciseGoalMinutes.toDouble();
        case 'Sunlight':
          value = log.sunlightMinutes.toDouble();
          goal = config.sunlightGoalMinutes.toDouble();
      }
      values.add(value);
      if (value > maxValue) maxValue = value;
    }

    // Ensure max is at least the goal
    if (goal > maxValue) maxValue = goal;
    // Add some padding
    maxValue *= 1.1;

    return (values, maxValue, goal);
  }

  void _drawGrid(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    // Horizontal lines
    for (int i = 0; i <= 4; i++) {
      final y = rect.top + (rect.height * i / 4);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
    }
  }

  void _drawLine(Canvas canvas, Rect rect, List<double> values, double maxValue, Color color, double goal) {
    if (values.isEmpty || maxValue == 0) return;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final goalPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = rect.left + (i / (values.length - 1).clamp(1, double.infinity)) * rect.width;
      final y = rect.bottom - (values[i] / maxValue) * rect.height;
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      fillPath.moveTo(points.first.dx, rect.bottom);
      fillPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
        fillPath.lineTo(points[i].dx, points[i].dy);
      }

      fillPath.lineTo(points.last.dx, rect.bottom);
      fillPath.close();

      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, linePaint);

      // Draw points
      final pointPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      for (final point in points) {
        canvas.drawCircle(point, 3, pointPaint);
      }
    }

    // Draw goal line
    final goalY = rect.bottom - (goal / maxValue) * rect.height;
    if (goalY >= rect.top && goalY <= rect.bottom) {
      final dashPath = Path();
      const dashWidth = 5.0;
      const dashSpace = 3.0;
      var x = rect.left;
      while (x < rect.right) {
        dashPath.moveTo(x, goalY);
        dashPath.lineTo((x + dashWidth).clamp(rect.left, rect.right), goalY);
        x += dashWidth + dashSpace;
      }
      canvas.drawPath(dashPath, goalPaint);
    }
  }

  void _drawXAxisLabels(Canvas canvas, Rect rect) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final step = logs.length <= 7 ? 1 : (logs.length / 7).ceil();
    for (int i = 0; i < logs.length; i += step) {
      final x = rect.left + (i / (logs.length - 1).clamp(1, double.infinity)) * rect.width;
      final date = logs[i].date.substring(8); // DD

      textPainter.text = TextSpan(
        text: date,
        style: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.4),
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, rect.bottom + 6));
    }
  }

  void _drawYAxisLabels(Canvas canvas, Rect rect, double maxValue) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i <= 4; i++) {
      final value = maxValue * (4 - i) / 4;
      final y = rect.top + (rect.height * i / 4);

      textPainter.text = TextSpan(
        text: value.toStringAsFixed(value > 10 ? 0 : 1),
        style: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.4),
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left - textPainter.width - 8, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.logs != logs ||
        oldDelegate.selectedMetrics != selectedMetrics ||
        oldDelegate.colorScheme != colorScheme;
  }
}
