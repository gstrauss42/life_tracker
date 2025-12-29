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

    final hasOriginalInput = widget.entry.originalInput != null &&
        widget.entry.originalInput!.isNotEmpty &&
        widget.entry.originalInput != widget.entry.name;

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
                    child: _buildContent(theme, colorScheme, hasOriginalInput),
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
    bool hasOriginalInput,
  ) {
    final macros = _buildMacrosText();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.entry.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (hasOriginalInput) ...[
          const SizedBox(height: 3),
          Text(
            widget.entry.originalInput!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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



