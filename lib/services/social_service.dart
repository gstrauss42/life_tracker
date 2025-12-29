import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/social_models.dart';

/// Service for social activity discovery.
/// Uses AI to filter categories based on location and discover local places.
class SocialService {
  SocialService({
    this.apiKey,
    this.provider = 'openai',
  });

  final String? apiKey;
  final String provider;

  /// Filter categories based on location using AI
  /// Called when location changes to determine which categories are applicable
  Future<List<SocialCategory>> filterCategoriesForLocation(String location) async {
    if (apiKey == null || apiKey!.isEmpty) {
      // Return all categories if no API key
      return SocialCategory.values.toList();
    }

    final allCategories = SocialCategory.values.map((c) => c.name).join(', ');

    final prompt = '''
Given the location "$location", determine which of these activity categories are available/applicable in this area.

Categories to evaluate:
$allCategories

Consider:
- Geographic features (coastal = beaches, mountains = skiing/hiking)
- Climate (no skiing in tropical areas)
- Urban vs rural (nightclubs unlikely in small towns)
- Cultural context

Respond with ONLY a JSON array of applicable category names (no explanation, no markdown):
["restaurants", "cafes", "parks", ...]
''';

    try {
      final response = await _callAI(prompt);
      return _parseCategoryResponse(response);
    } catch (e) {
      debugPrint('Error filtering categories: $e');
      // Return all categories on error
      return SocialCategory.values.toList();
    }
  }

