/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Life Tracker';
  static const String appVersion = '1.0.0';

  // Hive box names
  static const String dailyLogsBox = 'daily_logs';
  static const String foodItemsBox = 'food_items';
  static const String userConfigBox = 'user_config';

  // Default daily goals (can be overridden in settings)
  static const double defaultWaterGoalLiters = 2.5;
  static const int defaultExerciseGoalMinutes = 30;
  static const int defaultSunlightGoalMinutes = 20;
  static const int defaultSleepGoalHours = 8;
}

