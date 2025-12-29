import 'dart:convert';
import 'package:hive/hive.dart';

import '../../models/exercise_models.dart';

/// Repository interface for exercise data
abstract class ExerciseRepository {
  /// Save a logged exercise activity
  Future<void> saveActivity(ExerciseActivity activity);

  /// Get activities for a specific date
  List<ExerciseActivity> getActivitiesForDate(DateTime date);

  /// Get all activities (for history/analytics)
  List<ExerciseActivity> getAllActivities();

  /// Delete an activity
  Future<void> deleteActivity(String id);

  /// Save generated workout (persists until regenerated)
  Future<void> saveGeneratedWorkout(GeneratedWorkout workout);

  /// Get current generated workout
  GeneratedWorkout? getGeneratedWorkout();

  /// Clear generated workout
  Future<void> clearGeneratedWorkout();
}

/// Hive implementation of ExerciseRepository
class HiveExerciseRepository implements ExerciseRepository {
  final Box<ExerciseActivity> _activitiesBox;
  final Box<String> _workoutBox;

  HiveExerciseRepository(this._activitiesBox, this._workoutBox);

  @override
  Future<void> saveActivity(ExerciseActivity activity) async {
    await _activitiesBox.put(activity.id, activity);
  }

  @override
  List<ExerciseActivity> getActivitiesForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    return _activitiesBox.values
        .where((a) => a.timestamp.isAfter(start) && a.timestamp.isBefore(end))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  List<ExerciseActivity> getAllActivities() {
    return _activitiesBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<void> deleteActivity(String id) async {
    await _activitiesBox.delete(id);
  }

  @override
  Future<void> saveGeneratedWorkout(GeneratedWorkout workout) async {
    await _workoutBox.put('current', jsonEncode(workout.toJson()));
  }

  @override
  GeneratedWorkout? getGeneratedWorkout() {
    final json = _workoutBox.get('current');
    if (json == null) return null;

    try {
      return GeneratedWorkout.fromJson(
          jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearGeneratedWorkout() async {
    await _workoutBox.delete('current');
  }
}

