import 'dart:io' show Platform, Process;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/exercise_models.dart';
import '../../providers/exercise_provider.dart';

/// Displays a generated workout with exercises.
class WorkoutDisplay extends ConsumerWidget {
  const WorkoutDisplay({
    super.key,
    required this.workout,
    this.onLogWorkout,
    this.requestController,
    this.onRegenerate,
    this.isGenerating = false,
    this.onEditSettings,
    this.onClear,
  });

  final GeneratedWorkout workout;
  final VoidCallback? onLogWorkout;
  final TextEditingController? requestController;
  final VoidCallback? onRegenerate;
  final bool isGenerating;
  final VoidCallback? onEditSettings;
  final VoidCallback? onClear;

  static const Color exerciseColor = Color(0xFFEF5350);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCollapsed = ref.watch(workoutCollapsedProvider);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - always visible, tappable to expand/collapse
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ref.read(workoutCollapsedProvider.notifier).state = !isCollapsed;
              },
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(16),
                bottom: isCollapsed ? const Radius.circular(16) : Radius.zero,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: exerciseColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.flash_on,
                        color: exerciseColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workout.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: isCollapsed ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${workout.estimatedMinutes}m • ${workout.exercises.length} exercises',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Clear button
                    if (onClear != null)
                      IconButton(
                        onPressed: onClear,
                        icon: Icon(
                          Icons.close,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                          size: 20,
                        ),
                        tooltip: 'Dismiss workout',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    // Collapse/expand indicator
                    AnimatedRotation(
                      turns: isCollapsed ? 0 : 0.5,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Collapsible content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(context, theme, colorScheme),
            crossFadeState: isCollapsed ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          height: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),

        // Exercise list
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hint for tapping exercises
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 14,
                      color: colorScheme.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tap any exercise for instructions',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Warmup section
              if (workout.warmupExercises.isNotEmpty) ...[
                _buildSectionHeader(theme, colorScheme, 'Warm Up', Icons.sunny, Colors.orange),
                const SizedBox(height: 8),
                ...workout.warmupExercises.map((e) => _buildExerciseItem(theme, colorScheme, e)),
                const SizedBox(height: 16),
              ],

              // Main exercises
              if (workout.mainExercises.isNotEmpty) ...[
                _buildSectionHeader(theme, colorScheme, 'Workout', Icons.fitness_center, exerciseColor),
                const SizedBox(height: 8),
                ...workout.mainExercises.map((e) => _buildExerciseItem(theme, colorScheme, e)),
                const SizedBox(height: 16),
              ],

              // Cooldown section
              if (workout.cooldownExercises.isNotEmpty) ...[
                _buildSectionHeader(theme, colorScheme, 'Cool Down', Icons.self_improvement, Colors.teal),
                const SizedBox(height: 8),
                ...workout.cooldownExercises.map((e) => _buildExerciseItem(theme, colorScheme, e)),
              ],
            ],
          ),
        ),

        // Log workout button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onLogWorkout,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Mark as Completed'),
            ),
          ),
        ),

        // Regeneration section
        if (requestController != null && onRegenerate != null)
          _buildRegenerationSection(context, theme, colorScheme),
      ],
    );
  }

  Widget _buildRegenerationSection(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    // Show a nice loading state when regenerating
    if (isGenerating) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                exerciseColor.withValues(alpha: 0.08),
                exerciseColor.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: exerciseColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              // Animated spinner with icon
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: exerciseColor.withValues(alpha: 0.4),
                    ),
                  ),
                  Icon(
                    Icons.fitness_center,
                    color: exerciseColor,
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Creating new workout...',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tailoring exercises just for you',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.refresh,
                  size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  'Want a different workout?',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (onEditSettings != null) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: onEditSettings,
                    child: Text(
                      'Edit Profile',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: exerciseColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: requestController,
              style: theme.textTheme.bodySmall,
              decoration: InputDecoration(
                hintText: 'e.g., "more cardio", "upper body only"...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: exerciseColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRegenerate,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(
                    color: exerciseColor.withValues(alpha: 0.5),
                  ),
                  foregroundColor: exerciseColor,
                ),
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Generate New Workout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    String title,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseItem(
    ThemeData theme,
    ColorScheme colorScheme,
    WorkoutExercise exercise,
  ) {
    return _ExpandableExerciseItem(
      exercise: exercise,
      exerciseColor: exerciseColor,
    );
  }
}

/// Expandable exercise item that shows step-by-step instructions when tapped
class _ExpandableExerciseItem extends StatefulWidget {
  const _ExpandableExerciseItem({
    required this.exercise,
    required this.exerciseColor,
  });

  final WorkoutExercise exercise;
  final Color exerciseColor;

  @override
  State<_ExpandableExerciseItem> createState() => _ExpandableExerciseItemState();
}

class _ExpandableExerciseItemState extends State<_ExpandableExerciseItem>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Color get _dotColor {
    if (widget.exercise.isWarmup) return Colors.orange;
    if (widget.exercise.isCooldown) return Colors.teal;
    return widget.exerciseColor;
  }

  Future<void> _openYouTube() async {
    final url = widget.exercise.youtubeSearchUrl;
    
    try {
      // On Linux, use xdg-open directly for better compatibility
      if (Platform.isLinux) {
        final result = await Process.run('xdg-open', [url]);
        if (result.exitCode != 0 && mounted) {
          _showYouTubeFallback();
        }
      } else {
        // Use url_launcher for other platforms
        final uri = Uri.parse(url);
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && mounted) {
          _showYouTubeFallback();
        }
      }
    } catch (e) {
      if (mounted) {
        _showYouTubeFallback();
      }
    }
  }

  void _showYouTubeFallback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Search YouTube for: "how to do ${widget.exercise.name}"'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Copy URL',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.exercise.youtubeSearchUrl));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('URL copied to clipboard'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasInstructions = widget.exercise.hasInstructions;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasInstructions ? _toggle : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isExpanded
                    ? _dotColor.withValues(alpha: 0.4)
                    : colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                // Main row (always visible)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.exercise.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (widget.exercise.reps != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.exercise.reps!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (hasInstructions) ...[
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            size: 20,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Expandable instructions
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _dotColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _dotColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Icon(
                                Icons.format_list_numbered,
                                size: 14,
                                color: _dotColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Step-by-step instructions',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: _dotColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Numbered steps
                          ...widget.exercise.steps.asMap().entries.map((entry) {
                            final index = entry.key + 1;
                            final step = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Step number circle
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: _dotColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$index',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: _dotColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Step text
                                  Expanded(
                                    child: Text(
                                      step,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface.withValues(alpha: 0.85),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          
                          const SizedBox(height: 8),
                          
                          // YouTube button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _openYouTube,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFFF0000),
                                side: BorderSide(
                                  color: const Color(0xFFFF0000).withValues(alpha: 0.3),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.play_circle_fill, size: 18),
                              label: const Text('Watch on YouTube'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