  /// Parse AI response to extract category list
  List<SocialCategory> _parseCategoryResponse(String response) {
    try {
      var cleaned = response.trim();

      // Remove markdown code blocks if present
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceAll(RegExp(r'^```\w*\n?'), '')
            .replaceAll(RegExp(r'\n?```$'), '');
      }

      // Try to extract JSON array
      final jsonMatch = RegExp(r'\[[\s\S]*?\]').firstMatch(cleaned);
      if (jsonMatch != null) {
        cleaned = jsonMatch.group(0)!;
      }

      final List<dynamic> categoryNames = jsonDecode(cleaned);
      final categories = <SocialCategory>[];

      for (final name in categoryNames) {
        try {
          final category = SocialCategory.values.firstWhere(
            (c) => c.name.toLowerCase() == name.toString().toLowerCase(),
          );
          categories.add(category);
        } catch (_) {
          // Skip unknown categories
        }
      }

      return categories.isNotEmpty ? categories : SocialCategory.values.toList();
    } catch (e) {
      debugPrint('Error parsing category response: $e');
      return SocialCategory.values.toList();
    }
  }

  /// Discover places for a specific category using AI with web search
  Future<List<DiscoveredPlace>> discoverPlaces({
    required String location,
    required SocialCategory category,
    int limit = 10,
  }) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('API key not configured. Please set your API key in Settings.');
    }

    final categoryInfo = CategoryInfo.getInfo(category);

    final prompt = '''
Search for the best ${categoryInfo.displayName.toLowerCase()} in $location.

Find real, currently operating places. For each place provide:
- name: The venue name
- description: Brief description (1-2 sentences)
- address: Street address if available
- rating: Rating out of 5 if known
- priceLevel: \$, \$\$, \$\$\$, or \$\$\$\$ if applicable
- tags: Relevant tags (e.g., "outdoor seating", "family friendly", "live music")
- website: URL if found
- openNow: true/false/null if unknown

Search terms to use: ${categoryInfo.searchTerms}

Respond with ONLY a JSON array (no markdown, no explanation):
[
  {
    "name": "Place Name",
    "description": "Brief description",
    "address": "123 Street, City",
    "rating": 4.5,
    "priceLevel": "\$\$",
    "tags": ["outdoor", "family friendly"],
    "website": "https://...",
    "openNow": null
  }
]

Return up to $limit places. Only include real places you find through search.
If you cannot find places, return an empty array [].
''';

    try {
      final response = await _callAI(prompt);
      debugPrint('SOCIAL SERVICE - Places response for ${categoryInfo.displayName}:');
      debugPrint(response.substring(0, response.length.clamp(0, 500)));
      return _parsePlacesResponse(response, category);
    } catch (e) {
      debugPrint('Error discovering places: $e');
      rethrow;
    }
  }

  /// Discover places using a custom freeform query (AI-powered)
  Future<List<DiscoveredPlace>> discoverPlacesWithQuery({
    required String location,
    required String query,
    int limit = 10,
  }) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('API key not configured. Please set your API key in Settings.');
    }

    final prompt = '''
Search for places matching "$query" in $location.

The user is looking for: $query

Find real, currently operating places that match this description. For each place provide:
- name: The venue name
- description: Brief description (1-2 sentences)
- address: Street address if available
- rating: Rating out of 5 if known
- priceLevel: \$, \$\$, \$\$\$, or \$\$\$\$ if applicable
- tags: Relevant tags (e.g., "outdoor seating", "family friendly", "live music")
- website: URL if found
- openNow: true/false/null if unknown
- suggestedCategory: One of these categories that best fits: restaurants, cafes, bars, nightclubs, beaches, parks, hiking, camping, skiing, surfing, lakes, mountains, gyms, sportsCourts, golfCourses, swimmingPools, cinema, theatre, liveMusic, museums, artGalleries, arcades, shoppingMalls, markets, communityEvents, festivals, spas, yoga, meditation

Respond with ONLY a JSON array (no markdown, no explanation):
[
  {
    "name": "Place Name",
    "description": "Brief description",
    "address": "123 Street, City",
    "rating": 4.5,
    "priceLevel": "\$\$",
    "tags": ["outdoor", "family friendly"],
    "website": "https://...",
    "openNow": null,
    "suggestedCategory": "restaurants"
  }
]

Return up to $limit places. Only include real places you find through search.
If you cannot find places, return an empty array [].
''';

    try {
      final response = await _callAI(prompt);
      debugPrint('SOCIAL SERVICE - Custom query response for "$query":');
      debugPrint(response.substring(0, response.length.clamp(0, 500)));
      return _parseCustomQueryResponse(response);
    } catch (e) {
      debugPrint('Error discovering places with query: $e');
      rethrow;
    }
  }

  /// Parse AI response for custom query (determines category from response)
  List<DiscoveredPlace> _parseCustomQueryResponse(String response) {
    try {
      var cleaned = response.trim();

      // Remove markdown code blocks if present
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceAll(RegExp(r'^```\w*\n?'), '')
            .replaceAll(RegExp(r'\n?```$'), '');
      }

      // Try to extract JSON array
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(cleaned);
      if (jsonMatch != null) {
        cleaned = jsonMatch.group(0)!;
      }

      final List<dynamic> placesJson = jsonDecode(cleaned);
      return placesJson.map((json) {
        final Map<String, dynamic> placeData = json as Map<String, dynamic>;
        
        // Try to get suggested category from response
        SocialCategory category = SocialCategory.restaurants; // default
        if (placeData.containsKey('suggestedCategory')) {
          final suggestedName = placeData['suggestedCategory']?.toString().toLowerCase();
          try {
            category = SocialCategory.values.firstWhere(
              (c) => c.name.toLowerCase() == suggestedName,
            );
          } catch (_) {
            // Keep default category
          }
        }
        
        return DiscoveredPlace.fromJson(placeData, category);
      }).toList();
    } catch (e) {
      debugPrint('Error parsing custom query response: $e');
      return [];
    }
  }

  /// Parse AI response to extract places list
  List<DiscoveredPlace> _parsePlacesResponse(String response, SocialCategory category) {
    try {
      var cleaned = response.trim();

      // Remove markdown code blocks if present
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceAll(RegExp(r'^```\w*\n?'), '')
            .replaceAll(RegExp(r'\n?```$'), '');
      }

      // Try to extract JSON array
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(cleaned);
      if (jsonMatch != null) {
        cleaned = jsonMatch.group(0)!;
      }

      final List<dynamic> placesJson = jsonDecode(cleaned);
      return placesJson
          .map((json) => DiscoveredPlace.fromJson(json as Map<String, dynamic>, category))
          .toList();
    } catch (e) {
      debugPrint('Error parsing places response: $e');
      return [];
    }
  }

  /// Discover events for a specific category (optional, only if found)
  Future<List<DiscoveredEvent>> discoverEvents({
    required String location,
    required SocialCategory category,
    int limit = 5,
  }) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('API key not configured. Please set your API key in Settings.');
    }

    final categoryInfo = CategoryInfo.getInfo(category);

    final prompt = '''
Search for upcoming ${categoryInfo.displayName.toLowerCase()} events in $location.

Find real, upcoming events. For each event provide:
- name: The event name
- description: Brief description (1-2 sentences)
- venue: Venue name
- address: Address if available
- date: Date in YYYY-MM-DD format
- time: Time if known
- website: URL if found
- ticketUrl: Ticket purchase URL if available

Respond with ONLY a JSON array (no markdown, no explanation):
[
  {
    "name": "Event Name",
    "description": "Brief description",
    "venue": "Venue Name",
    "address": "123 Street, City",
    "date": "2025-01-15",
    "time": "19:00",
    "website": "https://...",
    "ticketUrl": "https://..."
  }
]

Return up to $limit events. Only include real upcoming events.
If you cannot find events, return an empty array [].
''';

    try {
      final response = await _callAI(prompt);
      return _parseEventsResponse(response, category);
    } catch (e) {
      debugPrint('Error discovering events: $e');
      return [];
    }
  }

  /// Parse AI response to extract events list
  List<DiscoveredEvent> _parseEventsResponse(String response, SocialCategory category) {
    try {
      var cleaned = response.trim();

      // Remove markdown code blocks if present
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceAll(RegExp(r'^```\w*\n?'), '')
            .replaceAll(RegExp(r'\n?```$'), '');
      }

      // Try to extract JSON array
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(cleaned);
      if (jsonMatch != null) {
        cleaned = jsonMatch.group(0)!;
      }

      final List<dynamic> eventsJson = jsonDecode(cleaned);
      return eventsJson
          .map((json) => DiscoveredEvent.fromJson(json as Map<String, dynamic>, category))
          .toList();
    } catch (e) {
      debugPrint('Error parsing events response: $e');
      return [];
    }
  }

  /// Call the AI provider
  Future<String> _callAI(String prompt) async {
    if (provider == 'anthropic') {
      return _callAnthropic(prompt);
    } else if (provider == 'deepseek') {
      return _callDeepSeek(prompt);
    } else {
      return _callOpenAI(prompt);
    }
  }

  Future<String> _callOpenAI(String prompt) async {
    final dio = Dio();
    final response = await dio.post(
      'https://api.openai.com/v1/chat/completions',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      ),
      data: {
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a local discovery assistant. You help find places and activities in specific locations. Always respond with valid JSON only, no markdown or explanation.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.7,
        'max_tokens': 2000,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode} - ${response.data}');
    }

    return response.data['choices'][0]['message']['content'] as String;
  }

  Future<String> _callAnthropic(String prompt) async {
    final dio = Dio();
    final response = await dio.post(
      'https://api.anthropic.com/v1/messages',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey!,
          'anthropic-version': '2023-06-01',
        },
      ),
      data: {
        'model': 'claude-3-haiku-20240307',
        'max_tokens': 2000,
        'system':
            'You are a local discovery assistant. You help find places and activities in specific locations. Always respond with valid JSON only, no markdown or explanation.',
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          },
        ],
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Anthropic API error: ${response.statusCode} - ${response.data}');
    }

    return response.data['content'][0]['text'] as String;
  }

  Future<String> _callDeepSeek(String prompt) async {
    final dio = Dio();
    final response = await dio.post(
      'https://api.deepseek.com/v1/chat/completions',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      ),
      data: {
        'model': 'deepseek-chat',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a local discovery assistant. You help find places and activities in specific locations. Always respond with valid JSON only, no markdown or explanation.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.7,
        'max_tokens': 2000,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('DeepSeek API error: ${response.statusCode} - ${response.data}');
    }

    return response.data['choices'][0]['message']['content'] as String;
  }
}

/// Helper to check if location change should trigger category refresh
bool shouldRefreshCategories(String? oldCity, String? oldCountry, String? newCity, String? newCountry) {
  // First time setting location
  if (oldCity == null && newCity != null) {
    return true;
  }
  // City changed
  if (oldCity != newCity) {
    return true;
  }
  // Country changed
  if (oldCountry != newCountry) {
    return true;
  }
  return false;
}

