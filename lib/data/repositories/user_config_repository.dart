import '../../models/models.dart';

/// Repository interface for user configuration.
abstract class UserConfigRepository {
  /// Get current config (creates default if none exists)
  UserConfig getConfig();

  /// Save config
  Future<void> save(UserConfig config);

  /// Update specific fields
  Future<UserConfig> update(UserConfig Function(UserConfig) updater);
}



