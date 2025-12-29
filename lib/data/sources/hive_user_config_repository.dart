import 'package:hive/hive.dart';

import '../../models/models.dart';
import '../repositories/user_config_repository.dart';

/// Hive implementation of UserConfigRepository.
class HiveUserConfigRepository implements UserConfigRepository {
  HiveUserConfigRepository(this._box);

  final Box<UserConfig> _box;
  static const String _configKey = 'config';

  @override
  UserConfig getConfig() {
    final existing = _box.get(_configKey);
    if (existing != null) return existing;

    final newConfig = UserConfig();
    _box.put(_configKey, newConfig);
    return newConfig;
  }

  @override
  Future<void> save(UserConfig config) async {
    await _box.put(_configKey, config);
  }

  @override
  Future<UserConfig> update(UserConfig Function(UserConfig) updater) async {
    final config = getConfig();
    final updated = updater(config);
    await save(updated);
    return updated;
  }
}



