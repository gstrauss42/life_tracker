import 'package:flutter/material.dart';

import '../../models/exercise_models.dart';

/// Dialog for manually logging an exercise activity.
class LogExerciseDialog extends StatefulWidget {
  const LogExerciseDialog({
    super.key,
    required this.onSave,
  });

  final void Function(ExerciseActivity activity) onSave;

  @override
  State<LogExerciseDialog> createState() => _LogExerciseDialogState();
}

class _LogExerciseDialogState extends State<LogExerciseDialog> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  int _selectedDuration = 30;

  static const Color exerciseColor = Color(0xFFEF5350);

  // Preset durations
  final List<int> _durationOptions = [10, 15, 20, 30, 45, 60];

  // Common activity suggestions
  final List<String> _activitySuggestions = [
    'Walking',
    'Running',
    'Cycling',
    'Yoga',
    'HIIT Workout',
    'Strength Training',
    'Swimming',
    'Stretching',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: exerciseColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: exerciseColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Log Exercise',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Activity name input
              Text(
                'Activity Name',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g., Morning Run, Yoga Session',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              // Activity suggestions
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _activitySuggestions.map((suggestion) {
                  return ActionChip(
                    label: Text(suggestion),
                    onPressed: () {
                      _nameController.text = suggestion;
                    },
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Duration selection
              Text(
                'Duration',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _durationOptions.map((duration) {
                  final isSelected = _selectedDuration == duration;
                  return ChoiceChip(
                    label: Text('$duration min'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedDuration = duration);
                      }
                    },
                    selectedColor: exerciseColor.withValues(alpha: 0.2),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    side: BorderSide(
                      color: isSelected
                          ? exerciseColor
                          : colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? exerciseColor : null,
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Notes (optional)
              Text(
                'Notes (optional)',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'How did it go?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: exerciseColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an activity name')),
      );
      return;
    }

    final notes = _notesController.text.trim();
    final activity = ExerciseActivity.create(
      name: name,
      durationMinutes: _selectedDuration,
      notes: notes.isEmpty ? null : notes,
    );

    widget.onSave(activity);
    Navigator.pop(context);
  }
}


