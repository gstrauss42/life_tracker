import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/breakpoints.dart';
import '../../models/exercise_models.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/user_config_provider.dart';
import 'exercise_progress_card.dart';
import 'workout_display.dart';
import 'exercise_activity_log.dart';
import 'log_exercise_dialog.dart';

/// Exercise panel for workout generation and activity logging.
/// Follows the same pattern as SocialPanel.
class ExercisePanel extends ConsumerStatefulWidget {
  const ExercisePanel({
    super.key,
    required this.onClose,
    this.selectedDate,
    this.onNavigateToSettings,
  });

  final VoidCallback onClose;
  final DateTime? selectedDate;
  final VoidCallback? onNavigateToSettings;

  @override
  ConsumerState<ExercisePanel> createState() => _ExercisePanelState();
}

class _ExercisePanelState extends ConsumerState<ExercisePanel> {
  final _requestController = TextEditingController();

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isCompact = Breakpoints.isMobile(width);

    final config = ref.watch(userConfigProvider);
    final progress = ref.watch(exerciseProgressProvider);
    final generatedWorkout = ref.watch(generatedWorkoutProvider);
    final generationState = ref.watch(workoutGenerationProvider);
    final activities = ref.watch(exerciseActivitiesProvider);

    // Check if user has configured their fitness preferences
    final hasConfiguredFitness = config.fitnessLevel != null && config.fitnessGoal != null;

    return Container(
      color: colorScheme.surface,
      child: Column(
        children: [
          _buildHeader(context, theme, colorScheme),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isCompact ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress card
                  ExerciseProgressCard(progress: progress),
                  const SizedBox(height: 24),

                  // Show setup prompt if fitness preferences not configured
                  if (!hasConfiguredFitness)
                    _buildSetupPrompt(context, theme, colorScheme)
                  else if (generatedWorkout != null) ...[
                    // Show workout with integrated regeneration
                    WorkoutDisplay(
                      workout: generatedWorkout,
                      onLogWorkout: () => _logWorkout(generatedWorkout),
                      requestController: _requestController,
                      onRegenerate: _generateWorkout,
                      isGenerating: generationState.isLoading,
                      onEditSettings: () => _openSettings(context),
                      onClear: () => ref.read(generatedWorkoutProvider.notifier).clear(),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    // Show generation section only when no workout exists
                    _buildGenerationSection(context, theme, colorScheme, generationState),
                    const SizedBox(height: 24),
                  ],

                  // Activity log (always show - users can still manually log)
                  ExerciseActivityLog(
                    activities: activities,
                    onAddActivity: () => _showAddActivityDialog(),
                    onRemoveActivity: (id) {
                      ref.read(exerciseActivitiesProvider.notifier).removeActivity(id);
                    },
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final dateText = widget.selectedDate != null ? _formatDate(widget.selectedDate!) : 'Today';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Hero(
            tag: 'exercise_icon',
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEF5350).withValues(alpha: 0.15),
                    const Color(0xFFEF5350).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Color(0xFFEF5350),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exercise',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dateText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPrompt(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFEF5350).withValues(alpha: 0.08),
            const Color(0xFFFF7043).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF5350).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Friendly icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEF5350).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_people,
              color: Color(0xFFEF5350),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),

          // Encouraging title
          Text(
            "Let's personalize your workouts!",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Supportive message
          Text(
            'To create safe and effective workouts tailored just for you, '
            "we need to know a bit about your fitness journey. This helps us "
            'suggest exercises that match your current level and goals.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Benefits list
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildBenefitItem(theme, colorScheme, Icons.check_circle_outline, 
                    'Workouts matched to your fitness level'),
                const SizedBox(height: 8),
                _buildBenefitItem(theme, colorScheme, Icons.check_circle_outline, 
                    'Exercises aligned with your goals'),
                const SizedBox(height: 8),
                _buildBenefitItem(theme, colorScheme, Icons.check_circle_outline, 
                    'Safe progression that respects your body'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openSettings(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF5350),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('Set Up My Fitness Profile'),
            ),
          ),
          const SizedBox(height: 12),

          // Reassuring note
          Text(
            'Takes less than a minute • You can change these anytime',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(ThemeData theme, ColorScheme colorScheme, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.green),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  void _openSettings(BuildContext context) {
    // Use the callback if provided (handles navigation from parent)
    if (widget.onNavigateToSettings != null) {
      widget.onClose();
      widget.onNavigateToSettings!();
    } else {
      // Fallback: just close and show a message
      widget.onClose();
    }
  }

  Widget _buildGenerationSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    AsyncValue<void> state,
  ) {
    // Show loading state
    if (state.isLoading) {
      return _buildLoadingState(context, theme, colorScheme);
    }

    final config = ref.watch(userConfigProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Generate Workout',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        // Show current fitness profile
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 18,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${config.fitnessLevel?.displayName ?? "Beginner"} • ${config.fitnessGoal?.displayName ?? "Stay Active"} • ${config.exerciseGoalMinutes} min',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _openSettings(context),
                child: Text(
                  'Edit',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFEF5350),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Optional request input
        TextField(
          controller: _requestController,
          decoration: InputDecoration(
            hintText: 'Optional: "focus on core", "leg day", "quick stretch"...',
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEF5350),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),

        // Generate button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _generateWorkout,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Generate Workout'),
          ),
        ),

        // Error display
        if (state.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Failed to generate workout. Please check your API key in Settings.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final config = ref.watch(userConfigProvider);
    final userRequest = _requestController.text.trim();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFEF5350).withValues(alpha: 0.08),
            const Color(0xFFFF7043).withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF5350).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Animated icon with spinner
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: const Color(0xFFEF5350).withValues(alpha: 0.3),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF5350).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Color(0xFFEF5350),
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Main text
          Text(
            'Creating your workout...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This may take a few moments',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          
          // Info hints
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEF5350).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: const Color(0xFFEF5350).withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'AI is designing a ${config.fitnessLevel?.displayName.toLowerCase() ?? "beginner"}-level workout',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                if (userRequest.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.format_quote,
                        size: 16,
                        color: const Color(0xFFEF5350).withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Focusing on: "$userRequest"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: const Color(0xFFEF5350).withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Targeting ${config.exerciseGoalMinutes} minutes of exercise',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _generateWorkout() {
    final userRequest = _requestController.text.trim();
    ref.read(workoutGenerationProvider.notifier).generate(
          userRequest: userRequest.isEmpty ? null : userRequest,
        );
  }

  void _logWorkout(GeneratedWorkout workout) {
    // Create an activity from the generated workout
    final activity = ExerciseActivity.create(
      name: workout.title,
      durationMinutes: workout.estimatedMinutes,
      workoutId: workout.id,
    );
    ref.read(exerciseActivitiesProvider.notifier).addActivity(activity);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged "${workout.title}" (${workout.estimatedMinutes} min)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddActivityDialog() {
    showDialog(
      context: context,
      builder: (context) => LogExerciseDialog(
        onSave: (activity) {
          ref.read(exerciseActivitiesProvider.notifier).addActivity(activity);
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

