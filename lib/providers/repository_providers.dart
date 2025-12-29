import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/data.dart';
import '../data/storage_initializer.dart';

/// Provider for the daily log repository.
final dailyLogRepositoryProvider = Provider<DailyLogRepository>((ref) {
  return StorageInitializer.dailyLogRepository;
});

/// Provider for the user config repository.
final userConfigRepositoryProvider = Provider<UserConfigRepository>((ref) {
  return StorageInitializer.userConfigRepository;
});



