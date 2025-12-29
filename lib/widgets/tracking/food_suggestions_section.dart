import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../services/services.dart';

/// Section for generating AI meal suggestions.
class FoodSuggestionsSection extends ConsumerStatefulWidget {
  const FoodSuggestionsSection({
    super.key,
  });

  @override
  ConsumerState<FoodSuggestionsSection> createState() => _FoodSuggestionsSectionState();
}

class _FoodSuggestionsSectionState extends ConsumerState<FoodSuggestionsSection> {
  List<String>? _aiSuggestions;
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final config = ref.watch(userConfigProvider);

    // Don't show if no API key configured
    if (config.aiApiKey == null || config.aiApiKey!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
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
            const Spacer(),
            if (_aiSuggestions != null && !_isLoading)
              IconButton(
                onPressed: _clearSuggestions,
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                tooltip: 'Clear suggestions',
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Content
        if (_isLoading)
          _buildLoadingState(context, theme, colorScheme)
        else if (_error != null)
          _buildErrorState(context, theme, colorScheme)
        else if (_aiSuggestions != null)
          _buildSuggestionsGrid(context, theme, colorScheme)
        else
          _buildGenerateButton(context, theme, colorScheme),
      ],
    );
  }

  Widget _buildGenerateButton(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _generateSuggestions,
        icon: const Icon(Icons.restaurant_menu, size: 18),
        label: const Text('Generate Meal Ideas'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
        ),
      ),
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

  Widget _buildErrorState(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
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
            _error!,
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

  Widget _buildSuggestionsGrid(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        // Grid of 4 suggestions
        ...List.generate(_aiSuggestions!.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index < _aiSuggestions!.length - 1 ? 10 : 0),
            child: _buildSuggestionCard(context, theme, colorScheme, _aiSuggestions![index], index),
          );
        }),
        const SizedBox(height: 12),
        // Regenerate button
        TextButton.icon(
          onPressed: _generateSuggestions,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Generate New Ideas'),
        ),
      ],
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

    setState(() {
      _isLoading = true;
      _error = null;
      _aiSuggestions = null;
    });

    try {
      final service = NutritionService(
        apiKey: config.aiApiKey,
        provider: config.aiProvider,
      );

      final suggestions = await service.getAIMealSuggestions(overview, count: 4);

      if (mounted) {
        setState(() {
          _aiSuggestions = suggestions;
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

  void _clearSuggestions() {
    setState(() {
      _aiSuggestions = null;
      _error = null;
    });
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
