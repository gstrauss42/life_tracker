import 'package:flutter/material.dart';

import '../../models/exercise_models.dart';

/// Card showing exercise progress for the day.
class ExerciseProgressCard extends StatelessWidget {
  const ExerciseProgressCard({
    super.key,
    required this.progress,
  });

  final ExerciseProgress progress;

  static const Color exerciseColor = Color(0xFFEF5350);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Guard against very narrow constraints (e.g., during panel animations)
        if (constraints.maxWidth < 100) {
          return const SizedBox.shrink();
        }
        
        final isCompact = constraints.maxWidth < 200;
        
        return Container(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                exerciseColor.withValues(alpha: 0.15),
                exerciseColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: exerciseColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: exerciseColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_fire_department,
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
                          "Today's Progress",
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (progress.activityCount > 0)
                          Text(
                            '${progress.activityCount} ${progress.activityCount == 1 ? 'activity' : 'activities'} logged',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Percentage badge - hide on very compact
                  if (!isCompact)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getProgressColor(progress.percentage).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${progress.percentComplete}%',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: _getProgressColor(progress.percentage),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
          const SizedBox(height: 16),

          // Progress bar
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: exerciseColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.percentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        exerciseColor,
                        exerciseColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Minutes display
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${progress.totalMinutes}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: exerciseColor,
                      ),
                    ),
                    TextSpan(
                      text: '/${progress.goalMinutes}m',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (progress.goalReached)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 12),
                      SizedBox(width: 3),
                      Text(
                        'Done!',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  '${progress.remainingMinutes}m left',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
      },
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return exerciseColor;
    if (progress >= 0.4) return Colors.orange;
    return Colors.grey;
  }
}

