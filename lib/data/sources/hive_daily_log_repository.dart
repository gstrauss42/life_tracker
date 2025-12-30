import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../repositories/daily_log_repository.dart';

/// Hive implementation of DailyLogRepository.
class HiveDailyLogRepository implements DailyLogRepository {
  HiveDailyLogRepository(this._box);

  final Box<DailyLog> _box;

  String _dateToKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  @override
  DailyLog? getLog(DateTime date) {
    return _box.get(_dateToKey(date));
  }

  @override
  DailyLog getOrCreateLog(DateTime date) {
    final key = _dateToKey(date);
    final existing = _box.get(key);
    if (existing != null) return existing;

    final newLog = DailyLog(date: key);
    _box.put(key, newLog);
    return newLog;
  }

  @override
  Future<void> save(DailyLog log) async {
    await _box.put(log.date, log);
  }

  @override
  List<DailyLog> getLogsInRange(DateTime start, DateTime end) {
    final logs = <DailyLog>[];
    var current = start;

    while (!current.isAfter(end)) {
      final log = getLog(current);
      if (log != null) {
        logs.add(log);
      }
      current = current.add(const Duration(days: 1));
    }

    return logs;
  }

  @override
  List<DailyLog> getRecentLogs(int days) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days - 1));
    return getLogsInRange(start, end);
  }

  @override
  Future<DailyLog> updateLog(DateTime date, DailyLog Function(DailyLog) update) async {
    final log = getOrCreateLog(date);
    final updated = update(log);
    await save(updated);
    return updated;
  }
}




