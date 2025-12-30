import 'dart:convert';
import 'package:hive/hive.dart';

import '../../models/analytics_models.dart';

/// Repository for storing and retrieving AI analytics data.
abstract class AnalyticsRepository {
  /// Get the stored AI analysis, or null if not yet generated
  StoredAIAnalysis? getAnalysis();

  /// Save AI analysis
  Future<void> saveAnalysis(StoredAIAnalysis analysis);

  /// Check if analysis exists
  bool hasAnalysis();

  /// Clear analysis (for testing/reset)
  Future<void> clear();

  /// Check if regeneration is needed (data has changed since last analysis)
  bool needsRegeneration(DateTime dataTimestamp);
}

/// Hive implementation of AnalyticsRepository
class HiveAnalyticsRepository implements AnalyticsRepository {
  final Box<String> _box;

  static const String _analysisKey = 'ai_analysis';

  HiveAnalyticsRepository(this._box);

  @override
  StoredAIAnalysis? getAnalysis() {
    final json = _box.get(_analysisKey);
    if (json == null) return null;

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return StoredAIAnalysis.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveAnalysis(StoredAIAnalysis analysis) async {
    final json = jsonEncode(analysis.toJson());
    await _box.put(_analysisKey, json);
  }

  @override
  bool hasAnalysis() {
    return _box.containsKey(_analysisKey);
  }

  @override
  Future<void> clear() async {
    await _box.delete(_analysisKey);
  }

  @override
  bool needsRegeneration(DateTime dataTimestamp) {
    final analysis = getAnalysis();
    if (analysis == null) return true;
    
    // Regeneration needed if data has been updated since last analysis
    return dataTimestamp.isAfter(analysis.dataTimestamp);
  }
}


