import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/exercise_models.dart';

/// Service for generating AI-powered workouts
/// Follows same pattern as NutritionService
class ExerciseService {
  final String? apiKey;
  final String provider;

  ExerciseService({
    this.apiKey,
    this.provider = 'openai',
  });

  /// Generate a workout based on user profile and optional request
  Future<GeneratedWorkout> generateWorkout({
    required FitnessGoal goal,
    required FitnessLevel level,
    required int durationMinutes,
    String? userRequest,
  }) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception(
          'API key not configured. Please set your API key in Settings.');
    }

    final prompt = _buildWorkoutPrompt(
      goal: goal,
      level: level,
      durationMinutes: durationMinutes,
      userRequest: userRequest,
    );

    try {
      final response = await _callAI(prompt);
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('EXERCISE SERVICE - Raw AI response:');
      debugPrint(response);
      debugPrint('═══════════════════════════════════════════════════════════');
      return _parseWorkoutResponse(response, goal, userRequest);
    } catch (e) {
      debugPrint('EXERCISE SERVICE ERROR: $e');
      throw Exception('Failed to generate workout: $e');
    }
  }

  String _buildWorkoutPrompt({
    required FitnessGoal goal,
    required FitnessLevel level,
    required int durationMinutes,
    String? userRequest,
  }) {
    final userRequestSection = userRequest != null && userRequest.isNotEmpty
        ? '\nUser request: "$userRequest" - incorporate this into the workout.'
        : '';

    return '''
Create a home workout with NO equipment required.

User profile:
- Goal: ${goal.displayName}
- Fitness level: ${level.displayName}
- Target duration: $durationMinutes minutes
$userRequestSection

Requirements:
- Include 1-2 warm-up exercise(s) marked with isWarmup: true
- Include 4-8 main exercises appropriate for the goal and level
- Include 1-2 cool-down stretch(es) marked with isCooldown: true
- All exercises must be doable at home with no equipment
- Adjust difficulty to fitness level
- Total time should be approximately $durationMinutes minutes
- For EACH exercise, include a "steps" array with 3-5 clear, numbered instructions explaining proper form. Each step should be concise but complete.

Respond with ONLY this JSON format (no markdown, no explanation):
{
  "title": "Descriptive workout title based on focus",
  "estimatedMinutes": $durationMinutes,
  "exercises": [
    {
      "name": "Exercise name",
      "reps": "duration or reps",
      "steps": [
        "Start in position X with feet shoulder-width apart",
        "Lower your body by bending at the knees",
        "Keep your back straight and core engaged",
        "Push through your heels to return to standing"
      ],
      "isWarmup": true,
      "isCooldown": false
    }
  ]
}
''';
  }

  GeneratedWorkout _parseWorkoutResponse(
    String response,
    FitnessGoal goal,
    String? userRequest,
  ) {
    try {
      var cleaned = response.trim();

      // Remove markdown code blocks if present
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceAll(RegExp(r'^```\w*\n?'), '')
            .replaceAll(RegExp(r'\n?```$'), '');
      }

      // Try to extract JSON
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
      if (jsonMatch != null) {
        cleaned = jsonMatch.group(0)!;
      }

      final data = jsonDecode(cleaned) as Map<String, dynamic>;

      return GeneratedWorkout(
        id: const Uuid().v4(),
        title: data['title'] as String? ?? 'Home Workout',
        exercises: (data['exercises'] as List<dynamic>?)
                ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        estimatedMinutes: data['estimatedMinutes'] as int? ?? 20,
        goal: goal,
        userRequest: userRequest,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Failed to parse workout response: $e');
      throw Exception('Failed to parse workout response: $e');
    }
  }

  /// AI calling methods - copy pattern from nutrition_service.dart
  Future<String> _callAI(String prompt) async {
    if (provider == 'anthropic') {
      return _callAnthropic(prompt);
    } else if (provider == 'deepseek') {
      return _callDeepSeek(prompt);
    } else {
      return _callOpenAI(prompt);
    }
  }

  Future<String> _callOpenAI(String prompt) async {
    final dio = Dio();
    final response = await dio.post(
      'https://api.openai.com/v1/chat/completions',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      ),
      data: {
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a certified personal trainer. Create effective, safe home workouts with clear exercise instructions. Always respond with valid JSON only, no markdown or explanation.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'max_tokens': 2500,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode}');
    }

    return response.data['choices'][0]['message']['content'] as String;
  }

  Future<String> _callAnthropic(String prompt) async {
    final dio = Dio();
    final response = await dio.post(
      'https://api.anthropic.com/v1/messages',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey!,
          'anthropic-version': '2023-06-01',
        },
      ),
      data: {
        'model': 'claude-3-haiku-20240307',
        'max_tokens': 2500,
        'system':
            'You are a certified personal trainer. Create effective, safe home workouts with clear exercise instructions. Always respond with valid JSON only.',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Anthropic API error: ${response.statusCode}');
    }

    return response.data['content'][0]['text'] as String;
  }

  Future<String> _callDeepSeek(String prompt) async {
    final dio = Dio();
    final response = await dio.post(
      'https://api.deepseek.com/v1/chat/completions',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      ),
      data: {
        'model': 'deepseek-chat',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a certified personal trainer. Create effective, safe home workouts with clear exercise instructions. Always respond with valid JSON only.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'max_tokens': 2500,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('DeepSeek API error: ${response.statusCode}');
    }

    return response.data['choices'][0]['message']['content'] as String;
  }
}

