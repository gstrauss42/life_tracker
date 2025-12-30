import 'package:uuid/uuid.dart';

/// Activity categories for social discovery
enum SocialCategory {
  // Food & Drink
  restaurants,
  cafes,
  bars,
  nightclubs,

  // Outdoors & Nature
  beaches,
  parks,
  hiking,
  camping,
  skiing,
  surfing,
  lakes,
  mountains,

  // Sports & Fitness
  gyms,
  sportsCourts,
  golfCourses,
  swimmingPools,

  // Entertainment
  cinema,
  theatre,
  liveMusic,
  museums,
  artGalleries,
  arcades,

  // Social Venues
  shoppingMalls,
  markets,
  communityEvents,
  festivals,

  // Wellness
  spas,
  yoga,
  meditation,
}

/// Information about a social category
class CategoryInfo {
  const CategoryInfo({
    required this.category,
    required this.displayName,
    required this.emoji,
    required this.searchTerms,
    this.icon,
  });

  final SocialCategory category;
  final String displayName;
  final String emoji;
  final String searchTerms; // For AI web search
  final String? icon;

  /// Get all category info
  static List<CategoryInfo> get all => _categoryInfoMap.values.toList();

  /// Get info for a specific category
  static CategoryInfo getInfo(SocialCategory category) {
    return _categoryInfoMap[category] ??
        CategoryInfo(
          category: category,
          displayName: category.name,
          emoji: '📍',
          searchTerms: category.name,
        );
  }

