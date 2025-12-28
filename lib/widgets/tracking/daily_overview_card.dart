import 'package:flutter/material.dart';

/// Card showing overall daily progress.
class DailyOverviewCard extends StatelessWidget {
  const DailyOverviewCard({
    super.key,
    required this.progress,
  });

  final double progress;

  String get _message {
    final percentage = (progress * 100).toInt();
    if (percentage == 0) return 'Start tracking to see your progress!';
    if (percentage < 25) return 'Just getting started - keep going!';
    if (percentage < 50) return 'Nice progress! You\'re on your way.';
    if (percentage < 75) return 'Great job! Over halfway there.';
    if (percentage < 100) return 'Almost there! Keep it up!';
    return '🎉 Amazing! All goals completed!';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percentage = (progress * 100).toInt();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer,
              colorScheme.primaryContainer.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Overview',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            _buildProgressRing(theme, colorScheme, percentage),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRing(ThemeData theme, ColorScheme colorScheme, int percentage) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimaryContainer),
          ),
          Text(
            '$percentage%',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

