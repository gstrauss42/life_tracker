import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/responsive.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../social/social_panel.dart';
import '../exercise/exercise_panel.dart';

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

    final padding = Breakpoints.getContentPadding(width);
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
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
              // On mobile, hide greeting (shown separately above) and use compact layout
              showGreeting: !isMobile,
              compactMode: isMobile,
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
              onSocialTap: () => _showSocialPanel(context, ref, selectedDate),
              onExerciseTap: () => _showExercisePanel(context, ref, selectedDate),
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

    // Use FittedBox to scale down if needed, but never truncate
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        isToday ? greeting : 'Viewing history',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
      ),
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
    // Use full-screen when mobile OR when screen is too narrow for side panel
    final useFullScreen = !Breakpoints.canShowDetailPanel(width);

    // Builder function to create the panel content with appropriate close callback
    Widget buildContent(VoidCallback onClose) {
      return FoodDetailView(
        selectedDate: selectedDate,
        onClose: onClose,
      );
    }

    if (useFullScreen) {
      // Full-screen page for mobile/narrow screens
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (pageContext, animation, secondaryAnimation) {
            return Scaffold(
              body: SafeArea(
                child: buildContent(() {
                  if (pageContext.mounted) {
                    Navigator.of(pageContext).maybePop();
                  }
                }),
              ),
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
      // Side panel for tablet/desktop - also pass contentBuilder for breakpoint crossing
      detailController?.open(
        buildContent(() => detailController?.close()),
        panelType: OpenPanelType.food,
        contentBuilder: buildContent,
      );
    }
  }

  void _showSocialPanel(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) {
    final width = MediaQuery.of(context).size.width;
    // Use full-screen when mobile OR when screen is too narrow for side panel
    final useFullScreen = !Breakpoints.canShowDetailPanel(width);

    // Builder function to create the panel content with appropriate close callback
    Widget buildContent(VoidCallback onClose) {
      return SocialPanel(
        selectedDate: selectedDate,
        onClose: onClose,
      );
    }

    if (useFullScreen) {
      // Full-screen page for mobile/narrow screens
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (pageContext, animation, secondaryAnimation) {
            return Scaffold(
              body: SafeArea(
                child: buildContent(() {
                  if (pageContext.mounted) {
                    Navigator.of(pageContext).maybePop();
                  }
                }),
              ),
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
      // Side panel for tablet/desktop - also pass contentBuilder for breakpoint crossing
      detailController?.open(
        buildContent(() => detailController?.close()),
        panelType: OpenPanelType.social,
        contentBuilder: buildContent,
      );
    }
  }

  void _showExercisePanel(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) {
    final width = MediaQuery.of(context).size.width;
    // Use full-screen when mobile OR when screen is too narrow for side panel
    final useFullScreen = !Breakpoints.canShowDetailPanel(width);

    void navigateToSettings() {
      // Navigate to settings and scroll to exercise preferences
      // Use post-frame callback to ensure navigation happens after panel closes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(settingsScrollTargetProvider.notifier).state = SettingsSections.exercisePreferences;
        ref.read(selectedTabProvider.notifier).state = NavTabs.settings;
      });
    }

    // Builder function to create the panel content with appropriate close callback
    Widget buildContent(VoidCallback onClose) {
      return ExercisePanel(
        selectedDate: selectedDate,
        onClose: onClose,
        onNavigateToSettings: navigateToSettings,
      );
    }

    if (useFullScreen) {
      // Full-screen page for mobile/narrow screens
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (pageContext, animation, secondaryAnimation) {
            return Scaffold(
              body: SafeArea(
                child: buildContent(() {
                  if (pageContext.mounted) {
                    Navigator.of(pageContext).maybePop();
                  }
                }),
              ),
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
      // Side panel for tablet/desktop - also pass contentBuilder for breakpoint crossing
      detailController?.open(
        buildContent(() => detailController?.close()),
        panelType: OpenPanelType.exercise,
        contentBuilder: buildContent,
      );
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
    required this.onSocialTap,
    required this.onExerciseTap,
  });

  final DailyLog log;
  final UserConfig config;
  final void Function(TrackingMetric metric, double value) onMetricChanged;
  final VoidCallback onFoodTap;
  final VoidCallback onSocialTap;
  final VoidCallback onExerciseTap;

  // Card sizing constraints
  static const double _minCardWidth = 150;
  static const double _maxCardWidth = 300;
  static const double _minCardHeight = 140;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        
        // Guard against invalid constraints
        if (availableWidth <= 0 || !availableWidth.isFinite) {
          return const SizedBox.shrink();
        }

        // Get responsive spacing based on width
        final spacing = Breakpoints.getCardSpacing(availableWidth);

        // Use the dedicated grid column calculator
        // - Desktop (>= 1024px): 3 columns
        // - Tablet/Mobile (< 1024px): 2 columns  
        // - Very narrow (< 360px): 1 column
        final columns = Breakpoints.getTrackingGridColumns(availableWidth);

        // Calculate actual card width given the columns
        final totalSpacing = (columns - 1) * spacing;
        final rawCardWidth = (availableWidth - totalSpacing) / columns;
        
        // Ensure card width is valid and within bounds
        final cardWidth = rawCardWidth.clamp(_minCardWidth, _maxCardWidth);

        // Height based on aspect ratio with minimum to prevent overflow
        // Use different aspect ratios for different column counts
        final aspectRatio = columns == 1 ? 2.0 : (columns == 2 ? 1.4 : 1.3);
        final cardHeight = (cardWidth / aspectRatio).clamp(_minCardHeight, 220.0);

        // Build all cards: metrics + food card + social card + exercise card
        final cards = <Widget>[
          // Slider-based metric cards with quick actions (exclude Social and Exercise)
          ...TrackingMetrics.all.where((m) => m.title != 'Social' && m.title != 'Exercise').map((metric) {
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
          // Exercise card (tappable, opens exercise panel)
          SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: _EnhancedExerciseCard(
              log: log,
              config: config,
              onTap: onExerciseTap,
            ),
          ),
          // Social card (tappable, opens discovery panel)
          SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: _EnhancedSocialCard(
              log: log,
              config: config,
              onTap: onSocialTap,
            ),
          ),
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
          spacing: spacing,
          runSpacing: spacing,
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

/// Enhanced social card with hover effects.
/// Displays social activity progress and is tappable to open the discovery panel.
class _EnhancedSocialCard extends StatefulWidget {
  const _EnhancedSocialCard({
    required this.log,
    required this.config,
    required this.onTap,
  });

  final DailyLog log;
  final UserConfig config;
  final VoidCallback onTap;

  @override
  State<_EnhancedSocialCard> createState() => _EnhancedSocialCardState();
}

class _EnhancedSocialCardState extends State<_EnhancedSocialCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _hoverController;
  late final Animation<double> _hoverAnimation;

  static const Color socialColor = Color(0xFF26A69A);

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

  double get _progress {
    final current = widget.log.socialMinutes;
    final goal = widget.config.socialGoalMinutes;
    if (goal <= 0) return 0;
    return (current / goal).clamp(0.0, 1.0);
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
              shadowColor: socialColor.withValues(alpha: 0.3),
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: _isHovered
                      ? socialColor.withValues(alpha: 0.3)
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: _isHovered ? 1.5 : 1,
                ),
              ),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(14),
                splashColor: socialColor.withValues(alpha: 0.1),
                highlightColor: socialColor.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme),
                      const Spacer(),
                      _buildValueDisplay(theme),
                      const SizedBox(height: 6),
                      _buildProgressBar(theme),
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
          tag: 'social_icon',
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: socialColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.explore, color: socialColor, size: 18),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Social',
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
    final current = widget.log.socialMinutes;
    final goal = widget.config.socialGoalMinutes;
    final percent = (_progress * 100).toInt();

    return Row(
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$current',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: socialColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ $goal min',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getProgressColor(_progress).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$percent%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: _getProgressColor(_progress),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return socialColor;
    if (progress >= 0.4) return Colors.orange;
    return Colors.grey;
  }

  Widget _buildProgressBar(ThemeData theme) {
    return SizedBox(
      height: 24,
      child: Stack(
        children: [
          // Track background - more visible
          Container(
            height: 24,
            decoration: BoxDecoration(
              color: socialColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // Progress fill
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progress.clamp(0.0, 1.0),
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    socialColor,
                    socialColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Small indicator dot at current position (always visible)
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final indicatorSize = 16.0;
              final position = (_progress * (trackWidth - indicatorSize)).clamp(0.0, trackWidth - indicatorSize);
              return Stack(
                children: [
                  Positioned(
                    left: position,
                    top: 4,
                    child: Container(
                      width: indicatorSize,
                      height: indicatorSize,
                      decoration: BoxDecoration(
                        color: socialColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Enhanced exercise card with hover effects.
/// Displays exercise progress and is tappable to open the exercise panel.
class _EnhancedExerciseCard extends StatefulWidget {
  const _EnhancedExerciseCard({
    required this.log,
    required this.config,
    required this.onTap,
  });

  final DailyLog log;
  final UserConfig config;
  final VoidCallback onTap;

  @override
  State<_EnhancedExerciseCard> createState() => _EnhancedExerciseCardState();
}

class _EnhancedExerciseCardState extends State<_EnhancedExerciseCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _hoverController;
  late final Animation<double> _hoverAnimation;

  static const Color exerciseColor = Color(0xFFEF5350);

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

  double get _progress {
    final current = widget.log.exerciseMinutes;
    final goal = widget.config.exerciseGoalMinutes;
    if (goal <= 0) return 0;
    return (current / goal).clamp(0.0, 1.0);
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
              shadowColor: exerciseColor.withValues(alpha: 0.3),
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: _isHovered
                      ? exerciseColor.withValues(alpha: 0.3)
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: _isHovered ? 1.5 : 1,
                ),
              ),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(14),
                splashColor: exerciseColor.withValues(alpha: 0.1),
                highlightColor: exerciseColor.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme),
                      const Spacer(),
                      _buildValueDisplay(theme),
                      const SizedBox(height: 6),
                      _buildProgressBar(theme),
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
          tag: 'exercise_icon',
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: exerciseColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fitness_center, color: exerciseColor, size: 18),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Exercise',
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
    final current = widget.log.exerciseMinutes;
    final goal = widget.config.exerciseGoalMinutes;
    final percent = (_progress * 100).toInt();

    return Row(
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$current',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: exerciseColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ $goal min',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getProgressColor(_progress).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$percent%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: _getProgressColor(_progress),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return exerciseColor;
    if (progress >= 0.4) return Colors.orange;
    return Colors.grey;
  }

  Widget _buildProgressBar(ThemeData theme) {
    return SizedBox(
      height: 24,
      child: Stack(
        children: [
          // Track background - more visible
          Container(
            height: 24,
            decoration: BoxDecoration(
              color: exerciseColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // Progress fill
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progress.clamp(0.0, 1.0),
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    exerciseColor,
                    exerciseColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Small indicator dot at current position (always visible)
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final indicatorSize = 16.0;
              final position = (_progress * (trackWidth - indicatorSize)).clamp(0.0, trackWidth - indicatorSize);
              return Stack(
                children: [
                  Positioned(
                    left: position,
                    top: 4,
                    child: Container(
                      width: indicatorSize,
                      height: indicatorSize,
                      decoration: BoxDecoration(
                        color: exerciseColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
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
                      _buildValueDisplay(theme),
                      const SizedBox(height: 4),
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
              style: theme.textTheme.bodyMedium?.copyWith(
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
              style: theme.textTheme.bodyMedium?.copyWith(
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
      height: 28,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Macro bar
          Expanded(
            child: Container(
              height: 22,
              decoration: BoxDecoration(
                color: macroColor.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _macroProgress,
                child: Container(
                  decoration: const BoxDecoration(
                    color: macroColor,
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(11)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Micro bar
          Expanded(
            child: Container(
              height: 22,
              decoration: BoxDecoration(
                color: microColor.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _microProgress,
                child: Container(
                  decoration: const BoxDecoration(
                    color: microColor,
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(11)),
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