  static final Map<SocialCategory, CategoryInfo> _categoryInfoMap = {
    // Food & Drink
    SocialCategory.restaurants: const CategoryInfo(
      category: SocialCategory.restaurants,
      displayName: 'Restaurants',
      emoji: '🍽️',
      searchTerms: 'restaurants, dining, eateries, food places',
    ),
    SocialCategory.cafes: const CategoryInfo(
      category: SocialCategory.cafes,
      displayName: 'Cafes',
      emoji: '☕',
      searchTerms: 'cafes, coffee shops, tea houses, bakeries',
    ),
    SocialCategory.bars: const CategoryInfo(
      category: SocialCategory.bars,
      displayName: 'Bars',
      emoji: '🍸',
      searchTerms: 'bars, pubs, cocktail lounges, wine bars',
    ),
    SocialCategory.nightclubs: const CategoryInfo(
      category: SocialCategory.nightclubs,
      displayName: 'Nightclubs',
      emoji: '🎉',
      searchTerms: 'nightclubs, clubs, dance clubs, nightlife venues',
    ),

    // Outdoors & Nature
    SocialCategory.beaches: const CategoryInfo(
      category: SocialCategory.beaches,
      displayName: 'Beaches',
      emoji: '🏖️',
      searchTerms: 'beaches, seaside, coastal, swimming spots, shore',
    ),
    SocialCategory.parks: const CategoryInfo(
      category: SocialCategory.parks,
      displayName: 'Parks',
      emoji: '🌳',
      searchTerms: 'parks, gardens, green spaces, nature reserves',
    ),
    SocialCategory.hiking: const CategoryInfo(
      category: SocialCategory.hiking,
      displayName: 'Hiking',
      emoji: '🥾',
      searchTerms: 'hiking trails, walking paths, nature walks, trekking routes',
    ),
    SocialCategory.camping: const CategoryInfo(
      category: SocialCategory.camping,
      displayName: 'Camping',
      emoji: '⛺',
      searchTerms: 'camping sites, campgrounds, outdoor camping, glamping',
    ),
    SocialCategory.skiing: const CategoryInfo(
      category: SocialCategory.skiing,
      displayName: 'Skiing',
      emoji: '⛷️',
      searchTerms: 'ski resorts, skiing, snowboarding, winter sports',
    ),
    SocialCategory.surfing: const CategoryInfo(
      category: SocialCategory.surfing,
      displayName: 'Surfing',
      emoji: '🏄',
      searchTerms: 'surfing spots, surf beaches, surf schools, wave spots',
    ),
    SocialCategory.lakes: const CategoryInfo(
      category: SocialCategory.lakes,
      displayName: 'Lakes',
      emoji: '🏞️',
      searchTerms: 'lakes, reservoirs, dams, water bodies, lakeside',
    ),
    SocialCategory.mountains: const CategoryInfo(
      category: SocialCategory.mountains,
      displayName: 'Mountains',
      emoji: '🏔️',
      searchTerms: 'mountains, peaks, viewpoints, mountain trails',
    ),

    // Sports & Fitness
    SocialCategory.gyms: const CategoryInfo(
      category: SocialCategory.gyms,
      displayName: 'Gyms',
      emoji: '💪',
      searchTerms: 'gyms, fitness centers, workout facilities, health clubs',
    ),
    SocialCategory.sportsCourts: const CategoryInfo(
      category: SocialCategory.sportsCourts,
      displayName: 'Sports Courts',
      emoji: '🎾',
      searchTerms: 'tennis courts, basketball courts, sports facilities',
    ),
    SocialCategory.golfCourses: const CategoryInfo(
      category: SocialCategory.golfCourses,
      displayName: 'Golf Courses',
      emoji: '⛳',
      searchTerms: 'golf courses, golf clubs, driving ranges',
    ),
    SocialCategory.swimmingPools: const CategoryInfo(
      category: SocialCategory.swimmingPools,
      displayName: 'Swimming Pools',
      emoji: '🏊',
      searchTerms: 'swimming pools, aquatic centers, public pools',
    ),

    // Entertainment
    SocialCategory.cinema: const CategoryInfo(
      category: SocialCategory.cinema,
      displayName: 'Cinema',
      emoji: '🎬',
      searchTerms: 'cinemas, movie theaters, film screenings',
    ),
    SocialCategory.theatre: const CategoryInfo(
      category: SocialCategory.theatre,
      displayName: 'Theatre',
      emoji: '🎭',
      searchTerms: 'theaters, playhouses, drama venues, performing arts',
    ),
    SocialCategory.liveMusic: const CategoryInfo(
      category: SocialCategory.liveMusic,
      displayName: 'Live Music',
      emoji: '🎵',
      searchTerms: 'live music venues, concert halls, music bars, gigs',
    ),
    SocialCategory.museums: const CategoryInfo(
      category: SocialCategory.museums,
      displayName: 'Museums',
      emoji: '🏛️',
      searchTerms: 'museums, exhibitions, cultural centers, history museums',
    ),
    SocialCategory.artGalleries: const CategoryInfo(
      category: SocialCategory.artGalleries,
      displayName: 'Art Galleries',
      emoji: '🎨',
      searchTerms: 'art galleries, art exhibitions, art museums',
    ),
    SocialCategory.arcades: const CategoryInfo(
      category: SocialCategory.arcades,
      displayName: 'Arcades',
      emoji: '🕹️',
      searchTerms: 'arcades, gaming centers, entertainment centers',
    ),

    // Social Venues
    SocialCategory.shoppingMalls: const CategoryInfo(
      category: SocialCategory.shoppingMalls,
      displayName: 'Shopping',
      emoji: '🛍️',
      searchTerms: 'shopping malls, shopping centers, retail complexes',
    ),
    SocialCategory.markets: const CategoryInfo(
      category: SocialCategory.markets,
      displayName: 'Markets',
      emoji: '🏪',
      searchTerms: 'markets, farmers markets, flea markets, craft markets',
    ),
    SocialCategory.communityEvents: const CategoryInfo(
      category: SocialCategory.communityEvents,
      displayName: 'Community Events',
      emoji: '🎪',
      searchTerms: 'community events, local gatherings, meetups, social events',
    ),
    SocialCategory.festivals: const CategoryInfo(
      category: SocialCategory.festivals,
      displayName: 'Festivals',
      emoji: '🎊',
      searchTerms: 'festivals, celebrations, cultural events, fairs',
    ),

    // Wellness
    SocialCategory.spas: const CategoryInfo(
      category: SocialCategory.spas,
      displayName: 'Spas',
      emoji: '💆',
      searchTerms: 'spas, wellness centers, massage, relaxation',
    ),
    SocialCategory.yoga: const CategoryInfo(
      category: SocialCategory.yoga,
      displayName: 'Yoga',
      emoji: '🧘',
      searchTerms: 'yoga studios, yoga classes, yoga retreats',
    ),
    SocialCategory.meditation: const CategoryInfo(
      category: SocialCategory.meditation,
      displayName: 'Meditation',
      emoji: '🧘‍♂️',
      searchTerms: 'meditation centers, mindfulness classes, zen centers',
    ),
  };
}

