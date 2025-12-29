import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../services/services.dart';

/// Section for generating AI meal suggestions.
/// Suggestions are scoped to the selected date and persist during the session.
class FoodSuggestionsSection extends ConsumerStatefulWidget {
  const FoodSuggestionsSection({
    super.key,
    required this.selectedDate,
  });

  final DateTime selectedDate;

  @override
  ConsumerState<FoodSuggestionsSection> createState() => _FoodSuggestionsSectionState();
}

class _FoodSuggestionsSectionState extends ConsumerState<FoodSuggestionsSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  final _feelLikeController = TextEditingController();
  final _dislikeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
    // Initialize with saved preferences
    _loadPreferences();
  }

  void _loadPreferences() {
    final state = ref.read(mealSuggestionsProvider);
    final prefs = state.getPreferences(widget.selectedDate);
    _feelLikeController.text = prefs.feelLike;
    _dislikeController.text = prefs.dislike;
  }

  @override
  void didUpdateWidget(FoodSuggestionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update animation state when date changes
    final state = ref.read(mealSuggestionsProvider);
    final isMinimized = state.isMinimized(widget.selectedDate);
    if (isMinimized) {
      _expandController.value = 0;
    } else {
      _expandController.value = 1;
    }
    // Load preferences for new date
    if (oldWidget.selectedDate != widget.selectedDate) {
      _loadPreferences();
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    _feelLikeController.dispose();
    _dislikeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final config = ref.watch(userConfigProvider);
    final suggestionsState = ref.watch(mealSuggestionsProvider);

    // Don't show if no API key configured
    if (config.aiApiKey == null || config.aiApiKey!.isEmpty) {
      return const SizedBox.shrink();
    }

    final suggestions = suggestionsState.getSuggestions(widget.selectedDate);
    final isLoading = suggestionsState.isLoadingForDate(widget.selectedDate);
    final isMinimized = suggestionsState.isMinimized(widget.selectedDate);
    final error = suggestionsState.error;

    // Update animation state
    if (suggestions != null && !isLoading) {
      if (isMinimized && _expandController.value != 0) {
        _expandController.reverse();
      } else if (!isMinimized && _expandController.value != 1) {
        _expandController.forward();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header - tappable to expand/collapse when suggestions exist
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (suggestions != null && !isLoading)
                ? () => ref.read(mealSuggestionsProvider.notifier).toggleMinimized(widget.selectedDate)
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Meal Ideas',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (suggestions != null && !isLoading) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatDate(widget.selectedDate),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (suggestions != null && !isLoading) ...[
                    // Collapse/expand indicator
                    AnimatedRotation(
                      turns: isMinimized ? 0 : 0.5,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 24,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Clear button
                    IconButton(
                      onPressed: () {
                        ref.read(mealSuggestionsProvider.notifier).clearSuggestions(widget.selectedDate);
                      },
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      tooltip: 'Clear suggestions',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Content
        if (isLoading)
          _buildLoadingState(context, theme, colorScheme)
        else if (error != null && suggestions == null)
          _buildErrorState(context, theme, colorScheme, error)
        else if (suggestions != null)
          _buildSuggestionsContent(context, theme, colorScheme, suggestions, isMinimized)
        else
          _buildGenerateButton(context, theme, colorScheme),
      ],
    );
  }

  Widget _buildGenerateButton(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Feel like input
        _buildPreferenceField(
          context,
          theme,
          colorScheme,
          controller: _feelLikeController,
          icon: Icons.favorite_outline,
          hintText: 'Optional: ingredients I\'d like (e.g., "chicken", "pasta")',
          iconColor: const Color(0xFF4CAF50),
        ),
        const SizedBox(height: 10),
        // Dislike input
        _buildPreferenceField(
          context,
          theme,
          colorScheme,
          controller: _dislikeController,
          icon: Icons.block_outlined,
          hintText: 'Optional: foods to avoid (e.g., "mushrooms", "fish")',
          iconColor: const Color(0xFFEF5350),
        ),
        const SizedBox(height: 14),
        // Generate button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _generateSuggestions,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Generate Meal Ideas'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceField(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    required Color iconColor,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.4),
          fontSize: 13,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: iconColor.withValues(alpha: 0.7),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      style: theme.textTheme.bodyMedium,
    );
  }

  Widget _buildLoadingState(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Generating meal ideas...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData theme, ColorScheme colorScheme, String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.error,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _generateSuggestions,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    List<String> suggestions,
    bool isMinimized,
  ) {
    return Column(
      children: [
        // Minimized summary bar
        if (isMinimized)
          _buildMinimizedBar(context, theme, colorScheme, suggestions)
        else
          // Expanded grid
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: _buildSuggestionsGrid(context, theme, colorScheme, suggestions),
          ),
      ],
    );
  }

  Widget _buildMinimizedBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    List<String> suggestions,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ref.read(mealSuggestionsProvider.notifier).expand(widget.selectedDate),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${suggestions.length} meal ideas ready',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Tap to expand',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.expand_more,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsGrid(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    List<String> suggestions,
  ) {
    return Column(
      children: [
        // Grid of suggestions
        ...List.generate(suggestions.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index < suggestions.length - 1 ? 10 : 0),
            child: _buildSuggestionCard(context, theme, colorScheme, suggestions[index], index),
          );
        }),
        const SizedBox(height: 16),
        // Regenerate section with preferences
        _buildRegenerateSection(context, theme, colorScheme),
      ],
    );
  }

  Widget _buildRegenerateSection(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                'Adjust Preferences',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Compact preference fields
          _buildCompactPreferenceField(
            context,
            theme,
            colorScheme,
            controller: _feelLikeController,
            icon: Icons.favorite_outline,
            hintText: 'Ingredients I\'d like...',
            iconColor: const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 8),
          _buildCompactPreferenceField(
            context,
            theme,
            colorScheme,
            controller: _dislikeController,
            icon: Icons.block_outlined,
            hintText: 'Ingredients to avoid...',
            iconColor: const Color(0xFFEF5350),
          ),
          const SizedBox(height: 12),
          // Regenerate button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _generateSuggestions,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Regenerate Ideas'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPreferenceField(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    required Color iconColor,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.4),
          fontSize: 12,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 10, right: 6),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 32),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: iconColor.withValues(alpha: 0.7),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        filled: true,
        fillColor: colorScheme.surface,
      ),
      style: theme.textTheme.bodySmall,
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    String suggestion,
    int index,
  ) {
    // Parse meal name and description
    final colonIndex = suggestion.indexOf(':');
    String mealName;
    String description;

    if (colonIndex > 0 && colonIndex < 60) {
      mealName = suggestion.substring(0, colonIndex).trim();
      description = suggestion.substring(colonIndex + 1).trim();
    } else {
      mealName = 'Meal ${index + 1}';
      description = suggestion;
    }

    // Different accent colors for each card
    final accentColors = [
      const Color(0xFFFF6B35), // Orange
      const Color(0xFF4CAF50), // Green
      const Color(0xFF2196F3), // Blue
      const Color(0xFF9C27B0), // Purple
    ];
    final accentColor = accentColors[index % accentColors.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showRecipe(context, mealName, accentColor),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Color indicator
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Recipe button
              IconButton(
                onPressed: () => _showRecipe(context, mealName, accentColor),
                icon: Icon(
                  Icons.menu_book_outlined,
                  color: accentColor,
                  size: 22,
                ),
                tooltip: 'View Recipe',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecipe(BuildContext context, String mealName, Color accentColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RecipeBottomSheet(
        mealName: mealName,
        accentColor: accentColor,
      ),
    );
  }

  Future<void> _generateSuggestions() async {
    final config = ref.read(userConfigProvider);
    final overview = ref.read(multiDayNutritionProvider);
    final notifier = ref.read(mealSuggestionsProvider.notifier);

    // Save current preferences
    final prefs = MealPreferences(
      feelLike: _feelLikeController.text.trim(),
      dislike: _dislikeController.text.trim(),
    );
    notifier.setPreferences(widget.selectedDate, prefs);
    notifier.setLoading(widget.selectedDate, true);

    try {
      final service = NutritionService(
        apiKey: config.aiApiKey,
        provider: config.aiProvider,
      );

      // Use preferences string if any preferences are set
      final preferencesString = prefs.isNotEmpty ? prefs.toPreferencesString() : null;
      final suggestions = await service.getAIMealSuggestions(
        overview,
        count: 4,
        preferences: preferencesString,
      );

      if (mounted) {
        notifier.setSuggestions(widget.selectedDate, suggestions);
      }
    } catch (e) {
      if (mounted) {
        notifier.setError(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (dateOnly == today.add(const Duration(days: 1))) return 'Tomorrow';

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

/// Bottom sheet to display a generated recipe
class _RecipeBottomSheet extends ConsumerStatefulWidget {
  const _RecipeBottomSheet({
    required this.mealName,
    required this.accentColor,
  });

  final String mealName;
  final Color accentColor;

  @override
  ConsumerState<_RecipeBottomSheet> createState() => _RecipeBottomSheetState();
}

class _RecipeBottomSheetState extends ConsumerState<_RecipeBottomSheet> {
  MealRecipe? _recipe;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateRecipe();
  }

  Future<void> _generateRecipe() async {
    final config = ref.read(userConfigProvider);
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = NutritionService(
        apiKey: config.aiApiKey,
        provider: config.aiProvider,
      );

      final recipe = await service.generateRecipe(widget.mealName);

      if (mounted) {
        setState(() {
          _recipe = recipe;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    color: widget.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.mealName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_recipe != null)
                        Text(
                          '${_recipe!.totalTime} • ${_recipe!.servings} servings • ${_recipe!.difficulty}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Content
          Flexible(
            child: _isLoading
                ? _buildLoadingState(theme, colorScheme)
                : _error != null
                    ? _buildErrorState(theme, colorScheme)
                    : _buildRecipeContent(theme, colorScheme, bottomPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated cooking icon with spinner
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: widget.accentColor.withValues(alpha: 0.3),
                ),
              ),
              Icon(
                Icons.restaurant,
                size: 28,
                color: widget.accentColor,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Creating your recipe...',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few moments',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          // Progress hints
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: widget.accentColor.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI is crafting ingredients, instructions, and nutrition info just for you',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.error,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _generateRecipe,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeContent(ThemeData theme, ColorScheme colorScheme, double bottomPadding) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nutrition summary
          if (_recipe!.caloriesPerServing != null)
            _buildNutritionSummary(theme, colorScheme),
          
          // Ingredients
          _buildSectionHeader(theme, colorScheme, Icons.shopping_basket_outlined, 'Ingredients'),
          const SizedBox(height: 12),
          _buildIngredientsList(theme, colorScheme),
          
          const SizedBox(height: 24),
          
          // Instructions
          _buildSectionHeader(theme, colorScheme, Icons.format_list_numbered, 'Instructions'),
          const SizedBox(height: 12),
          _buildInstructionsList(theme, colorScheme),
          
          // Tips
          if (_recipe!.tips != null && _recipe!.tips!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildTipsSection(theme, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionSummary(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Per Serving',
            style: theme.textTheme.labelMedium?.copyWith(
              color: widget.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildNutrientPill(theme, colorScheme, '${_recipe!.caloriesPerServing?.toInt() ?? 0}', 'cal'),
              const SizedBox(width: 8),
              _buildNutrientPill(theme, colorScheme, '${_recipe!.proteinPerServing?.toInt() ?? 0}g', 'protein'),
              const SizedBox(width: 8),
              _buildNutrientPill(theme, colorScheme, '${_recipe!.carbsPerServing?.toInt() ?? 0}g', 'carbs'),
              const SizedBox(width: 8),
              _buildNutrientPill(theme, colorScheme, '${_recipe!.fatPerServing?.toInt() ?? 0}g', 'fat'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientPill(ThemeData theme, ColorScheme colorScheme, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, ColorScheme colorScheme, IconData icon, String title) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: widget.accentColor,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsList(ThemeData theme, ColorScheme colorScheme) {
    if (_recipe!.ingredients.isEmpty) {
      return Text(
        'No ingredients available',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _recipe!.ingredients.asMap().entries.map((entry) {
          final index = entry.key;
          final ingredient = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: index < _recipe!.ingredients.length - 1
                  ? Border(
                      bottom: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: widget.accentColor.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ingredient.item,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  ingredient.amount,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInstructionsList(ThemeData theme, ColorScheme colorScheme) {
    if (_recipe!.instructions.isEmpty) {
      return Text(
        'No instructions available',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      children: _recipe!.instructions.asMap().entries.map((entry) {
        final index = entry.key;
        final instruction = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    instruction,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTipsSection(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 20,
            color: Colors.amber[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chef\'s Tip',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.amber[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _recipe!.tips!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
