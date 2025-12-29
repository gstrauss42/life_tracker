import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Food preferences for meal generation
class MealPreferences {
  final String feelLike; // Foods or ingredients the user feels like eating
  final String dislike; // Foods or ingredients the user wants to avoid

  const MealPreferences({
    this.feelLike = '',
    this.dislike = '',
  });

  bool get isEmpty => feelLike.isEmpty && dislike.isEmpty;
  bool get isNotEmpty => !isEmpty;

  MealPreferences copyWith({
    String? feelLike,
    String? dislike,
  }) {
    return MealPreferences(
      feelLike: feelLike ?? this.feelLike,
      dislike: dislike ?? this.dislike,
    );
  }

  /// Convert to a preferences string for the AI prompt
  String toPreferencesString() {
    final parts = <String>[];
    if (feelLike.isNotEmpty) {
      parts.add('I feel like eating: $feelLike');
    }
    if (dislike.isNotEmpty) {
      parts.add('Avoid these foods/ingredients: $dislike');
    }
    return parts.join('. ');
  }
}

/// State for meal suggestions - scoped to a specific date
class MealSuggestionsState {
  final Map<String, List<String>> suggestionsByDate; // key: 'yyyy-MM-dd'
  final Map<String, bool> minimizedByDate; // collapsed state per date
  final Map<String, MealPreferences> preferencesByDate; // preferences per date
  final bool isLoading;
  final String? error;
  final String? loadingDate; // which date is currently loading

  const MealSuggestionsState({
    this.suggestionsByDate = const {},
    this.minimizedByDate = const {},
    this.preferencesByDate = const {},
    this.isLoading = false,
    this.error,
    this.loadingDate,
  });

  MealSuggestionsState copyWith({
    Map<String, List<String>>? suggestionsByDate,
    Map<String, bool>? minimizedByDate,
    Map<String, MealPreferences>? preferencesByDate,
    bool? isLoading,
    String? error,
    String? loadingDate,
    bool clearError = false,
  }) {
    return MealSuggestionsState(
      suggestionsByDate: suggestionsByDate ?? this.suggestionsByDate,
      minimizedByDate: minimizedByDate ?? this.minimizedByDate,
      preferencesByDate: preferencesByDate ?? this.preferencesByDate,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      loadingDate: loadingDate ?? this.loadingDate,
    );
  }

  /// Get suggestions for a specific date
  List<String>? getSuggestions(DateTime date) {
    return suggestionsByDate[_dateKey(date)];
  }

  /// Check if suggestions are minimized for a date
  bool isMinimized(DateTime date) {
    return minimizedByDate[_dateKey(date)] ?? false;
  }

  /// Check if we're loading for a specific date
  bool isLoadingForDate(DateTime date) {
    return isLoading && loadingDate == _dateKey(date);
  }

  /// Get preferences for a specific date
  MealPreferences getPreferences(DateTime date) {
    return preferencesByDate[_dateKey(date)] ?? const MealPreferences();
  }

  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Notifier for managing meal suggestions state
class MealSuggestionsNotifier extends StateNotifier<MealSuggestionsState> {
  MealSuggestionsNotifier() : super(const MealSuggestionsState());

  /// Set suggestions for a specific date
  void setSuggestions(DateTime date, List<String> suggestions) {
    final key = MealSuggestionsState._dateKey(date);
    state = state.copyWith(
      suggestionsByDate: {...state.suggestionsByDate, key: suggestions},
      isLoading: false,
      loadingDate: null,
      clearError: true,
    );
  }

  /// Set loading state for a specific date
  void setLoading(DateTime date, bool loading) {
    state = state.copyWith(
      isLoading: loading,
      loadingDate: loading ? MealSuggestionsState._dateKey(date) : null,
      clearError: loading,
    );
  }

  /// Set error state
  void setError(String error) {
    state = state.copyWith(
      error: error,
      isLoading: false,
      loadingDate: null,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Toggle minimized state for a date
  void toggleMinimized(DateTime date) {
    final key = MealSuggestionsState._dateKey(date);
    final current = state.minimizedByDate[key] ?? false;
    state = state.copyWith(
      minimizedByDate: {...state.minimizedByDate, key: !current},
    );
  }

  /// Expand (show) suggestions for a date
  void expand(DateTime date) {
    final key = MealSuggestionsState._dateKey(date);
    state = state.copyWith(
      minimizedByDate: {...state.minimizedByDate, key: false},
    );
  }

  /// Minimize (collapse) suggestions for a date
  void minimize(DateTime date) {
    final key = MealSuggestionsState._dateKey(date);
    state = state.copyWith(
      minimizedByDate: {...state.minimizedByDate, key: true},
    );
  }

  /// Clear suggestions for a specific date
  void clearSuggestions(DateTime date) {
    final key = MealSuggestionsState._dateKey(date);
    final newSuggestions = Map<String, List<String>>.from(state.suggestionsByDate)
      ..remove(key);
    final newMinimized = Map<String, bool>.from(state.minimizedByDate)
      ..remove(key);
    state = state.copyWith(
      suggestionsByDate: newSuggestions,
      minimizedByDate: newMinimized,
    );
  }

  /// Update preferences for a specific date
  void setPreferences(DateTime date, MealPreferences preferences) {
    final key = MealSuggestionsState._dateKey(date);
    state = state.copyWith(
      preferencesByDate: {...state.preferencesByDate, key: preferences},
    );
  }

  /// Update "feel like" preference for a specific date
  void setFeelLike(DateTime date, String feelLike) {
    final key = MealSuggestionsState._dateKey(date);
    final current = state.preferencesByDate[key] ?? const MealPreferences();
    state = state.copyWith(
      preferencesByDate: {...state.preferencesByDate, key: current.copyWith(feelLike: feelLike)},
    );
  }

  /// Update "dislike" preference for a specific date
  void setDislike(DateTime date, String dislike) {
    final key = MealSuggestionsState._dateKey(date);
    final current = state.preferencesByDate[key] ?? const MealPreferences();
    state = state.copyWith(
      preferencesByDate: {...state.preferencesByDate, key: current.copyWith(dislike: dislike)},
    );
  }

  /// Clear preferences for a specific date
  void clearPreferences(DateTime date) {
    final key = MealSuggestionsState._dateKey(date);
    final newPreferences = Map<String, MealPreferences>.from(state.preferencesByDate)
      ..remove(key);
    state = state.copyWith(preferencesByDate: newPreferences);
  }

  /// Clear all suggestions (e.g., on logout)
  void clearAll() {
    state = const MealSuggestionsState();
  }
}

/// Provider for meal suggestions state
final mealSuggestionsProvider =
    StateNotifierProvider<MealSuggestionsNotifier, MealSuggestionsState>((ref) {
  return MealSuggestionsNotifier();
});

