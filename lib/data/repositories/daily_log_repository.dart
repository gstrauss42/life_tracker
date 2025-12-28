import '../../models/models.dart';

/// Repository interface for daily log data operations.
/// Abstracts the data source from the rest of the app.
abstract class DailyLogRepository {
  /// Get log for a specific date
  DailyLog? getLog(DateTime date);

  /// Get or create log for a specific date
  DailyLog getOrCreateLog(DateTime date);

  /// Save a log
  Future<void> save(DailyLog log);

  /// Get logs for a date range
  List<DailyLog> getLogsInRange(DateTime start, DateTime end);

  /// Get recent logs (last N days)
  List<DailyLog> getRecentLogs(int days);

  /// Update a specific field on a log
  Future<DailyLog> updateLog(DateTime date, DailyLog Function(DailyLog) update);
}

