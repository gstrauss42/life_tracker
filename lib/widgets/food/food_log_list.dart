import 'package:flutter/material.dart';

import '../../models/models.dart';
import 'food_entry_card.dart';

/// List of food entries or empty state.
class FoodLogList extends StatelessWidget {
  const FoodLogList({
    super.key,
    required this.entries,
    required this.onDeleteEntry,
  });

  final List<FoodEntry> entries;
  final void Function(String entryId) onDeleteEntry;

  // Constrain max width for better desktop experience
  static const double _maxWidth = 600;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _buildEmptyState(context);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxWidth),
      child: Column(
        children: entries.asMap().entries.map((entry) {
          final index = entry.key;
          final food = entry.value;
          final isLast = index == entries.length - 1;

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
            child: FoodEntryCard(
              entry: food,
              onDelete: () => onDeleteEntry(food.id),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxWidth),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
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
                Icons.restaurant_menu_rounded,
                size: 32,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No food logged today',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap "Add Food" to track your meals',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

