import 'package:flutter/material.dart';

import '../../models/models.dart';

/// A tappable card showing nutrition progress with two progress bars.
/// Styled to match the other tracking cards.
class NutritionScoreCard extends StatelessWidget {
  const NutritionScoreCard({
    super.key,
    required this.log,
    required this.config,
    required this.onTap,
  });

  final DailyLog log;
  final UserConfig config;
  final VoidCallback onTap;

  static const Color macroColor = Color(0xFFFF6B35);
  static const Color microColor = Color(0xFF26A69A);

  /// Calculate macro progress (calories, protein, carbs, fat)
  double get _macroProgress {
    final nutrition = log.nutritionSummary;
    if (log.foodEntries.isEmpty) return 0;

    final rec = NutritionSummary.recommendedDaily;
    
    final calorieProgress = (nutrition.calories / config.calorieGoal).clamp(0.0, 1.0);
    final proteinProgress = (nutrition.protein / config.proteinGoalGrams).clamp(0.0, 1.0);
    final carbsProgress = (nutrition.carbs / rec.carbs).clamp(0.0, 1.0);
    final fatProgress = (nutrition.fat / rec.fat).clamp(0.0, 1.0);
    
    return (calorieProgress + proteinProgress + carbsProgress + fatProgress) / 4;
  }

  /// Calculate micro progress (vitamins, minerals)
  double get _microProgress {
    final nutrition = log.nutritionSummary;
    if (log.foodEntries.isEmpty) return 0;

    final rec = NutritionSummary.recommendedDaily;
    
    final fiberProgress = (nutrition.fiber / rec.fiber).clamp(0.0, 1.0);
    final vitaminCProgress = (nutrition.vitaminC / rec.vitaminC).clamp(0.0, 1.0);
    final calciumProgress = (nutrition.calcium / rec.calcium).clamp(0.0, 1.0);
    final ironProgress = (nutrition.iron / rec.iron).clamp(0.0, 1.0);
    
    return (fiberProgress + vitaminCProgress + calciumProgress + ironProgress) / 4;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                const Spacer(),
                Text(
                  'Nutrients',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 2),
                _buildValueDisplay(theme),
                const SizedBox(height: 6),
                _buildDualProgressBar(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: macroColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.restaurant_menu, color: macroColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          'Food',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildValueDisplay(ThemeData theme) {
    final macroPercent = (_macroProgress * 100).toInt();
    final microPercent = (_microProgress * 100).toInt();
    
    return Row(
      children: [
        Text(
          'Macro $macroPercent%',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: macroColor,
          ),
        ),
        const Spacer(),
        Text(
          'Micro $microPercent%',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: microColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDualProgressBar(ThemeData theme) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Macro bar
          Expanded(
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                color: macroColor.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _macroProgress,
                child: Container(
                  decoration: BoxDecoration(
                    color: macroColor,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Micro bar
          Expanded(
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                color: microColor.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _microProgress,
                child: Container(
                  decoration: BoxDecoration(
                    color: microColor,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
