import 'package:flutter/material.dart';

import '../../services/nutrition_service.dart';

/// Bottom sheet for adding food with ingredients.
class AddFoodSheet extends StatefulWidget {
  const AddFoodSheet({
    super.key,
    required this.onSubmit,
  });

  final Future<void> Function(
    String mealName,
    List<StructuredIngredient> ingredients,
    String description,
  ) onSubmit;

  @override
  State<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<AddFoodSheet> {
  final _mealNameController = TextEditingController();
  final List<_Ingredient> _ingredients = [];
  bool _isSubmitting = false;

  static const _units = ['g', 'kg', 'oz', 'lb', 'ml', 'L', 'cups', 'tbsp', 'tsp', 'units'];

  @override
  void dispose() {
    _mealNameController.dispose();
    for (final i in _ingredients) {
      i.dispose();
    }
    super.dispose();
  }

  void _addIngredient() {
    setState(() => _ingredients.add(_Ingredient()));
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients[index].dispose();
      _ingredients.removeAt(index);
    });
  }

  String _buildDescription() {
    final mealName = _mealNameController.text.trim();
    final ingredientDescriptions = _ingredients
        .where((i) => !i.isEmpty)
        .map((i) => i.toDescription())
        .toList();

    if (ingredientDescriptions.isEmpty && mealName.isEmpty) return '';

    final buffer = StringBuffer();
    if (mealName.isNotEmpty) {
      buffer.write('Meal: $mealName');
      if (ingredientDescriptions.isNotEmpty) buffer.write('\nIngredients: ');
    }
    if (ingredientDescriptions.isNotEmpty) {
      buffer.write(ingredientDescriptions.join(', '));
    }
    return buffer.toString();
  }

  Future<void> _submit() async {
    final description = _buildDescription();
    if (description.isEmpty) return;

    setState(() => _isSubmitting = true);

    final structuredIngredients = _ingredients
        .where((i) => i.name.isNotEmpty)
        .map((i) => StructuredIngredient(
              name: i.name,
              amount: double.tryParse(i.amount) ?? 0,
              unit: i.unit,
            ))
        .toList();

    await widget.onSubmit(_mealNameController.text.trim(), structuredIngredients, description);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(colorScheme),
              _buildHeader(theme, colorScheme),
              Flexible(child: _buildContent(theme, colorScheme)),
              _buildSubmitButton(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.restaurant_rounded, color: colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            'Log Meal',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _mealNameController,
            decoration: InputDecoration(
              hintText: 'Meal name (e.g., Lunch, Dinner)',
              hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4)),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Text(
            'Ingredients',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...List.generate(_ingredients.length, (index) {
            return _buildIngredientRow(theme, colorScheme, index);
          }),
          Center(
            child: TextButton.icon(
              onPressed: _addIngredient,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Ingredient'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildIngredientRow(ThemeData theme, ColorScheme colorScheme, int index) {
    final ingredient = _ingredients[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: TextField(
              controller: ingredient.nameController,
              decoration: InputDecoration(
                hintText: 'Ingredient',
                hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4)),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                isDense: true,
              ),
              style: theme.textTheme.bodyMedium,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: TextField(
              controller: ingredient.amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3)),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                isDense: true,
              ),
              style: theme.textTheme.bodyMedium,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: ButtonTheme(
                alignedDropdown: true,
                child: DropdownButton<String>(
                  value: ingredient.unit,
                  isDense: false,
                  borderRadius: BorderRadius.circular(10),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  items: _units
                      .map((unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit, style: theme.textTheme.bodyMedium),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => ingredient.unit = value);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => _removeIngredient(index),
            icon: Icon(Icons.close, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.4)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _isSubmitting || _buildDescription().isEmpty ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.auto_awesome, size: 18),
          label: Text(_isSubmitting ? 'Analyzing...' : 'Analyze & Add'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}

class _Ingredient {
  final TextEditingController nameController;
  final TextEditingController amountController;
  String unit;

  _Ingredient({String name = '', String amount = '', this.unit = 'g'})
      : nameController = TextEditingController(text: name),
        amountController = TextEditingController(text: amount);

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }

  String get name => nameController.text.trim();
  String get amount => amountController.text.trim();
  bool get isEmpty => name.isEmpty;

  String toDescription() {
    if (isEmpty) return '';
    if (amount.isEmpty) return name;
    return '$amount $unit of $name';
  }
}

