import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/responsive.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

/// Daily tracking screen - main view for entering and viewing today's data.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    this.detailController,
  });

  final DetailPanelController? detailController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedDate = ref.watch(selectedDateProvider);
    final isToday = ref.watch(selectedDateProvider.notifier).isToday;
    final log = ref.watch(dailyLogProvider);
    final config = ref.watch(userConfigProvider);
    final width = MediaQuery.of(context).size.width;
    final isMobile = Breakpoints.isMobile(width);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact greeting for mobile
            if (isMobile) ...[
              _buildCompactGreeting(context, theme, colorScheme, isToday),
              const SizedBox(height: 12),
            ],
            DateHeader(
              date: selectedDate,
              isToday: isToday,
              onPreviousDay: () => ref.read(selectedDateProvider.notifier).previousDay(),
              onNextDay: isToday ? null : () => ref.read(selectedDateProvider.notifier).nextDay(),
              onDatePicked: (date) => ref.read(selectedDateProvider.notifier).setDate(date),
            ),
            const SizedBox(height: 20),

            const SectionHeader(title: 'Overview'),
            const SizedBox(height: 4),
            Text(
              'Tap any card for detailed tracking and insights',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            _EnhancedTrackingGrid(
              log: log,
              config: config,
              onMetricChanged: (metric, value) => _handleMetricChange(ref, metric, value),
              onFoodTap: () => _showFoodDetail(context, ref, log, config, selectedDate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactGreeting(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isToday,
  ) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return Row(
      children: [
        Expanded(
          child: Text(
            isToday ? greeting : 'Viewing history',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (isToday)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, size: 8, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  'Live',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _handleMetricChange(WidgetRef ref, TrackingMetric metric, double value) {
    final notifier = ref.read(dailyLogProvider.notifier);

    switch (metric.title) {
      case 'Water':
        notifier.setWater(value);
      case 'Exercise':
        notifier.setExercise(value.toInt());
      case 'Sunlight':
        notifier.setSunlight(value.toInt());
      case 'Sleep':
        notifier.setSleep(value);
      case 'Social':
        notifier.setSocial(value.toInt());
    }
  }

  void _showFoodDetail(
    BuildContext context,
    WidgetRef ref,
    DailyLog log,
    UserConfig config,
    DateTime selectedDate,
  ) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = Breakpoints.isMobile(width);

    final foodDetailView = FoodDetailView(
      selectedDate: selectedDate,
      onClose: () {
        if (isMobile) {
          Navigator.of(context).pop();
        } else {
          detailController?.close();
        }
      },
    );

    if (isMobile) {
      // Full-screen page for mobile
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return Scaffold(
              body: SafeArea(child: foodDetailView),
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      );
    } else {
      // Side panel for tablet/desktop
      detailController?.open(foodDetailView);
    }
  }
}

/// Enhanced tracking grid with hover effects and quick actions.
class _EnhancedTrackingGrid extends StatelessWidget {
  const _EnhancedTrackingGrid({
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
  static const double _minCardWidth = 160;
  static const double _maxCardWidth = 300;
  static const double _spacing = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // Calculate optimal number of columns based on available width
        int columns = (availableWidth / _minCardWidth).floor().clamp(2, 6);

        // Calculate actual card width given the columns
        final totalSpacing = (columns - 1) * _spacing;
        final cardWidth = ((availableWidth - totalSpacing) / columns).clamp(_minCardWidth, _maxCardWidth);

        // Height based on width (aspect ratio ~1.1)
        final cardHeight = cardWidth * 0.85;

        // Build all cards: metrics + food card
        final cards = <Widget>[
          // Slider-based metric cards with quick actions
          ...TrackingMetrics.all.map((metric) {
            return SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: EnhancedTrackingCard(
                title: metric.title,
                icon: metric.icon,
                color: metric.color,
                currentValue: metric.getValue(log),
                goalValue: metric.getGoal(config),
                unit: metric.unit,
                step: metric.step,
                onChanged: (value) => onMetricChanged(metric, value),
                quickActionIcon: _getQuickActionIcon(metric.title),
                quickActionLabel: _getQuickActionLabel(metric),
              ),
            );
          }),
          // Food/Nutrition card (tappable, no slider)
          SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: _EnhancedNutritionCard(
              log: log,
              config: config,
              onTap: onFoodTap,
            ),
          ),
        ];

        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: cards,
        );
      },
    );
  }

  IconData _getQuickActionIcon(String title) {
    return switch (title) {
      'Water' => Icons.add,
      'Exercise' => Icons.add,
      'Sunlight' => Icons.add,
      'Sleep' => Icons.add,
      'Social' => Icons.add,
      _ => Icons.add,
    };
  }

  String _getQuickActionLabel(TrackingMetric metric) {
    return switch (metric.title) {
      'Water' => '+1 glass',
      'Exercise' => '+${metric.step.toInt()} min',
      'Sunlight' => '+${metric.step.toInt()} min',
      'Sleep' => '+30 min',
      'Social' => '+${metric.step.toInt()} min',
      _ => '+${metric.step}',
    };
  }
}

/// Enhanced nutrition card with hover effects.
class _EnhancedNutritionCard extends StatefulWidget {
  const _EnhancedNutritionCard({
    required this.log,
    required this.config,
    required this.onTap,
  });

  final DailyLog log;
  final UserConfig config;
  final VoidCallback onTap;

  @override
  State<_EnhancedNutritionCard> createState() => _EnhancedNutritionCardState();
}

class _EnhancedNutritionCardState extends State<_EnhancedNutritionCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _hoverController;
  late final Animation<double> _hoverAnimation;

  static const Color macroColor = Color(0xFFFF6B35);
  static const Color microColor = Color(0xFF26A69A);

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _hoverAnimation = CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  double get _macroProgress {
    final nutrition = widget.log.nutritionSummary;
    if (widget.log.foodEntries.isEmpty) return 0;

    final rec = NutritionSummary.recommendedDaily;

    final calorieProgress = (nutrition.calories / widget.config.calorieGoal).clamp(0.0, 1.0);
    final proteinProgress = (nutrition.protein / widget.config.proteinGoalGrams).clamp(0.0, 1.0);
    final carbsProgress = (nutrition.carbs / rec.carbs).clamp(0.0, 1.0);
    final fatProgress = (nutrition.fat / rec.fat).clamp(0.0, 1.0);

    return (calorieProgress + proteinProgress + carbsProgress + fatProgress) / 4;
  }

  double get _microProgress {
    final nutrition = widget.log.nutritionSummary;
    if (widget.log.foodEntries.isEmpty) return 0;

    final rec = NutritionSummary.recommendedDaily;

    final fiberProgress = (nutrition.fiber / rec.fiber).clamp(0.0, 1.0);
    final vitaminCProgress = (nutrition.vitaminC / rec.vitaminC).clamp(0.0, 1.0);
    final calciumProgress = (nutrition.calcium / rec.calcium).clamp(0.0, 1.0);
    final ironProgress = (nutrition.iron / rec.iron).clamp(0.0, 1.0);

    return (fiberProgress + vitaminCProgress + calciumProgress + ironProgress) / 4;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: AnimatedBuilder(
        animation: _hoverAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_hoverAnimation.value * 0.02),
            child: Card(
              elevation: _hoverAnimation.value * 4,
              shadowColor: macroColor.withValues(alpha: 0.3),
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: _isHovered
                      ? macroColor.withValues(alpha: 0.3)
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: _isHovered ? 1.5 : 1,
                ),
              ),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(14),
                splashColor: macroColor.withValues(alpha: 0.1),
                highlightColor: macroColor.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme),
                      const Spacer(),
                      Flexible(
                        flex: 0,
                        child: Text(
                          'Nutrients',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _buildValueDisplay(theme),
                      const SizedBox(height: 6),
                      _buildDualProgressBar(theme),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Hero(
          tag: 'food_icon',
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: macroColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.restaurant_menu, color: macroColor, size: 18),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Food',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (_isHovered)
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
      ],
    );
  }

  Widget _buildValueDisplay(ThemeData theme) {
    final macroPercent = (_macroProgress * 100).toInt();
    final microPercent = (_microProgress * 100).toInt();

    return Row(
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Macro $macroPercent%',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: macroColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              'Micro $microPercent%',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: microColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDualProgressBar(ThemeData theme) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Macro bar
          Expanded(
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                color: macroColor.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _macroProgress,
                child: Container(
                  decoration: const BoxDecoration(
                    color: macroColor,
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Micro bar
          Expanded(
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                color: microColor.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _microProgress,
                child: Container(
                  decoration: const BoxDecoration(
                    color: microColor,
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
