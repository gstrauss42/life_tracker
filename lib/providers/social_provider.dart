import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../services/services.dart';
import 'user_config_provider.dart';
import 'daily_log_provider.dart';

/// Provider for the SocialService
final socialServiceProvider = Provider<SocialService>((ref) {
  final config = ref.watch(userConfigProvider);
  return SocialService(
    apiKey: config.aiApiKey,
    provider: config.aiProvider,
  );
});

/// Provider for available categories based on current location
/// Returns cached categories if available, otherwise filters all categories
final availableCategoriesProvider = FutureProvider<List<SocialCategory>>((ref) async {
  final config = ref.watch(userConfigProvider);

  // Return cached if available
  if (config.availableCategories != null && config.availableCategories!.isNotEmpty) {
    return config.availableCategories!
        .map((name) => SocialCategory.values.firstWhere(
              (c) => c.name == name,
              orElse: () => SocialCategory.restaurants,
            ))
        .toList();
  }

  // Show all categories if no location set
  if (config.locationCity == null) {
    return SocialCategory.values.toList();
  }

  // Filter categories for location
  final service = ref.read(socialServiceProvider);
  final location = '${config.locationCity}, ${config.locationCountry}';
  return service.filterCategoriesForLocation(location);
});

/// Provider for discovering places in a specific category
final discoveredPlacesProvider =
    FutureProvider.family<List<DiscoveredPlace>, SocialCategory>((ref, category) async {
  final config = ref.watch(userConfigProvider);
  if (config.locationCity == null) return [];

  final service = ref.read(socialServiceProvider);
  final location = '${config.locationCity}, ${config.locationCountry}';

  return service.discoverPlaces(location: location, category: category);
});

/// Provider for discovering places with a custom freeform query
final discoveredPlacesByQueryProvider =
    FutureProvider.family<List<DiscoveredPlace>, String>((ref, query) async {
  final config = ref.watch(userConfigProvider);
  if (config.locationCity == null) return [];
  if (query.trim().isEmpty) return [];

  final service = ref.read(socialServiceProvider);
  final location = '${config.locationCity}, ${config.locationCountry}';

  return service.discoverPlacesWithQuery(location: location, query: query);
});

/// Provider for discovering events in a specific category
final discoveredEventsProvider =
    FutureProvider.family<List<DiscoveredEvent>, SocialCategory>((ref, category) async {
  final config = ref.watch(userConfigProvider);
  if (config.locationCity == null) return [];

  final service = ref.read(socialServiceProvider);
  final location = '${config.locationCity}, ${config.locationCountry}';

  return service.discoverEvents(location: location, category: category);
});

/// State notifier for managing social activities
class SocialActivitiesNotifier extends StateNotifier<List<SocialActivity>> {
  SocialActivitiesNotifier(this.ref) : super([]) {
    _loadActivities();
  }

  final Ref ref;

  void _loadActivities() {
    // Social activities are tied to the daily log's socialMinutes
    // For now, we'll maintain a separate in-memory list
    // In a full implementation, this would be persisted to Hive
  }

  /// Add a new social activity
  void addActivity(SocialActivity activity) {
    state = [...state, activity];
    _updateDailyLog();
  }

  /// Remove an activity by ID
  void removeActivity(String id) {
    state = state.where((a) => a.id != id).toList();
    _updateDailyLog();
  }

  /// Update an existing activity
  void updateActivity(SocialActivity activity) {
    state = state.map((a) => a.id == activity.id ? activity : a).toList();
    _updateDailyLog();
  }

  /// Clear all activities for today
  void clearActivities() {
    state = [];
    _updateDailyLog();
  }

  /// Update the daily log with total social minutes
  void _updateDailyLog() {
    final totalMinutes = state.fold<int>(0, (sum, a) => sum + (a.durationMinutes ?? 0));
    ref.read(dailyLogProvider.notifier).setSocial(totalMinutes);
  }

  /// Create a quick activity from a discovered place
  SocialActivity createFromPlace({
    required DiscoveredPlace place,
    required int durationMinutes,
    String? notes,
  }) {
    final activity = SocialActivity(
      id: const Uuid().v4(),
      name: place.name,
      category: place.category,
      timestamp: DateTime.now(),
      durationMinutes: durationMinutes,
      notes: notes,
      placeId: place.id,
    );
    addActivity(activity);
    return activity;
  }

  /// Create a custom activity
  SocialActivity createCustomActivity({
    required String name,
    required SocialCategory category,
    required int durationMinutes,
    String? notes,
    DateTime? timestamp,
  }) {
    final activity = SocialActivity(
      id: const Uuid().v4(),
      name: name,
      category: category,
      timestamp: timestamp ?? DateTime.now(),
      durationMinutes: durationMinutes,
      notes: notes,
    );
    addActivity(activity);
    return activity;
  }
}

/// Provider for today's social activities
final todaySocialActivitiesProvider =
    StateNotifierProvider<SocialActivitiesNotifier, List<SocialActivity>>((ref) {
  return SocialActivitiesNotifier(ref);
});

/// Provider for social progress (aggregate of logged activities)
final socialProgressProvider = Provider<SocialProgress>((ref) {
  final activities = ref.watch(todaySocialActivitiesProvider);
  final config = ref.watch(userConfigProvider);
  final log = ref.watch(dailyLogProvider);
  final goalMinutes = config.socialGoalMinutes;

  // Use the daily log's social minutes as the source of truth
  // but also count activities
  final totalMinutes = log.socialMinutes;

  return SocialProgress(
    totalMinutes: totalMinutes,
    goalMinutes: goalMinutes,
    activityCount: activities.length,
  );
});

/// Selected category for viewing places
final selectedSocialCategoryProvider = StateProvider<SocialCategory?>((ref) => null);

/// Loading state for category filtering
final isCategoryFilteringProvider = StateProvider<bool>((ref) => false);

/// Loading state for place discovery
final isDiscoveringPlacesProvider = StateProvider<bool>((ref) => false);

