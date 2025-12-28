import 'package:flutter/material.dart';

import '../../models/models.dart';
import 'nutrient_card.dart';
import 'micro_nutrient_row.dart';

/// Complete nutrition summary section.
class NutritionSummarySection extends StatelessWidget {
  const NutritionSummarySection({
    super.key,
    required this.log,
    required this.config,
  });

  final DailyLog log;
  final UserConfig config;

  // Card sizing constraints
  static const double _minCardWidth = 90;
  static const double _maxCardWidth = 140;
  static const double _cardHeight = 100;
  static const double _spacing = 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nutrition = log.nutritionSummary;
    final rec = NutritionSummary.recommendedDaily;

    final nutrientCards = [
      NutrientCard(
        label: 'Calories',
        current: nutrition.calories,
        goal: config.calorieGoal.toDouble(),
        unit: '',
        color: const Color(0xFFFF6B35),
        icon: Icons.local_fire_department,
      ),
      NutrientCard(
        label: 'Protein',
        current: nutrition.protein,
        goal: config.proteinGoalGrams,
        unit: 'g',
        color: const Color(0xFFE91E63),
        icon: Icons.egg_alt,
      ),
      NutrientCard(
        label: 'Carbs',
        current: nutrition.carbs,
        goal: rec.carbs,
        unit: 'g',
        color: const Color(0xFF2196F3),
        icon: Icons.grain,
      ),
      NutrientCard(
        label: 'Fat',
        current: nutrition.fat,
        goal: rec.fat,
        unit: 'g',
        color: const Color(0xFF9C27B0),
        icon: Icons.opacity,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary macros grid - responsive
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            
            // Calculate optimal number of columns (4 cards, aim for all in one row when possible)
            int columns = (availableWidth / _minCardWidth).floor().clamp(2, 4);
            
            final totalSpacing = (columns - 1) * _spacing;
            final cardWidth = ((availableWidth - totalSpacing) / columns).clamp(_minCardWidth, _maxCardWidth);
            
            final actualTotalWidth = (cardWidth * columns) + totalSpacing;
            final horizontalPadding = (availableWidth - actualTotalWidth) / 2;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding.clamp(0, double.infinity)),
              child: Wrap(
                spacing: _spacing,
                runSpacing: _spacing,
                children: nutrientCards.map((card) {
                  return SizedBox(
                    width: cardWidth,
                    height: _cardHeight,
                    child: card,
                  );
                }).toList(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Micronutrients row - constrained width
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: MicroNutrientRow(
            items: [
              MicroNutrientItem(
                label: 'Fiber',
                current: nutrition.fiber,
                goal: rec.fiber,
                unit: 'g',
                color: const Color(0xFF4CAF50),
              ),
              MicroNutrientItem(
                label: 'Vit C',
                current: nutrition.vitaminC,
                goal: rec.vitaminC,
                unit: 'mg',
                color: const Color(0xFFFF9800),
              ),
              MicroNutrientItem(
                label: 'Iron',
                current: nutrition.iron,
                goal: rec.iron,
                unit: 'mg',
                color: const Color(0xFF795548),
              ),
              MicroNutrientItem(
                label: 'Calcium',
                current: nutrition.calcium,
                goal: rec.calcium,
                unit: 'mg',
                color: const Color(0xFF00BCD4),
              ),
            ],
          ),
        ),
        // Deficiency warnings
        if (log.foodEntries.isNotEmpty && nutrition.getDeficiencies().isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildDeficiencyWarnings(theme, colorScheme, nutrition),
        ],
      ],
    );
  }

  Widget _buildDeficiencyWarnings(ThemeData theme, ColorScheme colorScheme, NutritionSummary nutrition) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: nutrition.getDeficiencies().take(2).map((d) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange.shade400),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Low ${d.name}: ${d.current.toStringAsFixed(0)}/${d.recommended.toStringAsFixed(0)} ${d.unit}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

