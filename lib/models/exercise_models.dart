import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'exercise_models.g.dart';

/// User's fitness goal - stored in settings
enum FitnessGoal {
  loseWeight('Lose Weight', 'Burn calories and lose fat'),
  buildStrength('Build Strength', 'Build muscle and get stronger'),
  stayActive('Stay Active', 'Maintain general fitness'),
  improveFlexibility('Improve Flexibility', 'Increase mobility and flexibility'),
  buildEndurance('Build Endurance', 'Improve stamina and cardio');

  const FitnessGoal(this.displayName, this.description);
  
  final String displayName;
  final String description;
}

/// User's fitness level - stored in settings
enum FitnessLevel {
  beginner('Beginner', 'New to exercise or returning after a break'),
  intermediate('Intermediate', 'Exercise regularly, comfortable with most movements'),
  advanced('Advanced', 'Very fit, looking for challenging workouts');

  const FitnessLevel(this.displayName, this.description);
  
  final String displayName;
  final String description;
}

/// A single exercise within a workout
class WorkoutExercise {
  final String name;
  final String? reps; // e.g., "12 reps" or "30 seconds"
  final String? description; // Legacy field for backwards compatibility
  final List<String>? _steps; // Numbered step-by-step instructions (internal, nullable for legacy data)
  final bool isWarmup;
  final bool isCooldown;

  const WorkoutExercise({
    required this.name,
    this.reps,
    this.description,
    List<String>? steps,
    this.isWarmup = false,
    this.isCooldown = false,
  }) : _steps = steps;

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    // Parse steps array, or fall back to splitting description if steps not provided
    List<String>? steps;
    if (json['steps'] != null) {
      final stepsList = json['steps'] as List<dynamic>?;
      if (stepsList != null && stepsList.isNotEmpty) {
        steps = stepsList.map((s) => s.toString()).toList();
      }
    }
    // Legacy: if only description provided and no steps, use description as single step
    if ((steps == null || steps.isEmpty) && json['description'] != null) {
      final desc = json['description'] as String?;
      if (desc != null && desc.isNotEmpty) {
        steps = [desc];
      }
    }

    return WorkoutExercise(
      name: json['name'] as String? ?? 'Unknown Exercise',
      reps: json['reps'] as String?,
      description: json['description'] as String?,
      steps: steps ?? [],
      isWarmup: json['isWarmup'] as bool? ?? false,
      isCooldown: json['isCooldown'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'reps': reps,
        'description': description,
        'steps': steps,
        'isWarmup': isWarmup,
        'isCooldown': isCooldown,
      };

  /// Safe getter for steps - always returns a list (never null)
  List<String> get steps => _steps ?? [];

  /// Generate a YouTube search URL for this exercise
  String get youtubeSearchUrl {
    final searchQuery = Uri.encodeComponent('how to do $name exercise');
    return 'https://www.youtube.com/results?search_query=$searchQuery';
  }

  /// Check if this exercise has instructions
  bool get hasInstructions => steps.isNotEmpty;
}

/// A generated workout from AI
class GeneratedWorkout {
  final String id;
  final String title;
  final List<WorkoutExercise> exercises;
  final int estimatedMinutes;
  final FitnessGoal? goal;
  final String? userRequest; // What the user typed (if any)
  final DateTime generatedAt;

  const GeneratedWorkout({
    required this.id,
    required this.title,
    required this.exercises,
    required this.estimatedMinutes,
    this.goal,
    this.userRequest,
    required this.generatedAt,
  });

  factory GeneratedWorkout.fromJson(Map<String, dynamic> json) {
    return GeneratedWorkout(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: json['title'] as String? ?? 'Workout',
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 20,
      goal: json['goal'] != null
          ? FitnessGoal.values.firstWhere(
              (g) => g.name == json['goal'],
              orElse: () => FitnessGoal.stayActive,
            )
          : null,
      userRequest: json['userRequest'] as String?,
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'estimatedMinutes': estimatedMinutes,
        'goal': goal?.name,
        'userRequest': userRequest,
        'generatedAt': generatedAt.toIso8601String(),
      };

  /// Get warmup exercises
  List<WorkoutExercise> get warmupExercises =>
      exercises.where((e) => e.isWarmup).toList();

  /// Get main exercises (not warmup or cooldown)
  List<WorkoutExercise> get mainExercises =>
      exercises.where((e) => !e.isWarmup && !e.isCooldown).toList();

  /// Get cooldown exercises
  List<WorkoutExercise> get cooldownExercises =>
      exercises.where((e) => e.isCooldown).toList();
}

/// A logged exercise activity (manual entry by user)
@HiveType(typeId: 3)
class ExerciseActivity extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int durationMinutes;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String? notes;

  @HiveField(5)
  final String? workoutId; // Link to generated workout if applicable

  ExerciseActivity({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.timestamp,
    this.notes,
    this.workoutId,
  });

  factory ExerciseActivity.create({
    required String name,
    required int durationMinutes,
    String? notes,
    String? workoutId,
  }) {
    return ExerciseActivity(
      id: const Uuid().v4(),
      name: name,
      durationMinutes: durationMinutes,
      timestamp: DateTime.now(),
      notes: notes,
      workoutId: workoutId,
    );
  }

  factory ExerciseActivity.fromJson(Map<String, dynamic> json) {
    return ExerciseActivity(
      id: json['id'] as String,
      name: json['name'] as String,
      durationMinutes: json['durationMinutes'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      notes: json['notes'] as String?,
      workoutId: json['workoutId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'durationMinutes': durationMinutes,
        'timestamp': timestamp.toIso8601String(),
        'notes': notes,
        'workoutId': workoutId,
      };

  ExerciseActivity copyWith({
    String? id,
    String? name,
    int? durationMinutes,
    DateTime? timestamp,
    String? notes,
    String? workoutId,
  }) {
    return ExerciseActivity(
      id: id ?? this.id,
      name: name ?? this.name,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
      workoutId: workoutId ?? this.workoutId,
    );
  }
}

/// Progress tracking for exercise
class ExerciseProgress {
  final int totalMinutes;
  final int goalMinutes;
  final int activityCount;

  const ExerciseProgress({
    required this.totalMinutes,
    required this.goalMinutes,
    required this.activityCount,
  });

  double get percentage =>
      goalMinutes > 0 ? (totalMinutes / goalMinutes).clamp(0.0, 1.0) : 0.0;

  int get percentComplete => (percentage * 100).round();

  bool get goalReached => totalMinutes >= goalMinutes;

  int get remainingMinutes => (goalMinutes - totalMinutes).clamp(0, goalMinutes);
}

