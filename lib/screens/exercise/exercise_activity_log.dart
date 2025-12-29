import 'package:flutter/material.dart';

import '../../models/exercise_models.dart';

/// Displays the list of logged exercise activities.
class ExerciseActivityLog extends StatelessWidget {
  const ExerciseActivityLog({
    super.key,
    required this.activities,
    required this.onAddActivity,
    required this.onRemoveActivity,
  });

  final List<ExerciseActivity> activities;
  final VoidCallback onAddActivity;
  final void Function(String id) onRemoveActivity;

  static const Color exerciseColor = Color(0xFFEF5350);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Activity Log',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (activities.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: exerciseColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${activities.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: exerciseColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onAddActivity,
              style: FilledButton.styleFrom(
                backgroundColor: exerciseColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Log'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (activities.isEmpty)
          _buildEmptyState(context, theme, colorScheme)
        else
          _buildActivityList(context, theme, colorScheme),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_run,
              size: 32,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No activities logged today',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate a workout above or tap "Log Activity" to track your exercise',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: activities.asMap().entries.map((entry) {
        final index = entry.key;
        final activity = entry.value;
        final isLast = index == activities.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: exerciseColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getActivityIcon(activity.name),
                  color: exerciseColor,
                  size: 20,
                ),
              ),
              title: Text(
                activity.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '${activity.durationMinutes} min • ${_formatTime(activity.timestamp)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: colorScheme.error.withValues(alpha: 0.7),
                  size: 20,
                ),
                onPressed: () => onRemoveActivity(activity.id),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getActivityIcon(String name) {
    final lowercaseName = name.toLowerCase();
    if (lowercaseName.contains('run') || lowercaseName.contains('jog')) {
      return Icons.directions_run;
    }
    if (lowercaseName.contains('walk')) {
      return Icons.directions_walk;
    }
    if (lowercaseName.contains('yoga') || lowercaseName.contains('stretch')) {
      return Icons.self_improvement;
    }
    if (lowercaseName.contains('bike') || lowercaseName.contains('cycl')) {
      return Icons.directions_bike;
    }
    if (lowercaseName.contains('swim')) {
      return Icons.pool;
    }
    if (lowercaseName.contains('hiit') || lowercaseName.contains('cardio')) {
      return Icons.local_fire_department;
    }
    if (lowercaseName.contains('strength') || lowercaseName.contains('weight')) {
      return Icons.fitness_center;
    }
    return Icons.fitness_center;
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

