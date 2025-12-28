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
  });

  final DateTime date;
  final bool isToday;
  final VoidCallback onPreviousDay;
  final VoidCallback? onNextDay;
  final void Function(DateTime) onDatePicked;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isToday ? 'Good $_greeting' : DateFormat('EEEE').format(date),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMMM d, yyyy').format(date),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        _buildDateNavigation(context),
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

