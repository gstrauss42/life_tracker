import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';

/// Grid of available social activity categories.
class CategoryGrid extends ConsumerWidget {
  const CategoryGrid({
    super.key,
    required this.onCategorySelected,
  });

  final void Function(SocialCategory category) onCategorySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(availableCategoriesProvider);
    final config = ref.watch(userConfigProvider);

    return categoriesAsync.when(
      loading: () => _buildLoadingState(context),
      error: (error, stack) => _buildErrorState(context, error, ref),
      data: (categories) {
        if (!config.hasLocation) {
          return _buildNoLocationState(context);
        }
        return _buildCategoryGrid(context, categories);
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: 8,
      itemBuilder: (context, index) => _buildSkeletonTile(context),
    );
  }

  Widget _buildSkeletonTile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error, size: 32),
          const SizedBox(height: 12),
          Text(
            'Failed to load categories',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => ref.invalidate(availableCategoriesProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoLocationState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
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
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off,
              size: 32,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Set your location to discover activities',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Go to Settings → Location to set your city',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context, List<SocialCategory> categories) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    // Adjust columns based on width
    final crossAxisCount = width > 600 ? 5 : (width > 400 ? 4 : 3);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final info = CategoryInfo.getInfo(category);
        return _CategoryTile(
          info: info,
          onTap: () => onCategorySelected(category),
        );
      },
    );
  }
}

class _CategoryTile extends StatefulWidget {
  const _CategoryTile({
    required this.info,
    required this.onTap,
  });

  final CategoryInfo info;
  final VoidCallback onTap;

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  IconData _getCategoryIcon(SocialCategory category) {
    return switch (category) {
      // Food & Drink
      SocialCategory.restaurants => Icons.restaurant,
      SocialCategory.cafes => Icons.local_cafe,
      SocialCategory.bars => Icons.local_bar,
      SocialCategory.nightclubs => Icons.nightlife,
      // Outdoors & Nature
      SocialCategory.beaches => Icons.beach_access,
      SocialCategory.parks => Icons.park,
      SocialCategory.hiking => Icons.hiking,
      SocialCategory.camping => Icons.holiday_village,
      SocialCategory.skiing => Icons.downhill_skiing,
      SocialCategory.surfing => Icons.surfing,
      SocialCategory.lakes => Icons.water,
      SocialCategory.mountains => Icons.landscape,
      // Sports & Fitness
      SocialCategory.gyms => Icons.fitness_center,
      SocialCategory.sportsCourts => Icons.sports_tennis,
      SocialCategory.golfCourses => Icons.golf_course,
      SocialCategory.swimmingPools => Icons.pool,
      // Entertainment
      SocialCategory.cinema => Icons.movie,
      SocialCategory.theatre => Icons.theater_comedy,
      SocialCategory.liveMusic => Icons.music_note,
      SocialCategory.museums => Icons.museum,
      SocialCategory.artGalleries => Icons.palette,
      SocialCategory.arcades => Icons.sports_esports,
      // Social Venues
      SocialCategory.shoppingMalls => Icons.shopping_bag,
      SocialCategory.markets => Icons.storefront,
      SocialCategory.communityEvents => Icons.groups,
      SocialCategory.festivals => Icons.celebration,
      // Wellness
      SocialCategory.spas => Icons.spa,
      SocialCategory.yoga => Icons.self_improvement,
      SocialCategory.meditation => Icons.self_improvement,
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const primaryColor = Color(0xFF26A69A);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: primaryColor.withValues(alpha: 0.1),
            highlightColor: primaryColor.withValues(alpha: 0.05),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: _isHovered
                    ? primaryColor.withValues(alpha: 0.1)
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isHovered
                      ? primaryColor.withValues(alpha: 0.3)
                      : colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: _isHovered ? 1.5 : 1,
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(widget.info.category),
                      size: 20,
                      color: _isHovered ? primaryColor : colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.info.displayName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 9,
                        color: _isHovered ? primaryColor : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

