import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive/breakpoints.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import 'category_grid.dart';
import 'places_list_view.dart';
import 'custom_query_places_view.dart';
import 'social_progress_card.dart';
import 'log_activity_dialog.dart';

/// Social & Activities discovery panel.
/// Follows the same pattern as FoodDetailView.
class SocialPanel extends ConsumerStatefulWidget {
  const SocialPanel({
    super.key,
    required this.onClose,
    this.selectedDate,
  });

  final VoidCallback onClose;
  final DateTime? selectedDate;

  @override
  ConsumerState<SocialPanel> createState() => _SocialPanelState();
}

class _SocialPanelState extends ConsumerState<SocialPanel> {
  SocialCategory? _selectedCategory;
  String? _customQuery;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleCustomSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _customQuery = query;
        _selectedCategory = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isCompact = Breakpoints.isMobile(width);
    final config = ref.watch(userConfigProvider);

    return Container(
      color: colorScheme.surface,
      child: Column(
        children: [
          _buildHeader(context, theme, colorScheme),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isCompact ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress card
                  const SocialProgressCard(),
                  const SizedBox(height: 20),

                  // Location display & categories or places
                  if (_selectedCategory != null)
                    _buildPlacesView(context, theme, colorScheme)
                  else if (_customQuery != null)
                    _buildCustomQueryView(context, theme, colorScheme)
                  else
                    _buildCategoriesView(context, theme, colorScheme, config),

                  const SizedBox(height: 24),

                  // Activity log section
                  _buildActivityLogSection(context, theme, colorScheme),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final dateText = widget.selectedDate != null ? _formatDate(widget.selectedDate!) : 'Today';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Hero(
            tag: 'social_icon',
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF26A69A).withValues(alpha: 0.15),
                    const Color(0xFF26A69A).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.explore,
                color: Color(0xFF26A69A),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Social & Activities',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dateText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesView(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    UserConfig config,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with AI badge and location
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildAiBadge(theme, colorScheme),
            if (config.hasLocation)
              _buildLocationChip(theme, colorScheme, config),
          ],
        ),
        const SizedBox(height: 16),

        // Custom search input
        _buildSearchInput(context, theme, colorScheme),
        const SizedBox(height: 20),

        // Divider with "or browse categories"
        _buildDividerWithText(theme, colorScheme, 'or browse categories'),
        const SizedBox(height: 16),

        // Category grid
        CategoryGrid(
          onCategorySelected: (category) {
            setState(() {
              _selectedCategory = category;
              _customQuery = null;
            });
          },
        ),

        // Hint text below grid
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Tap any for personalized recommendations',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.45),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiBadge(ThemeData theme, ColorScheme colorScheme) {
    const accentColor = Color(0xFF26A69A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.15),
            accentColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 14,
            color: accentColor,
          ),
          const SizedBox(width: 6),
          Text(
            'AI-Powered Discovery',
            style: theme.textTheme.labelSmall?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    const accentColor = Color(0xFF26A69A);
    
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _handleCustomSearch(),
            decoration: InputDecoration(
              hintText: '"fun night out", "casual dinner", "family activity"...',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                fontStyle: FontStyle.italic,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _handleCustomSearch,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Discover'),
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDividerWithText(
    ThemeData theme,
    ColorScheme colorScheme,
    String text,
  ) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomQueryView(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button and query header
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() {
                _customQuery = null;
                _searchController.clear();
              }),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to categories',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.auto_awesome,
              size: 24,
              color: Color(0xFF26A69A),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '"$_customQuery"',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomQueryPlacesView(
          query: _customQuery!,
          onLogActivity: (place) => _showLogActivityDialog(context, place: place),
        ),
      ],
    );
  }

  Widget _buildLocationChip(ThemeData theme, ColorScheme colorScheme, UserConfig config) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, size: 14, color: colorScheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              config.locationCity ?? 'Location',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacesView(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final categoryInfo = CategoryInfo.getInfo(_selectedCategory!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button and category header
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _selectedCategory = null),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to categories',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              _getCategoryIcon(_selectedCategory!),
              size: 24,
              color: const Color(0xFF26A69A),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                categoryInfo.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PlacesListView(
          category: _selectedCategory!,
          onLogActivity: (place) => _showLogActivityDialog(context, place: place),
        ),
      ],
    );
  }

  Widget _buildActivityLogSection(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final activities = ref.watch(todaySocialActivitiesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 280;
            return Row(
              children: [
                Flexible(
                  child: Text(
                    'Activity Log',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (activities.isNotEmpty && !isNarrow)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${activities.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const Spacer(),
                isNarrow
                    ? IconButton.filled(
                        onPressed: () => _showLogActivityDialog(context),
                        icon: const Icon(Icons.add, size: 20),
                        tooltip: 'Log Activity',
                      )
                    : FilledButton.icon(
                        onPressed: () => _showLogActivityDialog(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Log'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        if (activities.isEmpty)
          _buildEmptyActivityState(context, theme, colorScheme)
        else
          _buildActivityList(context, theme, colorScheme, activities),
      ],
    );
  }

  Widget _buildEmptyActivityState(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 32,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No activities logged today',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover places above or tap "Log Activity" to track your social time',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    List<SocialActivity> activities,
  ) {
    return Column(
      children: activities.asMap().entries.map((entry) {
        final index = entry.key;
        final activity = entry.value;
        final isLast = index == activities.length - 1;
        final categoryInfo = CategoryInfo.getInfo(activity.category);

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
          child: Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF26A69A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(activity.category),
                  color: const Color(0xFF26A69A),
                  size: 20,
                ),
              ),
              title: Text(
                activity.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '${activity.durationMinutes ?? 0} min • ${_formatTime(activity.timestamp)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: colorScheme.error.withValues(alpha: 0.7),
                  size: 20,
                ),
                onPressed: () {
                  ref.read(todaySocialActivitiesProvider.notifier).removeActivity(activity.id);
                },
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showLogActivityDialog(BuildContext context, {DiscoveredPlace? place}) {
    showDialog(
      context: context,
      builder: (context) => LogActivityDialog(
        place: place,
        category: _selectedCategory,
        onSubmit: (activity) {
          ref.read(todaySocialActivitiesProvider.notifier).addActivity(activity);
          Navigator.pop(context);
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
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

