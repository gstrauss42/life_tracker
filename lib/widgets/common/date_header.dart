import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Header showing date with navigation controls.
class DateHeader extends StatelessWidget {
  const DateHeader({
    super.key,
    required this.date,
    required this.isToday,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onDatePicked,
    this.showGreeting = true,
    this.compactMode = false,
  });

  final DateTime date;
  final bool isToday;
  final VoidCallback onPreviousDay;
  final VoidCallback? onNextDay;
  final void Function(DateTime) onDatePicked;
  /// Whether to show greeting text (e.g., "Good Morning")
  final bool showGreeting;
  /// Whether to use compact layout for narrow screens
  final bool compactMode;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
  
  /// Get adaptive date format based on available width
  String _getDateText(double width) {
    // Very narrow: "Tue, Dec 30"
    if (width < 360) {
      return DateFormat('EEE, MMM d').format(date);
    }
    // Narrow: "Tuesday, Dec 30"
    if (width < 480) {
      return DateFormat('EEEE, MMM d').format(date);
    }
    // Normal: "Tuesday, December 30"
    return DateFormat('EEEE, MMMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // Use compact vertical layout for mobile
    if (compactMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date text - adaptive format based on width
          Text(
            _getDateText(screenWidth),
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Navigation row - centered
          _buildCompactNavigation(context, theme, colorScheme),
        ],
      );
    }

    // Desktop/tablet layout
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showGreeting)
                // Use FittedBox to scale greeting if needed, never truncate
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isToday ? 'Good $_greeting' : DateFormat('EEEE').format(date),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (showGreeting) const SizedBox(height: 4),
              Text(
                screenWidth < 900 
                    ? DateFormat('MMM d, yyyy').format(date)
                    : DateFormat('MMMM d, yyyy').format(date),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildDateNavigation(context),
      ],
    );
  }

  Widget _buildCompactNavigation(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        // Previous button
        _CompactNavButton(
          icon: Icons.chevron_left,
          onPressed: onPreviousDay,
          tooltip: 'Previous day',
        ),
        const SizedBox(width: 8),
        // Today/Date button - takes available space
        Expanded(
          child: FilledButton.tonal(
            onPressed: () => _showDatePicker(context),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              isToday ? 'Today' : DateFormat('MMM d').format(date),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Next button
        _CompactNavButton(
          icon: Icons.chevron_right,
          onPressed: onNextDay,
          tooltip: 'Next day',
          enabled: onNextDay != null,
        ),
      ],
    );
  }

  Widget _buildDateNavigation(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPreviousDay,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous day',
        ),
        FilledButton.tonal(
          onPressed: () => _showDatePicker(context),
          child: Text(isToday ? 'Today' : DateFormat('MMM d').format(date)),
        ),
        IconButton(
          onPressed: onNextDay,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next day',
        ),
      ],
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      onDatePicked(picked);
    }
  }
}

/// Compact navigation button for mobile layout
class _CompactNavButton extends StatelessWidget {
  const _CompactNavButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled 
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 24,
              color: enabled 
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

