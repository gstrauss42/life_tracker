import 'package:flutter/material.dart';

import '../../models/models.dart';

/// Card displaying a single food entry.
class FoodEntryCard extends StatelessWidget {
  const FoodEntryCard({
    super.key,
    required this.entry,
    required this.onDelete,
  });

  final FoodEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasOriginalInput = entry.originalInput != null &&
        entry.originalInput!.isNotEmpty &&
        entry.originalInput != entry.name;

    final nutritionText = _buildNutritionText();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(colorScheme),
            const SizedBox(width: 12),
            Expanded(
              child: _buildContent(theme, colorScheme, hasOriginalInput, nutritionText),
            ),
            _buildDeleteButton(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.15),
            colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.restaurant_rounded,
        color: colorScheme.primary,
        size: 20,
      ),
    );
  }

  Widget _buildContent(
    ThemeData theme,
    ColorScheme colorScheme,
    bool hasOriginalInput,
    String nutritionText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (hasOriginalInput) ...[
          const SizedBox(height: 3),
          Text(
            entry.originalInput!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.3,
            ),
          ),
        ],
        if (nutritionText.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            nutritionText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.primary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDeleteButton(ColorScheme colorScheme) {
    return IconButton(
      icon: Icon(
        Icons.delete_outline_rounded,
        color: colorScheme.onSurface.withValues(alpha: 0.4),
        size: 20,
      ),
      onPressed: onDelete,
      tooltip: 'Remove',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  String _buildNutritionText() {
    final parts = <String>[];
    if (entry.calories != null) parts.add('${entry.calories!.toInt()} kcal');
    if (entry.protein != null) parts.add('${entry.protein!.toInt()}g P');
    if (entry.carbs != null) parts.add('${entry.carbs!.toInt()}g C');
    if (entry.fat != null) parts.add('${entry.fat!.toInt()}g F');
    return parts.join(' · ');
  }
}

