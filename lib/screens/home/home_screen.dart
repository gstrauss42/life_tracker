import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';

/// Daily tracking screen - main view for entering and viewing today's data.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedDate = ref.watch(selectedDateProvider);
    final isToday = ref.watch(selectedDateProvider.notifier).isToday;
    final log = ref.watch(dailyLogProvider);
    final config = ref.watch(userConfigProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DateHeader(
              date: selectedDate,
              isToday: isToday,
              onPreviousDay: () => ref.read(selectedDateProvider.notifier).previousDay(),
              onNextDay: isToday ? null : () => ref.read(selectedDateProvider.notifier).nextDay(),
              onDatePicked: (date) => ref.read(selectedDateProvider.notifier).setDate(date),
            ),
            const SizedBox(height: 24),

            const SectionHeader(title: 'Overview'),
            const SizedBox(height: 6),
            Text(
              'Tap any card for detailed tracking and insights',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            TrackingGrid(
              log: log,
              config: config,
              onMetricChanged: (metric, value) => _handleMetricChange(ref, metric, value),
              onFoodTap: () => _showFoodDetailSheet(context, ref, log, config),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMetricChange(WidgetRef ref, TrackingMetric metric, double value) {
    final notifier = ref.read(dailyLogProvider.notifier);
    
    switch (metric.title) {
      case 'Water':
        notifier.setWater(value);
      case 'Exercise':
        notifier.setExercise(value.toInt());
      case 'Sunlight':
        notifier.setSunlight(value.toInt());
      case 'Sleep':
        notifier.setSleep(value);
      case 'Social':
        notifier.setSocial(value.toInt());
    }
  }

  void _showFoodDetailSheet(BuildContext context, WidgetRef ref, DailyLog log, UserConfig config) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (sheetContext) => FoodDetailSheet(
        log: log,
        config: config,
        onAddFood: (mealName, ingredients, description) async {
          await _addFoodWithAnalysis(context, ref, mealName, ingredients, description);
        },
        onDeleteFood: (id) => ref.read(dailyLogProvider.notifier).removeFood(id),
      ),
    );
  }

  Future<void> _addFoodWithAnalysis(
    BuildContext context,
    WidgetRef ref,
    String mealName,
    List<StructuredIngredient> ingredients,
    String description,
  ) async {
    final config = ref.read(userConfigProvider);
    final notifier = ref.read(dailyLogProvider.notifier);

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
        _showSuccessSnackbar(context, result.name, result.calories, result.protein);
      } else {
        final entry = FoodEntry(
          id: const Uuid().v4(),
          name: mealName.isNotEmpty ? mealName : description,
          timestamp: DateTime.now(),
          originalInput: description,
        );
        await notifier.addFood(entry);
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
}
