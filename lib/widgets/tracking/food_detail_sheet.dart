import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../../services/services.dart';
import '../food/food.dart';
import '../nutrition/nutrition.dart';

/// Bottom sheet showing full nutrition details and food log.
class FoodDetailSheet extends StatelessWidget {
  const FoodDetailSheet({
    super.key,
    required this.log,
    required this.config,
    required this.onAddFood,
    required this.onDeleteFood,
  });

  final DailyLog log;
  final UserConfig config;
  final Future<void> Function(String mealName, List<StructuredIngredient> ingredients, String description) onAddFood;
  final void Function(String foodId) onDeleteFood;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: Color(0xFFFF6B35),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Food & Nutrition',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nutrition summary
                  NutritionSummarySection(log: log, config: config),
                  const SizedBox(height: 24),
                  // Food log header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Food Log',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _showAddFoodSheet(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Food entries list
                  FoodLogList(
                    entries: log.foodEntries,
                    onDeleteEntry: onDeleteFood,
                  ),
                  // Extra padding at bottom for safe area
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFoodSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AddFoodSheet(
        onSubmit: (mealName, ingredients, description) async {
          Navigator.pop(sheetContext);
          await onAddFood(mealName, ingredients, description);
        },
      ),
    );
  }
}

