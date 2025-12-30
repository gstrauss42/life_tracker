import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Header showing date with navigation controls.
class DateHeader extends StatelessWidget {
  const DateHeader({
    super.key,
    required this.date,
    required this.isToday,
    required this.onDatePicked,
    this.showGreeting = true,
    this.compactMode = false,
  });

  final DateTime date;
  final bool isToday;
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
      return _buildCompactDateSelector(context, theme, colorScheme, screenWidth);
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
              // Clickable date with dropdown caret
              _buildClickableDate(context, theme, colorScheme, screenWidth),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Today button on the right
        if (!isToday) _buildTodayButton(context, theme, colorScheme, screenWidth),
      ],
    );
  }

  /// Builds the compact date selector for mobile (date on left, today button on right)
  Widget _buildCompactDateSelector(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    double screenWidth,
  ) {
    return Row(
      children: [
        // Clickable date with dropdown caret
        _buildClickableDate(context, theme, colorScheme, screenWidth),
        const Spacer(),
        // Today button
        if (!isToday) _buildTodayButton(context, theme, colorScheme, screenWidth),
      ],
    );
  }

  /// Builds the clickable date text with dropdown caret
  Widget _buildClickableDate(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    double screenWidth,
  ) {
    return InkWell(
      onTap: () => _showDatePicker(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getDateText(screenWidth),
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the Today button - collapses to icon-only at extremely narrow widths
  Widget _buildTodayButton(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    double screenWidth,
  ) {
    // Only collapse at extremely narrow widths (< 240px) where overflow is likely
    final showTextLabel = screenWidth >= 240;
    
    return FilledButton.tonal(
      onPressed: () => onDatePicked(DateTime.now()),
      style: FilledButton.styleFrom(
        padding: showTextLabel
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.all(8),
        minimumSize: showTextLabel ? const Size(80, 36) : const Size(36, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      child: showTextLabel
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 6),
                Text(
                  'Today',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            )
          : Icon(
              Icons.refresh_rounded,
              size: 18,
              color: colorScheme.onPrimaryContainer,
            ),
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
