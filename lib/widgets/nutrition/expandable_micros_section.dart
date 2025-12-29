import 'package:flutter/material.dart';

import '../../models/models.dart';

/// Expandable section showing micronutrients with warning indicators.
class ExpandableMicrosSection extends StatefulWidget {
  const ExpandableMicrosSection({
    super.key,
    required this.nutrition,
  });

  final NutritionSummary nutrition;

  @override
  State<ExpandableMicrosSection> createState() => _ExpandableMicrosSectionState();
}

class _ExpandableMicrosSectionState extends State<ExpandableMicrosSection>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rec = NutritionSummary.recommendedDaily;

    final allMicros = [
      // Key nutrients (shown first)
      _MicroData('Fiber', widget.nutrition.fiber, rec.fiber, 'g', const Color(0xFF4CAF50)),
      _MicroData('Vitamin C', widget.nutrition.vitaminC, rec.vitaminC, 'mg', const Color(0xFFFF9800)),
      _MicroData('Vitamin D', widget.nutrition.vitaminD, rec.vitaminD, 'mcg', const Color(0xFFFFC107)),
      _MicroData('Iron', widget.nutrition.iron, rec.iron, 'mg', const Color(0xFF795548)),
      // Minerals
      _MicroData('Calcium', widget.nutrition.calcium, rec.calcium, 'mg', const Color(0xFF00BCD4)),
      _MicroData('Potassium', widget.nutrition.potassium, rec.potassium, 'mg', const Color(0xFF9C27B0)),
      _MicroData('Magnesium', widget.nutrition.magnesium, rec.magnesium, 'mg', const Color(0xFF607D8B)),
      _MicroData('Zinc', widget.nutrition.zinc, rec.zinc, 'mg', const Color(0xFF8D6E63)),
      _MicroData('Phosphorus', widget.nutrition.phosphorus, rec.phosphorus, 'mg', const Color(0xFF78909C)),
      _MicroData('Selenium', widget.nutrition.selenium, rec.selenium, 'mcg', const Color(0xFF455A64)),
      _MicroData('Iodine', widget.nutrition.iodine, rec.iodine, 'mcg', const Color(0xFF546E7A)),
      // More vitamins
      _MicroData('Vitamin A', widget.nutrition.vitaminA, rec.vitaminA, 'mcg', const Color(0xFFE65100)),
      _MicroData('Vitamin E', widget.nutrition.vitaminE, rec.vitaminE, 'mg', const Color(0xFF7CB342)),
      _MicroData('Vitamin K', widget.nutrition.vitaminK, rec.vitaminK, 'mcg', const Color(0xFF558B2F)),
      _MicroData('B1 (Thiamin)', widget.nutrition.vitaminB1, rec.vitaminB1, 'mg', const Color(0xFF5E35B1)),
      _MicroData('B2 (Riboflavin)', widget.nutrition.vitaminB2, rec.vitaminB2, 'mg', const Color(0xFF512DA8)),
      _MicroData('B3 (Niacin)', widget.nutrition.vitaminB3, rec.vitaminB3, 'mg', const Color(0xFF4527A0)),
      _MicroData('Vitamin B6', widget.nutrition.vitaminB6, rec.vitaminB6, 'mg', const Color(0xFF311B92)),
      _MicroData('B12', widget.nutrition.vitaminB12, rec.vitaminB12, 'mcg', const Color(0xFFD81B60)),
      _MicroData('Folate', widget.nutrition.folate, rec.folate, 'mcg', const Color(0xFFC2185B)),
      // Fatty acids
      _MicroData('Omega-3', widget.nutrition.omega3, rec.omega3, 'g', const Color(0xFF0097A7)),
      // Limit nutrients (shown last)
      _MicroData('Sodium', widget.nutrition.sodium, rec.sodium, 'mg', const Color(0xFFE91E63)),
      _MicroData('Sugar', widget.nutrition.sugar, rec.sugar, 'g', const Color(0xFFFF5722)),
    ];

    final warnings = allMicros.where((m) => m.percentage < 50 && m.label != 'Sodium' && m.label != 'Sugar').length;
    final initialMicros = allMicros.take(4).toList();
    final remainingMicros = allMicros.skip(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with warning badge
        InkWell(
          onTap: _toggleExpanded,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(
                  'Micronutrients',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                if (warnings > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '$warnings low',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.orange.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Initial micros (always visible)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: initialMicros.map((m) => _MicroChip(data: m)).toList(),
        ),
        // Expandable remaining micros
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: remainingMicros.map((m) => _MicroChip(data: m)).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MicroData {
  const _MicroData(this.label, this.current, this.goal, this.unit, this.color);
  final String label;
  final double current;
  final double goal;
  final String unit;
  final Color color;

  double get percentage => goal > 0 ? (current / goal * 100).clamp(0, 200) : 0;
  bool get isLow => percentage < 50;
  bool get isGood => percentage >= 70;

  /// Format value intelligently - show decimals for small values
  String get formattedCurrent {
    if (current == 0) return '0';
    if (current >= 10) return current.toStringAsFixed(0);
    if (current >= 1) return current.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    if (current >= 0.1) return current.toStringAsFixed(1);
    return '<0.1';
  }

  String get formattedGoal {
    if (goal >= 10) return goal.toStringAsFixed(0);
    if (goal >= 1) return goal.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    return goal.toStringAsFixed(1);
  }
}

class _MicroChip extends StatelessWidget {
  const _MicroChip({required this.data});

  final _MicroData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 100,
        maxWidth: 140,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: data.isLow
              ? Colors.orange.withValues(alpha: 0.08)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: data.isLow
                ? Colors.orange.withValues(alpha: 0.3)
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    data.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (data.isLow) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.warning_amber, size: 12, color: Colors.orange.shade600),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '${data.formattedCurrent}${data.unit}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: data.isLow ? Colors.orange.shade700 : data.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ ${data.formattedGoal}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (data.percentage / 100).clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: data.color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  data.isLow ? Colors.orange : data.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



