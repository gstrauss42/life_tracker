import 'package:flutter/material.dart';

import '../../models/models.dart';

/// Enhanced card displaying a single food entry with 3-dot menu actions.
class EnhancedFoodEntryCard extends StatefulWidget {
  const EnhancedFoodEntryCard({
    super.key,
    required this.entry,
    required this.onDelete,
    this.onEdit,
    this.onDuplicate,
  });

  final FoodEntry entry;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;

  @override
  State<EnhancedFoodEntryCard> createState() => _EnhancedFoodEntryCardState();
}

class _EnhancedFoodEntryCardState extends State<EnhancedFoodEntryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovered
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? colorScheme.primary.withValues(alpha: 0.2)
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onEdit,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIcon(colorScheme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildContent(theme, colorScheme),
                  ),
                  _buildCaloriesBadge(theme, colorScheme),
                  _buildMenuButton(context, colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.15),
            colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.restaurant_rounded,
        color: colorScheme.primary,
        size: 20,
      ),
    );
  }

  Widget _buildContent(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final macros = _buildMacrosText();
    
    // Parse the original input to extract meal name and ingredients
    final parsed = _parseOriginalInput();
    final displayName = parsed.mealName ?? widget.entry.name;
    final ingredients = parsed.ingredients;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (ingredients.isNotEmpty) ...[
          const SizedBox(height: 4),
          ...ingredients.map((ingredient) {
            return Text(
              ingredient,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          }),
        ],
        if (macros.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: macros.map((macro) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: macro.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  macro.text,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: macro.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  /// Parse originalInput to extract meal name and ingredients list
  _ParsedFoodInput _parseOriginalInput() {
    final input = widget.entry.originalInput;
    if (input == null || input.isEmpty) {
      return _ParsedFoodInput(null, []);
    }

    String? mealName;
    List<String> ingredients = [];

    // Split by newlines to handle multi-line input
    final lines = input.split('\n');
    
    for (final line in lines) {
      final trimmed = line.trim();
      
      // Check for "Meal: " prefix
      if (trimmed.toLowerCase().startsWith('meal:')) {
        mealName = trimmed.substring(5).trim();
      }
      // Check for "Ingredients: " prefix
      else if (trimmed.toLowerCase().startsWith('ingredients:')) {
        final ingredientsPart = trimmed.substring(12).trim();
        // Split by comma and clean up each ingredient
        ingredients = ingredientsPart
            .split(',')
            .map((i) => i.trim())
            .where((i) => i.isNotEmpty)
            .toList();
      }
    }

    // If no structured format found, try to parse as single line with both parts
    if (mealName == null && ingredients.isEmpty) {
      // Try to find "Meal:" and "Ingredients:" in a single string
      final mealMatch = RegExp(r'Meal:\s*([^,\n]+)', caseSensitive: false).firstMatch(input);
      final ingredientsMatch = RegExp(r'Ingredients:\s*(.+)', caseSensitive: false).firstMatch(input);
      
      if (mealMatch != null) {
        mealName = mealMatch.group(1)?.trim();
      }
      if (ingredientsMatch != null) {
        final ingredientsPart = ingredientsMatch.group(1)?.trim() ?? '';
        ingredients = ingredientsPart
            .split(',')
            .map((i) => i.trim())
            .where((i) => i.isNotEmpty)
            .toList();
      }
    }

    return _ParsedFoodInput(mealName, ingredients);
  }

  Widget _buildCaloriesBadge(ThemeData theme, ColorScheme colorScheme) {
    if (widget.entry.calories == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${widget.entry.calories!.toInt()} kcal',
        style: theme.textTheme.labelMedium?.copyWith(
          color: const Color(0xFFFF6B35),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, ColorScheme colorScheme) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: colorScheme.onSurface.withValues(alpha: 0.5),
        size: 20,
      ),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      position: PopupMenuPosition.under,
      onSelected: (value) {
        switch (value) {
          case 'edit':
            widget.onEdit?.call();
          case 'duplicate':
            widget.onDuplicate?.call();
          case 'delete':
            _showDeleteConfirmation(context);
        }
      },
      itemBuilder: (context) => [
        if (widget.onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 18),
                SizedBox(width: 12),
                Text('Edit'),
              ],
            ),
          ),
        if (widget.onDuplicate != null)
          const PopupMenuItem(
            value: 'duplicate',
            child: Row(
              children: [
                Icon(Icons.copy_outlined, size: 18),
                SizedBox(width: 12),
                Text('Duplicate'),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
              const SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: Colors.red.shade400)),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Remove "${widget.entry.name}" from your food log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete();
            },
            child: Text('Delete', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  List<_MacroInfo> _buildMacrosText() {
    final macros = <_MacroInfo>[];
    if (widget.entry.protein != null) {
      macros.add(_MacroInfo('${widget.entry.protein!.toInt()}g P', const Color(0xFFE91E63)));
    }
    if (widget.entry.carbs != null) {
      macros.add(_MacroInfo('${widget.entry.carbs!.toInt()}g C', const Color(0xFF2196F3)));
    }
    if (widget.entry.fat != null) {
      macros.add(_MacroInfo('${widget.entry.fat!.toInt()}g F', const Color(0xFF9C27B0)));
    }
    return macros;
  }
}

class _MacroInfo {
  const _MacroInfo(this.text, this.color);
  final String text;
  final Color color;
}

class _ParsedFoodInput {
  const _ParsedFoodInput(this.mealName, this.ingredients);
  final String? mealName;
  final List<String> ingredients;
}



