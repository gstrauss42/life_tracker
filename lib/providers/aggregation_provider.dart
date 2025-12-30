import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/aggregated_data.dart';
import '../services/aggregation_service.dart';
import 'repository_providers.dart';
import 'social_provider.dart';
import 'user_config_provider.dart';

/// Whether aggregates are currently being computed in the background
final _isComputingProvider = StateProvider<bool>((ref) => false);

/// Service instance provider
final _aggregationServiceProvider = Provider<AggregationService>((ref) {
  final dailyLogRepo = ref.watch(dailyLogRepositoryProvider);
  final exerciseRepo = ref.watch(exerciseRepositoryProvider);
  return AggregationService(
    dailyLogRepository: dailyLogRepo,
    exerciseRepository: exerciseRepo,
  );
});

/// Notifier that triggers background recomputation and saves to database
class AggregationNotifier extends Notifier<AggregatedUserData?> {
  @override
  AggregatedUserData? build() {
    // Just read from database - no computation
    final repository = ref.watch(aggregationRepositoryProvider);
    return repository.getAggregates();
  }

  /// Trigger background recomputation of aggregates
  /// This is called when underlying data changes
  Future<void> recompute() async {
    // Don't start if already computing
    if (ref.read(_isComputingProvider)) return;

    ref.read(_isComputingProvider.notifier).state = true;

    try {
      final service = ref.read(_aggregationServiceProvider);
      final userConfig = ref.read(userConfigProvider);
      final socialActivities = ref.read(todaySocialActivitiesProvider);
      final repository = ref.read(aggregationRepositoryProvider);

      // Compute aggregates synchronously (fast enough for 14 days of data)
      // Using Future.delayed(Duration.zero) to yield to the event loop
      await Future.delayed(Duration.zero);
      
      final aggregates = service.computeAggregates(
        days: 14,
        userConfig: userConfig,
        socialActivities: socialActivities,
      );

      // Save to database
      await repository.saveAggregates(aggregates);

      // Update state to notify listeners
      state = aggregates;
    } catch (e) {
      debugPrint('Error computing aggregates: $e');
    } finally {
      ref.read(_isComputingProvider.notifier).state = false;
    }
  }
}

/// Provides aggregated data from the database.
/// Use `ref.read(aggregatedDataProvider.notifier).recompute()` to trigger recomputation.
final aggregatedDataProvider =
    NotifierProvider<AggregationNotifier, AggregatedUserData?>(
  AggregationNotifier.new,
);

/// Whether aggregates are currently being computed
final isComputingAggregatesProvider = Provider<bool>((ref) {
  return ref.watch(_isComputingProvider);
});

/// Trigger aggregation recomputation - call this from notifiers when data changes
void triggerAggregationRecompute(Ref ref) {
  // Use Future.microtask to avoid calling during build
  Future.microtask(() {
    ref.read(aggregatedDataProvider.notifier).recompute();
  });
}

/// Aggregated data for specific time period (for analytics page)
/// This one computes on-demand since it's for a specific period
final aggregatedDataForPeriodProvider = Provider.family<AggregatedUserData, int>((ref, days) {
  final service = ref.watch(_aggregationServiceProvider);
  final userConfig = ref.watch(userConfigProvider);
  final socialActivities = ref.watch(todaySocialActivitiesProvider);

  return service.computeAggregates(
    days: days,
    userConfig: userConfig,
    socialActivities: socialActivities,
  );
});

/// Convenience providers for accessing specific aggregate sections
/// These return empty aggregates if none exist yet
final nutritionAggregatesProvider = Provider<NutritionAggregates>((ref) {
  final data = ref.watch(aggregatedDataProvider);
  return data?.nutrition ?? NutritionAggregates.empty();
});

final exerciseAggregatesProvider = Provider<ExerciseAggregates>((ref) {
  final data = ref.watch(aggregatedDataProvider);
  return data?.exercise ?? ExerciseAggregates.empty();
});

final socialAggregatesProvider = Provider<SocialAggregates>((ref) {
  final data = ref.watch(aggregatedDataProvider);
  return data?.social ?? SocialAggregates.empty();
});

final simpleMetricsAggregatesProvider = Provider<SimpleMetricsAggregates>((ref) {
  final data = ref.watch(aggregatedDataProvider);
  return data?.simpleMetrics ?? SimpleMetricsAggregates.empty();
});

final patternsDataProvider = Provider<PatternData>((ref) {
  final data = ref.watch(aggregatedDataProvider);
  return data?.patterns ?? PatternData.empty();
});
