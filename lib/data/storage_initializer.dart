import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';
import 'sources/sources.dart';
import 'repositories/repositories.dart';

/// Handles Hive initialization and provides repository instances.
class StorageInitializer {
  StorageInitializer._();

  static bool _initialized = false;
  static late Box<DailyLog> _dailyLogsBox;
  static late Box<UserConfig> _userConfigBox;

  /// Initialize Hive storage. Call once at app startup.
  static Future<void> init() async {
    if (_initialized) return;

    final appDocDir = await getApplicationDocumentsDirectory();
    final dataDir = Directory('${appDocDir.path}/life_tracker_data');

    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }

    Hive.init(dataDir.path);

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DailyLogAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(FoodEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(UserConfigAdapter());
    }

    // Open boxes
    _dailyLogsBox = await Hive.openBox<DailyLog>('daily_logs');
    _userConfigBox = await Hive.openBox<UserConfig>('user_config');

    _initialized = true;
  }

  /// Get the daily log repository instance.
  static DailyLogRepository get dailyLogRepository {
    _ensureInitialized();
    return HiveDailyLogRepository(_dailyLogsBox);
  }

  /// Get the user config repository instance.
  static UserConfigRepository get userConfigRepository {
    _ensureInitialized();
    return HiveUserConfigRepository(_userConfigBox);
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('StorageInitializer.init() must be called before accessing repositories');
    }
  }

  /// Clear all data (for testing/reset)
  static Future<void> clearAll() async {
    _ensureInitialized();
    await _dailyLogsBox.clear();
    await _userConfigBox.clear();
  }
}



