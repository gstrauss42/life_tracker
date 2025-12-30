import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/aggregated_data.dart';
import '../models/analytics_models.dart';
import '../models/daily_log.dart';
import '../models/user_config.dart';

/// Service for generating AI-powered analytics insights.
class AnalyticsService {
  AnalyticsService({
    this.apiKey,
    this.provider = 'openai',
  });

  final String? apiKey;
  final String provider;

  /// Generate AI analysis from aggregated data and recent logs
  Future<StoredAIAnalysis> generateAnalysis({
    required AggregatedUserData aggregates,
    required List<DailyLog> recentLogs,
    required UserConfig config,
  }) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('API key not configured. Please set your API key in Settings.');
    }

    final prompt = _buildAnalysisPrompt(aggregates, recentLogs, config);

    try {
      final response = await _callAI(prompt);
      debugPrint('Analytics AI Response: $response');
      
      return _parseAnalysisResponse(response, aggregates);
    } catch (e) {
      debugPrint('Analytics AI Error: $e');
      rethrow;
    }
  }

  /// Build the analysis prompt from user data
  String _buildAnalysisPrompt(
    AggregatedUserData aggregates,
    List<DailyLog> recentLogs,
    UserConfig config,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('Analyze this health tracking data and provide insights.');
    buffer.writeln();
    buffer.writeln('=== AGGREGATED DATA (${aggregates.daysAnalyzed} days) ===');
    buffer.writeln();
    
    // Nutrition context
    if (aggregates.nutrition.hasData) {
      buffer.writeln(aggregates.nutrition.toAIContext());
    }
    
    // Exercise context
    if (aggregates.exercise.hasData) {
      buffer.writeln(aggregates.exercise.toAIContext());
    }
    
    // Social context
    if (aggregates.social.hasData) {
      buffer.writeln(aggregates.social.toAIContext());
    }
    
    // Simple metrics
    final sm = aggregates.simpleMetrics;
    if (sm.hasData) {
      buffer.writeln('Simple Metrics:');
      buffer.writeln('- Water: ${sm.avgWaterLiters.toStringAsFixed(1)}L avg (goal: ${config.waterGoalLiters}L), ${(sm.waterGoalHitRate * 100).round()}% hit rate');
      buffer.writeln('- Sunlight: ${sm.avgSunlightMinutes.round()} min avg (goal: ${config.sunlightGoalMinutes} min), ${(sm.sunlightGoalHitRate * 100).round()}% hit rate');
      buffer.writeln('- Sleep: ${sm.avgSleepHours.toStringAsFixed(1)} hrs avg (goal: ${config.sleepGoalHours} hrs), ${(sm.sleepGoalHitRate * 100).round()}% hit rate');
      buffer.writeln();
    }
    
    // Patterns
    final patterns = aggregates.patterns;
    if (patterns.hasPatterns) {
      buffer.writeln('Patterns detected:');
      if (patterns.exerciseTrend != null) {
        buffer.writeln('- Exercise trend: ${patterns.exerciseTrend}');
      }
      if (patterns.sleepTrend != null) {
        buffer.writeln('- Sleep trend: ${patterns.sleepTrend}');
      }
      if (patterns.sleepExerciseCorrelation != null && patterns.sleepExerciseCorrelation!.abs() > 0.3) {
        final corrType = patterns.sleepExerciseCorrelation! > 0 ? 'positive' : 'negative';
        buffer.writeln('- Sleep-exercise correlation: $corrType (${patterns.sleepExerciseCorrelation!.toStringAsFixed(2)})');
      }
      buffer.writeln();
    }
    
    // Recent daily values
    buffer.writeln('=== RECENT DAILY VALUES ===');
    final recentFive = recentLogs.take(5).toList();
    for (final log in recentFive) {
      final nutrition = log.nutritionSummary;
      buffer.writeln('${log.date}: Water ${log.waterLiters}L, Sleep ${log.sleepHours}hrs, Exercise ${log.exerciseMinutes}min, Calories ${nutrition.calories.round()}');
    }
    buffer.writeln();
    
    buffer.writeln('''
Provide analysis in this JSON format ONLY (no other text):
{
  "working": ["point 1", "point 2"],
  "attention": ["point 1", "point 2"],
  "recommendations": ["point 1", "point 2"]
}

Rules:
1. "working" - 2-3 genuine wins based on the data, not generic praise. Reference specific numbers.
2. "attention" - 2-3 specific issues with context (e.g., "Water intake dropped from 1.5L to 0.8L")
3. "recommendations" - 2-3 actionable, specific suggestions based on their actual patterns
4. Be direct and specific. Reference actual numbers from their data.
5. No generic advice like "drink more water" - be specific to their situation.
6. If a metric is at 0 or no data exists, don't include it in analysis.
''');
    
    return buffer.toString();
  }

  /// Parse the AI response into StoredAIAnalysis
  StoredAIAnalysis _parseAnalysisResponse(
    String response,
    AggregatedUserData aggregates,
  ) {
    var cleaned = response.trim();
    
    // Remove markdown code blocks if present
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'^```\w*\n?'), '').replaceAll(RegExp(r'\n?```$'), '');
    }
    
    // Try to extract JSON if there's text around it
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
    if (jsonMatch != null) {
      cleaned = jsonMatch.group(0)!;
    }

    final data = jsonDecode(cleaned) as Map<String, dynamic>;
    
    return StoredAIAnalysis(
      generatedAt: DateTime.now(),
      dataTimestamp: aggregates.lastUpdated,
      working: _parseStringList(data['working']),
      attention: _parseStringList(data['attention']),
      recommendations: _parseStringList(data['recommendations']),
      daysAnalyzed: aggregates.daysAnalyzed,
    );
  }

  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Call AI provider
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
            'content': 'You are a health analytics expert. Analyze user health data and provide specific, actionable insights. Always respond with valid JSON only, no markdown or explanation.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.3,
        'max_tokens': 1000,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode} - ${response.data}');
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
        'max_tokens': 1000,
        'system': 'You are a health analytics expert. Analyze user health data and provide specific, actionable insights. Always respond with valid JSON only.',
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          },
        ],
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Anthropic API error: ${response.statusCode} - ${response.data}');
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
            'content': 'You are a health analytics expert. Analyze user health data and provide specific, actionable insights. Always respond with valid JSON only.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.3,
        'max_tokens': 1000,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('DeepSeek API error: ${response.statusCode} - ${response.data}');
    }

    return response.data['choices'][0]['message']['content'] as String;
  }
}

