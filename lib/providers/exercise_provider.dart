import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/exercise_repository.dart';
import '../models/exercise_models.dart';
import '../services/exercise_service.dart';
import 'repository_providers.dart';
import 'user_config_provider.dart';
import 'daily_log_provider.dart';

/// Service provider
final exerciseServiceProvider = Provider<ExerciseService>((ref) {
  final config = ref.watch(userConfigProvider);
  return ExerciseService(
    apiKey: config.aiApiKey,
    provider: config.aiProvider,
  );
});

/// Current generated workout
final generatedWorkoutProvider =
    StateNotifierProvider<GeneratedWorkoutNotifier, GeneratedWorkout?>((ref) {
  final repository = ref.watch(exerciseRepositoryProvider);
  return GeneratedWorkoutNotifier(repository);
});

class GeneratedWorkoutNotifier extends StateNotifier<GeneratedWorkout?> {
  final ExerciseRepository _repository;

  GeneratedWorkoutNotifier(this._repository) : super(null) {
    _load();
  }

  void _load() {
    state = _repository.getGeneratedWorkout();
  }

  Future<void> setWorkout(GeneratedWorkout workout) async {
    await _repository.saveGeneratedWorkout(workout);
    state = workout;
  }

  Future<void> clear() async {
    await _repository.clearGeneratedWorkout();
    state = null;
  }
}

/// Today's exercise activities
final exerciseActivitiesProvider =
    StateNotifierProvider<ExerciseActivitiesNotifier, List<ExerciseActivity>>(
        (ref) {
  final repository = ref.watch(exerciseRepositoryProvider);
  return ExerciseActivitiesNotifier(repository, ref);
});

class ExerciseActivitiesNotifier extends StateNotifier<List<ExerciseActivity>> {
  final ExerciseRepository _repository;
  final Ref _ref;

  ExerciseActivitiesNotifier(this._repository, this._ref) : super([]) {
    _loadToday();
  }

  void _loadToday() {
    state = _repository.getActivitiesForDate(DateTime.now());
  }

  void loadForDate(DateTime date) {
    state = _repository.getActivitiesForDate(date);
  }

  Future<void> addActivity(ExerciseActivity activity) async {
    await _repository.saveActivity(activity);
    _loadToday();
    _updateDailyLog();
  }

  Future<void> removeActivity(String id) async {
    await _repository.deleteActivity(id);
    _loadToday();
    _updateDailyLog();
  }

  /// Update the daily log with total exercise minutes from logged activities
  void _updateDailyLog() {
    final totalMinutes = state.fold<int>(0, (sum, a) => sum + a.durationMinutes);
    _ref.read(dailyLogProvider.notifier).setExercise(totalMinutes);
  }

  /// Total minutes logged today
  int get totalMinutesToday {
    return state.fold(0, (sum, a) => sum + a.durationMinutes);
  }
}

/// Exercise progress for today
final exerciseProgressProvider = Provider<ExerciseProgress>((ref) {
  final log = ref.watch(dailyLogProvider);
  final config = ref.watch(userConfigProvider);
  final activities = ref.watch(exerciseActivitiesProvider);

  return ExerciseProgress(
    totalMinutes: log.exerciseMinutes,
    goalMinutes: config.exerciseGoalMinutes,
    activityCount: activities.length,
  );
});

/// Whether the workout display is collapsed
final workoutCollapsedProvider = StateProvider<bool>((ref) => false);

/// Workout generation state (loading, error handling)
final workoutGenerationProvider =
    StateNotifierProvider<WorkoutGenerationNotifier, AsyncValue<void>>((ref) {
  return WorkoutGenerationNotifier(ref);
});

class WorkoutGenerationNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  WorkoutGenerationNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> generate({String? userRequest}) async {
    state = const AsyncValue.loading();

    try {
      final config = _ref.read(userConfigProvider);
      final service = _ref.read(exerciseServiceProvider);
      final workoutNotifier = _ref.read(generatedWorkoutProvider.notifier);

      final workout = await service.generateWorkout(
        goal: config.fitnessGoal ?? FitnessGoal.stayActive,
        level: config.fitnessLevel ?? FitnessLevel.beginner,
        // Use the daily exercise goal for workout duration
        durationMinutes: config.exerciseGoalMinutes,
        userRequest: userRequest,
      );

      await workoutNotifier.setWorkout(workout);
      
      // Expand the workout display for new workouts
      _ref.read(workoutCollapsedProvider.notifier).state = false;
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

