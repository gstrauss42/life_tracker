import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the currently selected date.
final selectedDateProvider = StateNotifierProvider<SelectedDateNotifier, DateTime>((ref) {
  return SelectedDateNotifier();
});

/// Notifier for managing the selected date.
class SelectedDateNotifier extends StateNotifier<DateTime> {
  SelectedDateNotifier() : super(DateTime.now());

  void setDate(DateTime date) {
    if (date.isAfter(DateTime.now())) {
      state = DateTime.now();
    } else {
      state = date;
    }
  }

  void goToToday() => state = DateTime.now();

  void previousDay() => state = state.subtract(const Duration(days: 1));

  void nextDay() {
    final tomorrow = state.add(const Duration(days: 1));
    if (!tomorrow.isAfter(DateTime.now())) {
      state = tomorrow;
    }
  }

  bool get isToday {
    final now = DateTime.now();
    return state.year == now.year && state.month == now.month && state.day == now.day;
  }
}



