import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the currently selected navigation tab index.
/// This allows any widget to programmatically navigate between tabs.
final selectedTabProvider = StateProvider<int>((ref) => 0);

/// Provider for scrolling to a specific settings section after navigation.
/// Set this before navigating to settings, and the settings screen will scroll to it.
final settingsScrollTargetProvider = StateProvider<String?>((ref) => null);

/// Provider for scrolling to a specific profile section after navigation.
/// Set this before navigating to profile, and the profile screen will scroll to it.
final profileScrollTargetProvider = StateProvider<String?>((ref) => null);

/// Navigation tab indices
class NavTabs {
  static const int home = 0;
  static const int analytics = 1;
  static const int profile = 2;
  static const int settings = 3;
}

/// Settings section identifiers for scrolling
class SettingsSections {
  static const String exercisePreferences = 'exercise_preferences';
}

/// Profile section identifiers for scrolling
class ProfileSections {
  static const String personalInfo = 'personal_info';
  static const String location = 'location';
  static const String goals = 'goals';
  static const String exercisePreferences = 'exercise_preferences';
  static const String health = 'health';
  static const String dietary = 'dietary';
}

