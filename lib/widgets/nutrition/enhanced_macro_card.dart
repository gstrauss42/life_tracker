import 'package:flutter/material.dart';

/// Enhanced macro card with progress toward daily goals.
class EnhancedMacroCard extends StatelessWidget {
  const EnhancedMacroCard({
    super.key,
    required this.label,
    required this.current,
    required this.goal,
    required this.unit,
    required this.color,
    required this.icon,
    this.isCompact = false,
  });

  final String label;
  final double current;
  final double goal;
  final String unit;
  final Color color;
  final IconData icon;
  final bool isCompact;

  double get _percentage => goal > 0 ? (current / goal).clamp(0.0, 1.5) : 0.0;
  bool get _isOverGoal => current > goal && goal > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Guard against invalid constraints
        if (constraints.maxWidth <= 0 || !constraints.maxWidth.isFinite) {
          return const SizedBox.shrink();
        }
        
        // Determine if we need compact mode based on available space
        final useCompact = isCompact || constraints.maxWidth < 120;
        final padding = useCompact ? 10.0 : 14.0;

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.12),
                color.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, size: 14, color: color),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${(_percentage * 100).toInt()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        current.toStringAsFixed(0),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        unit,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'of ${goal.toStringAsFixed(0)}$unit goal',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              _buildProgressBar(theme),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor() {
    if (_isOverGoal) return Colors.orange;
    if (_percentage >= 0.9) return Colors.green;
    if (_percentage >= 0.7) return color;
    return Colors.grey;
  }

  Widget _buildProgressBar(ThemeData theme) {
    return Stack(
      children: [
        // Background track
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        // Progress fill (capped at 100% for display)
        FractionallySizedBox(
          widthFactor: _percentage.clamp(0.0, 1.0),
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isOverGoal
                    ? [color, Colors.orange]
                    : [color, color.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        // Overflow indicator
        if (_isOverGoal)
          Positioned(
            right: 0,
            child: Container(
              width: 12,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    );
  }
}



