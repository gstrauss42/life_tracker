import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/responsive/breakpoints.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../food/enhanced_food_entry_card.dart';
import '../food/add_food_sheet.dart';
import '../nutrition/enhanced_macro_card.dart';
import '../nutrition/expandable_micros_section.dart';
import 'food_suggestions_section.dart';

/// Redesigned Food & Nutrition detail view with responsive layout.
class FoodDetailView extends ConsumerStatefulWidget {
  const FoodDetailView({
    super.key,
    required this.onClose,
    this.selectedDate,
    this.onEditFood,
    this.onDuplicateFood,
  });

  final VoidCallback onClose;
  final DateTime? selectedDate;
  final void Function(FoodEntry entry)? onEditFood;
  final void Function(FoodEntry entry)? onDuplicateFood;

  @override
  ConsumerState<FoodDetailView> createState() => _FoodDetailViewState();
}

class _FoodDetailViewState extends ConsumerState<FoodDetailView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;
    // Watch the providers directly so the UI updates when food is added/deleted
    final log = ref.watch(dailyLogProvider);
    final config = ref.watch(userConfigProvider);

    final padding = Breakpoints.getContentPadding(width);
    
    return Container(
      color: colorScheme.surface,
      child: Column(
        children: [
          _buildHeader(context, theme, colorScheme),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Macros section
                  _buildMacrosGrid(context, theme, log, config),
                  const SizedBox(height: 20),
                  // Micronutrients section
                  ExpandableMicrosSection(nutrition: log.nutritionSummary),
                  const SizedBox(height: 24),
                  // Food suggestions section
                  FoodSuggestionsSection(
                    selectedDate: widget.selectedDate ?? DateTime.now(),
                  ),
                  const SizedBox(height: 24),
                  // Food log section
                  _buildFoodLogSection(context, theme, colorScheme, log),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final dateText = widget.selectedDate != null
        ? _formatDate(widget.selectedDate!)
        : 'Today';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Hero(
            tag: 'food_icon',
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B35).withValues(alpha: 0.15),
                    const Color(0xFFFF6B35).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: Color(0xFFFF6B35),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Food & Nutrition',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dateText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosGrid(BuildContext context, ThemeData theme, DailyLog log, UserConfig config) {
    final nutrition = log.nutritionSummary;
    final rec = NutritionSummary.recommendedDaily;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Guard against invalid constraints (can happen during layout transitions)
        if (width <= 0 || !width.isFinite) {
          return const SizedBox.shrink();
        }
        
        // Responsive column count based on width
        int crossAxisCount;
        if (width < 280) {
          crossAxisCount = 1;
        } else if (width < 400) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 4;
        }
        
        const spacing = 10.0;
        final totalSpacing = (crossAxisCount - 1) * spacing;
        
        // Calculate card dimensions with safety checks
        final cardWidth = ((width - totalSpacing) / crossAxisCount).clamp(80.0, 200.0);
        final cardHeight = (cardWidth * 1.15).clamp(100.0, 180.0);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: EnhancedMacroCard(
                label: 'Calories',
                current: nutrition.calories,
                goal: config.calorieGoal.toDouble(),
                unit: '',
                color: const Color(0xFFFF6B35),
                icon: Icons.local_fire_department,
                isCompact: crossAxisCount >= 4,
              ),
            ),
            SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: EnhancedMacroCard(
                label: 'Protein',
                current: nutrition.protein,
                goal: config.proteinGoalGrams,
                unit: 'g',
                color: const Color(0xFFE91E63),
                icon: Icons.egg_alt,
                isCompact: crossAxisCount >= 4,
              ),
            ),
            SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: EnhancedMacroCard(
                label: 'Carbs',
                current: nutrition.carbs,
                goal: rec.carbs,
                unit: 'g',
                color: const Color(0xFF2196F3),
                icon: Icons.grain,
                isCompact: crossAxisCount >= 4,
              ),
            ),
            SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: EnhancedMacroCard(
                label: 'Fat',
                current: nutrition.fat,
                goal: rec.fat,
                unit: 'g',
                color: const Color(0xFF9C27B0),
                icon: Icons.opacity,
                isCompact: crossAxisCount >= 4,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFoodLogSection(BuildContext context, ThemeData theme, ColorScheme colorScheme, DailyLog log) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Food Log',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            if (log.foodEntries.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${log.foodEntries.length} ${log.foodEntries.length == 1 ? 'item' : 'items'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _showAddFoodSheet(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Food'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (log.foodEntries.isEmpty)
          _buildEmptyState(context, theme, colorScheme)
        else
          _buildFoodList(context, theme, colorScheme, log),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              size: 40,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No food logged today',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "+ Add Food" to track your first meal',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _showAddFoodSheet(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add your first meal'),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList(BuildContext context, ThemeData theme, ColorScheme colorScheme, DailyLog log) {
    return Column(
      children: log.foodEntries.asMap().entries.map((entry) {
        final index = entry.key;
        final food = entry.value;
        final isLast = index == log.foodEntries.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
          child: EnhancedFoodEntryCard(
            entry: food,
            onDelete: () => ref.read(dailyLogProvider.notifier).removeFood(food.id),
            onEdit: widget.onEditFood != null ? () => widget.onEditFood!(food) : null,
            onDuplicate: widget.onDuplicateFood != null ? () => widget.onDuplicateFood!(food) : null,
          ),
        );
      }).toList(),
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
          await _addFoodWithAnalysis(context, mealName, ingredients, description);
        },
      ),
    );
  }

  Future<void> _addFoodWithAnalysis(
    BuildContext context,
    String mealName,
    List<StructuredIngredient> ingredients,
    String description,
  ) async {
    final config = ref.read(userConfigProvider);
    final notifier = ref.read(dailyLogProvider.notifier);
    final selectedDate = widget.selectedDate ?? DateTime.now();

    _showLoadingSnackbar(context, ingredients.length);

    try {
      if (config.aiApiKey != null && config.aiApiKey!.isNotEmpty && ingredients.isNotEmpty) {
        final service = NutritionService(
          apiKey: config.aiApiKey,
          provider: config.aiProvider,
        );

        final result = await service.analyzeStructuredIngredients(
          mealName: mealName,
          ingredients: ingredients,
        );

        final entry = result.toFoodEntry(
          const Uuid().v4(),
          DateTime.now(),
          originalInput: description,
        );

        await notifier.addFood(entry);
        // Clear meal suggestions when food is added
        ref.read(mealSuggestionsProvider.notifier).clearSuggestions(selectedDate);
        _showSuccessSnackbar(context, result.name, result.calories, result.protein);
      } else {
        final entry = FoodEntry(
          id: const Uuid().v4(),
          name: mealName.isNotEmpty ? mealName : description,
          timestamp: DateTime.now(),
          originalInput: description,
        );
        await notifier.addFood(entry);
        // Clear meal suggestions when food is added
        ref.read(mealSuggestionsProvider.notifier).clearSuggestions(selectedDate);
        _showNoApiKeySnackbar(context);
      }
    } catch (e) {
      final entry = FoodEntry(
        id: const Uuid().v4(),
        name: mealName.isNotEmpty ? mealName : description,
        timestamp: DateTime.now(),
        originalInput: description,
      );
      await notifier.addFood(entry);
      // Clear meal suggestions when food is added
      ref.read(mealSuggestionsProvider.notifier).clearSuggestions(selectedDate);
      _showErrorSnackbar(context, e);
    }
  }

  void _showLoadingSnackbar(BuildContext context, int ingredientCount) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Text('Analyzing $ingredientCount ingredient(s)...'),
          ],
        ),
        duration: const Duration(seconds: 30),
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context, String name, double? calories, double? protein) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "$name" - ${calories?.toStringAsFixed(0) ?? "?"} kcal, ${protein?.toStringAsFixed(0) ?? "?"}g protein'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showNoApiKeySnackbar(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added meal (set API key in Settings for nutrition analysis)'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, Object error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added meal (analysis error: $error)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