/// A discovered place/venue
class DiscoveredPlace {
  const DiscoveredPlace({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.rating,
    this.priceLevel,
    this.tags = const [],
    this.website,
    this.openNow,
    required this.category,
    required this.discoveredAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? address;
  final double? rating;
  final String? priceLevel; // $, $$, $$$, $$$$
  final List<String> tags;
  final String? website;
  final bool? openNow;
  final SocialCategory category;
  final DateTime discoveredAt;

  factory DiscoveredPlace.fromJson(
    Map<String, dynamic> json,
    SocialCategory category,
  ) {
    return DiscoveredPlace(
      id: const Uuid().v4(),
      name: json['name'] as String? ?? 'Unknown Place',
      description: json['description'] as String?,
      address: json['address'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      priceLevel: json['priceLevel'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      website: json['website'] as String?,
      openNow: json['openNow'] as bool?,
      category: category,
      discoveredAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'rating': rating,
      'priceLevel': priceLevel,
      'tags': tags,
      'website': website,
      'openNow': openNow,
      'category': category.name,
      'discoveredAt': discoveredAt.toIso8601String(),
    };
  }
}

/// A discovered event
class DiscoveredEvent {
  const DiscoveredEvent({
    required this.id,
    required this.name,
    this.description,
    this.venue,
    this.address,
    this.date,
    this.time,
    this.website,
    this.ticketUrl,
    required this.category,
    required this.discoveredAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? venue;
  final String? address;
  final DateTime? date;
  final String? time;
  final String? website;
  final String? ticketUrl;
  final SocialCategory category;
  final DateTime discoveredAt;

  factory DiscoveredEvent.fromJson(
    Map<String, dynamic> json,
    SocialCategory category,
  ) {
    DateTime? date;
    if (json['date'] != null) {
      try {
        date = DateTime.parse(json['date'] as String);
      } catch (_) {
        // Ignore parsing errors
      }
    }

    return DiscoveredEvent(
      id: const Uuid().v4(),
      name: json['name'] as String? ?? 'Unknown Event',
      description: json['description'] as String?,
      venue: json['venue'] as String?,
      address: json['address'] as String?,
      date: date,
      time: json['time'] as String?,
      website: json['website'] as String?,
      ticketUrl: json['ticketUrl'] as String?,
      category: category,
      discoveredAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'venue': venue,
      'address': address,
      'date': date?.toIso8601String(),
      'time': time,
      'website': website,
      'ticketUrl': ticketUrl,
      'category': category.name,
      'discoveredAt': discoveredAt.toIso8601String(),
    };
  }
}

/// A logged social activity (for tracking)
class SocialActivity {
  const SocialActivity({
    required this.id,
    required this.name,
    required this.category,
    required this.timestamp,
    this.durationMinutes,
    this.notes,
    this.placeId,
  });

  final String id;
  final String name;
  final SocialCategory category;
  final DateTime timestamp;
  final int? durationMinutes;
  final String? notes;
  final String? placeId; // Optional link to discovered place

  factory SocialActivity.fromJson(Map<String, dynamic> json) {
    return SocialActivity(
      id: json['id'] as String,
      name: json['name'] as String,
      category: SocialCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => SocialCategory.restaurants,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      durationMinutes: json['durationMinutes'] as int?,
      notes: json['notes'] as String?,
      placeId: json['placeId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'timestamp': timestamp.toIso8601String(),
      'durationMinutes': durationMinutes,
      'notes': notes,
      'placeId': placeId,
    };
  }

  SocialActivity copyWith({
    String? id,
    String? name,
    SocialCategory? category,
    DateTime? timestamp,
    int? durationMinutes,
    String? notes,
    String? placeId,
  }) {
    return SocialActivity(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      placeId: placeId ?? this.placeId,
    );
  }
}

/// Progress tracking for social activities
class SocialProgress {
  const SocialProgress({
    required this.totalMinutes,
    required this.goalMinutes,
    required this.activityCount,
  });

  final int totalMinutes;
  final int goalMinutes;
  final int activityCount;

  double get progress => goalMinutes > 0 ? (totalMinutes / goalMinutes).clamp(0.0, 1.0) : 0.0;
  int get percentComplete => (progress * 100).round();
  bool get goalReached => totalMinutes >= goalMinutes;
  int get remainingMinutes => (goalMinutes - totalMinutes).clamp(0, goalMinutes);
}


