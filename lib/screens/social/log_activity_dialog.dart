import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';

/// Dialog for logging a social activity.
class LogActivityDialog extends ConsumerStatefulWidget {
  const LogActivityDialog({
    super.key,
    this.place,
    this.category,
    required this.onSubmit,
  });

  final DiscoveredPlace? place;
  final SocialCategory? category;
  final void Function(SocialActivity activity) onSubmit;

  @override
  ConsumerState<LogActivityDialog> createState() => _LogActivityDialogState();
}

class _LogActivityDialogState extends ConsumerState<LogActivityDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late SocialCategory _selectedCategory;
  int _durationMinutes = 30;
  DateTime _timestamp = DateTime.now();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.place?.name ?? '');
    _notesController = TextEditingController();
    _selectedCategory = widget.place?.category ?? widget.category ?? SocialCategory.restaurants;
  }

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
    const primaryColor = Color(0xFF26A69A);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
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
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_task, color: primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.place != null ? 'Log Activity' : 'Add Activity',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Activity name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Activity Name',
                hintText: 'e.g., Coffee with friends',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.edit_outlined),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Category dropdown
            DropdownButtonFormField<SocialCategory>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(
                  _getCategoryIcon(_selectedCategory),
                  color: primaryColor,
                ),
              ),
              items: SocialCategory.values.map((category) {
                final info = CategoryInfo.getInfo(category);
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(_getCategoryIcon(category), size: 20),
                      const SizedBox(width: 8),
                      Text(info.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Duration
            Text(
              'Duration',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _durationMinutes > 5
                        ? () => setState(() => _durationMinutes -= 5)
                        : null,
                    icon: const Icon(Icons.remove),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$_durationMinutes',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          'minutes',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _durationMinutes += 5),
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Quick duration buttons
            Wrap(
              spacing: 8,
              children: [15, 30, 45, 60, 90, 120].map((minutes) {
                final isSelected = _durationMinutes == minutes;
                return ChoiceChip(
                  label: Text('${minutes}m'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _durationMinutes = minutes);
                    }
                  },
                  selectedColor: primaryColor.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Notes (optional)
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Any additional details...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: const Text('Log Activity'),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an activity name')),
      );
      return;
    }

    final activity = SocialActivity(
      id: const Uuid().v4(),
      name: name,
      category: _selectedCategory,
      timestamp: _timestamp,
      durationMinutes: _durationMinutes,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      placeId: widget.place?.id,
    );

    widget.onSubmit(activity);
  }

  IconData _getCategoryIcon(SocialCategory category) {
    return switch (category) {
      SocialCategory.restaurants => Icons.restaurant,
      SocialCategory.cafes => Icons.local_cafe,
      SocialCategory.bars => Icons.local_bar,
      SocialCategory.nightclubs => Icons.nightlife,
      SocialCategory.beaches => Icons.beach_access,
      SocialCategory.parks => Icons.park,
      SocialCategory.hiking => Icons.hiking,
      SocialCategory.camping => Icons.holiday_village,
      SocialCategory.skiing => Icons.downhill_skiing,
      SocialCategory.surfing => Icons.surfing,
      SocialCategory.lakes => Icons.water,
      SocialCategory.mountains => Icons.landscape,
      SocialCategory.gyms => Icons.fitness_center,
      SocialCategory.sportsCourts => Icons.sports_tennis,
      SocialCategory.golfCourses => Icons.golf_course,
      SocialCategory.swimmingPools => Icons.pool,
      SocialCategory.cinema => Icons.movie,
      SocialCategory.theatre => Icons.theater_comedy,
      SocialCategory.liveMusic => Icons.music_note,
      SocialCategory.museums => Icons.museum,
      SocialCategory.artGalleries => Icons.palette,
      SocialCategory.arcades => Icons.sports_esports,
      SocialCategory.shoppingMalls => Icons.shopping_bag,
      SocialCategory.markets => Icons.storefront,
      SocialCategory.communityEvents => Icons.groups,
      SocialCategory.festivals => Icons.celebration,
      SocialCategory.spas => Icons.spa,
      SocialCategory.yoga => Icons.self_improvement,
      SocialCategory.meditation => Icons.self_improvement,
    };
  }
}

