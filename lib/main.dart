import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/storage_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage
  await StorageInitializer.init();

  runApp(
    const ProviderScope(
      child: LifeTrackerApp(),
    ),
  );
}