/// Helper class for computing analytics dashboard data
class AnalyticsComputer {
  const AnalyticsComputer._();

  /// Compute summary text for the period
  static String computePeriodSummary({
    required AggregatedUserData current,
    required AggregatedUserData? previous,
    required UserConfig config,
  }) {
    final sm = current.simpleMetrics;
    final exercise = current.exercise;
    
    // Calculate average completion
    final avgCompletion = _calculateAvgCompletion(current, config);
    
    // Determine trend
    String trendText = '';
    if (previous != null) {
      final prevCompletion = _calculateAvgCompletion(previous, config);
      if (avgCompletion > prevCompletion + 5) {
        trendText = ', trending ↑ from last period';
      } else if (avgCompletion < prevCompletion - 5) {
        trendText = ', trending ↓ from last period';
      } else {
        trendText = ', stable from last period';
      }
    }
    
    // Find focus area (lowest performing metric)
    final focusArea = _findFocusArea(current, config);
    
    return 'This period: ${avgCompletion.round()}% avg completion$trendText. Focus area: $focusArea';
  }

  static double _calculateAvgCompletion(AggregatedUserData data, UserConfig config) {
    final sm = data.simpleMetrics;
    final exercise = data.exercise;
    
    double total = 0;
    int count = 0;
    
    if (sm.avgWaterLiters > 0 || config.waterGoalLiters > 0) {
      total += (sm.avgWaterLiters / config.waterGoalLiters * 100).clamp(0, 100);
      count++;
    }
    if (sm.avgSunlightMinutes > 0 || config.sunlightGoalMinutes > 0) {
      total += (sm.avgSunlightMinutes / config.sunlightGoalMinutes * 100).clamp(0, 100);
      count++;
    }
    if (sm.avgSleepHours > 0 || config.sleepGoalHours > 0) {
      total += (sm.avgSleepHours / config.sleepGoalHours * 100).clamp(0, 100);
      count++;
    }
    if (exercise.avgMinutesPerDay > 0 || config.exerciseGoalMinutes > 0) {
      total += (exercise.avgMinutesPerDay / config.exerciseGoalMinutes * 100).clamp(0, 100);
      count++;
    }
    
    return count > 0 ? total / count : 0;
  }

  static String _findFocusArea(AggregatedUserData data, UserConfig config) {
    final sm = data.simpleMetrics;
    final exercise = data.exercise;
    
    final metrics = <String, double>{
      'Water': config.waterGoalLiters > 0 
          ? (sm.avgWaterLiters / config.waterGoalLiters * 100) : 100,
      'Sunlight': config.sunlightGoalMinutes > 0 
          ? (sm.avgSunlightMinutes / config.sunlightGoalMinutes * 100) : 100,
      'Sleep': config.sleepGoalHours > 0 
          ? (sm.avgSleepHours / config.sleepGoalHours * 100) : 100,
      'Exercise': config.exerciseGoalMinutes > 0 
          ? (exercise.avgMinutesPerDay / config.exerciseGoalMinutes * 100) : 100,
    };
    
    final lowestEntry = metrics.entries.reduce((a, b) => a.value < b.value ? a : b);
    return '${lowestEntry.key} (${lowestEntry.value.round()}% of goal)';
  }

  /// Get day name from weekday number (1=Mon, 7=Sun)
  static String getDayName(int weekday) {
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday.clamp(1, 7)];
  }

  /// Get short day name
  static String getShortDayName(int weekday) {
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday.clamp(1, 7)];
  }

  /// Find best day for a metric from logs
  static (String, double) findBestDay(
    List<DailyLog> logs, 
    double Function(DailyLog) getValue,
  ) {
    if (logs.isEmpty) return ('N/A', 0);
    
    DailyLog? bestLog;
    double bestValue = -1;
    
    for (final log in logs) {
      final value = getValue(log);
      if (value > bestValue) {
        bestValue = value;
        bestLog = log;
      }
    }
    
    if (bestLog == null) return ('N/A', 0);
    
    final date = DateTime.parse(bestLog.date);
    return (getDayName(date.weekday), bestValue);
  }

  /// Count days that hit goal
  static int countGoalHits(
    List<DailyLog> logs,
    double Function(DailyLog) getValue,
    double goal,
  ) {
    return logs.where((log) => getValue(log) >= goal).length;
  }
}


