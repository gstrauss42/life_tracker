import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/data.dart';
import '../models/models.dart';
import '../models/exercise_models.dart';
import '../services/services.dart';
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

  // Location settings
  Future<void> setLocation({
    required String address,
    required String city,
    required String country,
    double? lat,
    double? lng,
  }) async {
    final oldCity = state.locationCity;
    final oldCountry = state.locationCountry;

    await _updateAndSave((c) {
      c.locationAddress = address;
      c.locationCity = city;
      c.locationCountry = country;
      c.locationLat = lat;
      c.locationLng = lng;
      return c;
    });

    // Check if we should refresh categories
    if (shouldRefreshCategories(oldCity, oldCountry, city, country)) {
      await refreshCategoriesForLocation();
    }
  }

  /// Set location from GPS coordinates
  Future<void> setLocationFromCoordinates({
    required double lat,
    required double lng,
    required String address,
    required String city,
    required String country,
  }) async {
    await setLocation(
      address: address,
      city: city,
      country: country,
      lat: lat,
      lng: lng,
    );
  }

  /// Clear location data
  Future<void> clearLocation() => _updateAndSave((c) {
        c.locationAddress = null;
        c.locationCity = null;
        c.locationCountry = null;
        c.locationLat = null;
        c.locationLng = null;
        c.availableCategories = null;
        c.categoriesLastUpdated = null;
        return c;
      });

  /// Refresh available categories for current location
  Future<void> refreshCategoriesForLocation() async {
    if (state.locationCity == null) return;

    final location = '${state.locationCity}, ${state.locationCountry}';
    
    // Use SocialService to filter categories
    final service = SocialService(
      apiKey: state.aiApiKey,
      provider: state.aiProvider,
    );

    try {
      final categories = await service.filterCategoriesForLocation(location);
      await _updateAndSave((c) {
        c.availableCategories = categories.map((cat) => cat.name).toList();
        c.categoriesLastUpdated = DateTime.now();
        return c;
      });
    } catch (e) {
      // On error, keep existing categories or use all
      if (state.availableCategories == null) {
        await _updateAndSave((c) {
          c.availableCategories = SocialCategory.values.map((cat) => cat.name).toList();
          c.categoriesLastUpdated = DateTime.now();
          return c;
        });
      }
    }
  }

  /// Save available categories
  Future<void> setAvailableCategories(List<SocialCategory> categories) => _updateAndSave((c) {
        c.availableCategories = categories.map((cat) => cat.name).toList();
        c.categoriesLastUpdated = DateTime.now();
        return c;
      });

  // Exercise settings
  Future<void> setFitnessGoal(FitnessGoal goal) => _updateAndSave((c) {
        c.fitnessGoalName = goal.name;
        return c;
      });

  Future<void> setFitnessLevel(FitnessLevel level) => _updateAndSave((c) {
        c.fitnessLevelName = level.name;
        return c;
      });

  Future<void> setPreferredWorkoutDuration(int minutes) => _updateAndSave((c) {
        c.preferredWorkoutDuration = minutes;
        return c;
      });
}



