import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/data.dart';
import '../models/models.dart';
import 'repository_providers.dart';

/// Provider for user configuration.
final userConfigProvider = StateNotifierProvider<UserConfigNotifier, UserConfig>((ref) {
  final repository = ref.watch(userConfigRepositoryProvider);
  return UserConfigNotifier(repository);
});

/// Notifier for managing user configuration.
class UserConfigNotifier extends StateNotifier<UserConfig> {
  UserConfigNotifier(this._repository) : super(UserConfig()) {
    load();
  }

  final UserConfigRepository _repository;

  void load() => state = _repository.getConfig();

  Future<void> _updateAndSave(UserConfig Function(UserConfig) update) async {
    final config = _repository.getConfig();
    final updated = update(config);
    await _repository.save(updated);
    state = updated.copyWith();
  }

  // Goals
  Future<void> setWaterGoal(double liters) => _updateAndSave((c) {
        c.waterGoalLiters = liters;
        return c;
      });

  Future<void> setExerciseGoal(int minutes) => _updateAndSave((c) {
        c.exerciseGoalMinutes = minutes;
        return c;
      });

  Future<void> setSunlightGoal(int minutes) => _updateAndSave((c) {
        c.sunlightGoalMinutes = minutes;
        return c;
      });

  Future<void> setSleepGoal(double hours) => _updateAndSave((c) {
        c.sleepGoalHours = hours;
        return c;
      });

  Future<void> setSocialGoal(int minutes) => _updateAndSave((c) {
        c.socialGoalMinutes = minutes;
        return c;
      });

  // AI settings
  Future<void> setAiApiKey(String key) => _updateAndSave((c) {
        c.aiApiKey = key;
        return c;
      });

  Future<void> setAiProvider(String provider) => _updateAndSave((c) {
        c.aiProvider = provider;
        return c;
      });
}

