import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import 'place_card.dart';

/// Rotating positive loading messages for AI discovery
const _loadingMessages = [
  'Finding the best spots for you...',
  'Curating personalized recommendations...',
  'Discovering hidden gems nearby...',
  'Searching for top-rated places...',
  'Exploring local favorites...',
  'Matching your vibe...',
];

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

/// List view showing discovered places for a category.
class PlacesListView extends ConsumerStatefulWidget {
  const PlacesListView({
    super.key,
    required this.category,
    required this.onLogActivity,
  });

  final SocialCategory category;
  final void Function(DiscoveredPlace place) onLogActivity;

  @override
  ConsumerState<PlacesListView> createState() => _PlacesListViewState();
}

class _PlacesListViewState extends ConsumerState<PlacesListView> {
  int _currentMessageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _startMessageRotation();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  void _startMessageRotation() {
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _loadingMessages.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final placesAsync = ref.watch(discoveredPlacesProvider(widget.category));

    return placesAsync.when(
      loading: () => _buildLoadingState(context),
      error: (error, stack) => _buildErrorState(context, error, ref),
      data: (places) {
        if (places.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildPlacesList(context, places);
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryInfo = CategoryInfo.getInfo(widget.category);
    const accentColor = Color(0xFF26A69A);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Animated icon with spinner overlay
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  Icon(
                    _getCategoryIcon(widget.category),
                    size: 28,
                    color: accentColor,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Rotating message with animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _loadingMessages[_currentMessageIndex],
                  key: ValueKey(_currentMessageIndex),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              // Progress hints container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: accentColor.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI is searching for the best ${categoryInfo.displayName.toLowerCase()} near you',
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
        ),
        const SizedBox(height: 16),
        // Skeleton cards
        ...List.generate(3, (index) => _buildSkeletonCard(context)),
      ],
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 200,
                height: 20,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 14,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 150,
                height: 14,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
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
          Icon(Icons.error_outline, color: colorScheme.error, size: 40),
          const SizedBox(height: 16),
          Text(
            'Failed to discover places',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString().length > 100
                ? '${error.toString().substring(0, 100)}...'
                : error.toString(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => ref.invalidate(discoveredPlacesProvider(widget.category)),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryInfo = CategoryInfo.getInfo(widget.category);

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
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(widget.category),
              size: 32,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${categoryInfo.displayName.toLowerCase()} found',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different category or check back later',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacesList(BuildContext context, List<DiscoveredPlace> places) {
    return Column(
      children: places.asMap().entries.map((entry) {
        final index = entry.key;
        final place = entry.value;
        final isLast = index == places.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: PlaceCard(
            place: place,
            onLogActivity: () => widget.onLogActivity(place),
          ),
        );
      }).toList(),
    );
  }
}

