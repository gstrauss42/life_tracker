import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/data.dart';
import '../models/models.dart';
import 'aggregation_provider.dart';
import 'repository_providers.dart';
import 'date_provider.dart';

/// Provider for the selected date's daily log.
final dailyLogProvider = StateNotifierProvider<DailyLogNotifier, DailyLog>((ref) {
  final repository = ref.watch(dailyLogRepositoryProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  return DailyLogNotifier(repository, selectedDate, ref);
});

/// Provider for multi-day nutrition overview (last 7 days).
final multiDayNutritionProvider = Provider<MultiDayNutritionOverview>((ref) {
  final repository = ref.watch(dailyLogRepositoryProvider);
  // Watch the daily log to trigger updates when food is added
  ref.watch(dailyLogProvider);
  
  final recentLogs = repository.getRecentLogs(7);
  return MultiDayNutritionOverview.fromLogs(recentLogs, lookbackDays: 7);
});

/// Unified notifier for managing daily log state.
class DailyLogNotifier extends StateNotifier<DailyLog> {
  DailyLogNotifier(this._repository, DateTime date, this._ref)
      : _dateKey = DateFormat('yyyy-MM-dd').format(date),
        super(DailyLog(date: DateFormat('yyyy-MM-dd').format(date))) {
    _loadLog();
  }

  final DailyLogRepository _repository;
  final String _dateKey;
  final Ref _ref;

  void _loadLog() {
    final log = _repository.getLog(DateTime.parse(_dateKey));
    state = log?.copyWith() ?? DailyLog(date: _dateKey);
  }

  Future<void> _updateAndSave(DailyLog Function(DailyLog) update, {bool triggerAggregation = true}) async {
    final log = _repository.getOrCreateLog(DateTime.parse(_dateKey));
    final updated = update(log);
    await _repository.save(updated);
    state = updated.copyWith();
    
    // Trigger aggregation recomputation in background
    if (triggerAggregation) {
      triggerAggregationRecompute(_ref);
    }
  }

  // Tracking updates
  Future<void> setWater(double liters) => _updateAndSave((log) {
        log.waterLiters = liters.clamp(0.0, 20.0);
        return log;
      });

  Future<void> setExercise(int minutes) => _updateAndSave((log) {
        log.exerciseMinutes = minutes.clamp(0, 480);
        return log;
      }, triggerAggregation: false); // Exercise provider handles this

  Future<void> setSunlight(int minutes) => _updateAndSave((log) {
        log.sunlightMinutes = minutes.clamp(0, 480);
        return log;
      });

  Future<void> setSleep(double hours) => _updateAndSave((log) {
        log.sleepHours = hours.clamp(0.0, 24.0);
        return log;
      });

  Future<void> setSocial(int minutes) => _updateAndSave((log) {
        log.socialMinutes = minutes.clamp(0, 480);
        return log;
      }, triggerAggregation: false); // Social provider handles this

  // Food operations
  Future<void> addFood(FoodEntry entry) => _updateAndSave((log) {
        log.foodEntries.add(entry);
        return log;
      });

  Future<void> removeFood(String entryId) => _updateAndSave((log) {
        log.foodEntries.removeWhere((e) => e.id == entryId);
        return log;
      });

  // Notes
  Future<void> setNotes(String notes) => _updateAndSave((log) {
        log.notes = notes;
        return log;
      }, triggerAggregation: false); // Notes don't affect aggregates
}
