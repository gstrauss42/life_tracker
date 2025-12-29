import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Service for analyzing food and getting nutrition data.
/// Uses OpenAI or Anthropic API to analyze food descriptions and estimate nutrition.
class NutritionService {
  NutritionService({
    this.apiKey,
    this.provider = 'openai',
  });

  final String? apiKey;
  final String provider;

  /// Parse user input to extract food name and weight in grams
  /// Handles formats like "150g chicken", "chicken 150g", "2 eggs", "100ml milk"
  _ParsedFoodInput _parseInputWithWeight(String input) {
    final trimmed = input.trim();
    
    // Pattern: number + unit at start (e.g., "150g chicken", "100ml milk", "2 eggs")
    final startPattern = RegExp(r'^(\d+(?:\.\d+)?)\s*(g|kg|oz|lb|ml|l|cups?|tbsp|tsp|units?|pieces?|slices?|eggs?)?\s+(.+)$', caseSensitive: false);
    // Pattern: number + unit at end (e.g., "chicken 150g")
    final endPattern = RegExp(r'^(.+?)\s+(\d+(?:\.\d+)?)\s*(g|kg|oz|lb|ml|l|cups?|tbsp|tsp|units?|pieces?|slices?|eggs?)?$', caseSensitive: false);
    
    // Try start pattern first
    var match = startPattern.firstMatch(trimmed);
    if (match != null) {
      final amount = double.tryParse(match.group(1)!) ?? 100;
      final unit = match.group(2)?.toLowerCase() ?? 'g';
      final foodName = match.group(3)!.trim();
      return _ParsedFoodInput(foodName, _convertToGrams(amount, unit));
    }
    
    // Try end pattern
    match = endPattern.firstMatch(trimmed);
    if (match != null) {
      final foodName = match.group(1)!.trim();
      final amount = double.tryParse(match.group(2)!) ?? 100;
      final unit = match.group(3)?.toLowerCase() ?? 'g';
      return _ParsedFoodInput(foodName, _convertToGrams(amount, unit));
    }
    
    // No weight found - assume 100g (will show per-100g values)
    return _ParsedFoodInput(trimmed, 100);
  }

  /// Parse AI response containing per-100g nutrition values
  FoodNutritionResult _parseResponsePer100g(String response, String originalName) {
    try {
      var cleaned = response.trim();
      
      // Remove markdown code blocks if present
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'^```\w*\n?'), '').replaceAll(RegExp(r'\n?```$'), '');
      }
      
      // Try to extract JSON if there's text around it
      final jsonMatch = RegExp(r'\{[^{}]*\}').firstMatch(cleaned);
      if (jsonMatch != null) {
        cleaned = jsonMatch.group(0)!;
      }

      final data = jsonDecode(cleaned) as Map<String, dynamic>;
      
      // Debug: log what we received
      debugPrint('PARSED: ${data.keys.length} fields for $originalName');
      debugPrint('MICROS: Ca=${data['calcium']} Fe=${data['iron']} B12=${data['vitaminB12']} Mg=${data['magnesium']} Zn=${data['zinc']}');

      return FoodNutritionResult(
        name: data['name'] as String? ?? originalName,
        servingSize: 100, // Per 100g reference
        servingUnit: 'g',
        calories: (data['calories'] as num?)?.toDouble(),
        protein: (data['protein'] as num?)?.toDouble(),
        carbs: (data['carbs'] as num?)?.toDouble(),
        fat: (data['fat'] as num?)?.toDouble(),
        fiber: (data['fiber'] as num?)?.toDouble(),
        sugar: (data['sugar'] as num?)?.toDouble(),
        sodium: (data['sodium'] as num?)?.toDouble(),
        vitaminC: (data['vitaminC'] as num?)?.toDouble(),
        vitaminD: (data['vitaminD'] as num?)?.toDouble(),
        calcium: (data['calcium'] as num?)?.toDouble(),
        iron: (data['iron'] as num?)?.toDouble(),
        potassium: (data['potassium'] as num?)?.toDouble(),
        healthScore: (data['healthScore'] as num?)?.toDouble(),
        vitaminA: (data['vitaminA'] as num?)?.toDouble(),
        vitaminE: (data['vitaminE'] as num?)?.toDouble(),
        vitaminK: (data['vitaminK'] as num?)?.toDouble(),
        vitaminB1: (data['vitaminB1'] as num?)?.toDouble(),
        vitaminB2: (data['vitaminB2'] as num?)?.toDouble(),
        vitaminB3: (data['vitaminB3'] as num?)?.toDouble(),
        vitaminB6: (data['vitaminB6'] as num?)?.toDouble(),
        vitaminB12: (data['vitaminB12'] as num?)?.toDouble(),
        folate: (data['folate'] as num?)?.toDouble(),
        magnesium: (data['magnesium'] as num?)?.toDouble(),
        zinc: (data['zinc'] as num?)?.toDouble(),
        phosphorus: (data['phosphorus'] as num?)?.toDouble(),
        selenium: (data['selenium'] as num?)?.toDouble(),
        iodine: (data['iodine'] as num?)?.toDouble(),
        omega3: (data['omega3'] as num?)?.toDouble(),
      );
    } catch (e) {
      return FoodNutritionResult(
        name: originalName,
        error: 'Failed to parse nutrition data: $e',
      );
    }
  }

  /// Scale per-100g nutrition values to actual serving weight
  FoodNutritionResult _scaleNutrition(FoodNutritionResult per100g, double grams) {
    if (per100g.hasError) return per100g;
    
    final multiplier = grams / 100.0;
    
    double? scale(double? value) => value != null ? value * multiplier : null;
    
    return FoodNutritionResult(
      name: per100g.name,
      servingSize: grams,
      servingUnit: 'g',
      calories: scale(per100g.calories),
      protein: scale(per100g.protein),
      carbs: scale(per100g.carbs),
      fat: scale(per100g.fat),
      fiber: scale(per100g.fiber),
      sugar: scale(per100g.sugar),
      sodium: scale(per100g.sodium),
      vitaminC: scale(per100g.vitaminC),
      vitaminD: scale(per100g.vitaminD),
      calcium: scale(per100g.calcium),
      iron: scale(per100g.iron),
      potassium: scale(per100g.potassium),
      healthScore: per100g.healthScore, // Don't scale health score
      vitaminA: scale(per100g.vitaminA),
      vitaminE: scale(per100g.vitaminE),
      vitaminK: scale(per100g.vitaminK),
      vitaminB1: scale(per100g.vitaminB1),
      vitaminB2: scale(per100g.vitaminB2),
      vitaminB3: scale(per100g.vitaminB3),
      vitaminB6: scale(per100g.vitaminB6),
      vitaminB12: scale(per100g.vitaminB12),
      folate: scale(per100g.folate),
      magnesium: scale(per100g.magnesium),
      zinc: scale(per100g.zinc),
      phosphorus: scale(per100g.phosphorus),
      selenium: scale(per100g.selenium),
      iodine: scale(per100g.iodine),
      omega3: scale(per100g.omega3),
    );
  }

  /// Analyze a food description and return estimated nutrition data
  Future<FoodNutritionResult> analyzeFood(String foodDescription) async {

    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('API key not configured. Please set your API key in Settings.');
    }

    // Parse input to extract weight if specified
    final parsed = _parseInputWithWeight(foodDescription);
    final foodName = parsed.foodName;
    final requestedGrams = parsed.grams;

    final prompt = '''
Return complete USDA nutrition data for "$foodName" per 100g. ALL fields are REQUIRED with accurate non-zero values.

RESPOND WITH ONLY THIS JSON (no text before or after):
{"name":"$foodName","calories":0,"protein":0,"carbs":0,"fat":0,"fiber":0,"sugar":0,"sodium":0,"vitaminC":0,"vitaminD":0,"calcium":0,"iron":0,"potassium":0,"vitaminA":0,"vitaminE":0,"vitaminK":0,"vitaminB1":0,"vitaminB2":0,"vitaminB3":0,"vitaminB6":0,"vitaminB12":0,"folate":0,"magnesium":0,"zinc":0,"phosphorus":0,"selenium":0,"iodine":0,"omega3":0,"healthScore":7}

Replace all 0s with actual USDA values per 100g. Units: calories=kcal, protein/carbs/fat/fiber/sugar/omega3=g, sodium/calcium/iron/potassium/magnesium/zinc/phosphorus=mg, vitaminC/vitaminE/vitaminB1/vitaminB2/vitaminB3/vitaminB6=mg, vitaminD/vitaminA/vitaminK/vitaminB12/folate/selenium/iodine=mcg.

Most whole foods contain measurable amounts of most nutrients. Return accurate values, not zeros.
''';

    try {
      final response = await _callAI(prompt);
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('NUTRITION SERVICE - Raw AI response for "$foodName":');
      debugPrint(response);
      debugPrint('═══════════════════════════════════════════════════════════');
      final per100g = _parseResponsePer100g(response, foodName);
      
      // Check if micronutrients are missing and log
      final missingMicros = <String>[];
      if (per100g.calcium == null || per100g.calcium == 0) missingMicros.add('calcium');
      if (per100g.iron == null || per100g.iron == 0) missingMicros.add('iron');
      if (per100g.vitaminB12 == null || per100g.vitaminB12 == 0) missingMicros.add('B12');
      if (per100g.magnesium == null || per100g.magnesium == 0) missingMicros.add('magnesium');
      if (per100g.zinc == null || per100g.zinc == 0) missingMicros.add('zinc');
      
      if (missingMicros.isNotEmpty) {
        debugPrint('⚠️ MISSING MICROS for $foodName: ${missingMicros.join(", ")}');
        debugPrint('Raw response was: $response');
      }
      
      // Scale from per-100g to actual requested weight
      final result = _scaleNutrition(per100g, requestedGrams);
      return result;
    } catch (e, stack) {
      debugPrint('NUTRITION SERVICE ERROR for "$foodName": $e');
      debugPrint('Stack: $stack');
      // Return a basic entry if AI fails
      return FoodNutritionResult(
        name: foodDescription,
        servingSize: null,
        servingUnit: null,
        calories: null,
        protein: null,
        carbs: null,
        fat: null,
        fiber: null,
        sugar: null,
        sodium: null,
        vitaminC: null,
        vitaminD: null,
        calcium: null,
        iron: null,
        potassium: null,
        healthScore: null,
        error: e.toString(),
      );
    }
  }

  /// Get nutrition per 100g for a single ingredient (lookup only, no math)
  Future<IngredientNutritionPer100g> getNutritionPer100g(String ingredientName) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('API key not configured');
    }

    final prompt = '''
What is the nutrition content of "$ingredientName" per 100g (raw/uncooked if applicable)?

Respond with ONLY this JSON (no other text, no markdown):
{"calories":<number>,"protein":<number>,"carbs":<number>,"fat":<number>,"fiber":<number>}

Use standard USDA database values. Numbers only, no units in the JSON.
''';

    try {
      final response = await _callAI(prompt);
      
      var cleaned = response.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'^```\w*\n?'), '').replaceAll(RegExp(r'\n?```$'), '');
      }
      
      final data = jsonDecode(cleaned) as Map<String, dynamic>;
      return IngredientNutritionPer100g(
        ingredientName: ingredientName,
        caloriesPer100g: (data['calories'] as num?)?.toDouble() ?? 0,
        proteinPer100g: (data['protein'] as num?)?.toDouble() ?? 0,
        carbsPer100g: (data['carbs'] as num?)?.toDouble() ?? 0,
        fatPer100g: (data['fat'] as num?)?.toDouble() ?? 0,
        fiberPer100g: (data['fiber'] as num?)?.toDouble() ?? 0,
      );
    } catch (e) {
      return IngredientNutritionPer100g(ingredientName: ingredientName);
    }
  }

  /// Analyze structured ingredients - analyzes each ingredient and sums the nutrition
  Future<FoodNutritionResult> analyzeStructuredIngredients({
    required String mealName,
    required List<StructuredIngredient> ingredients,
  }) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('API key not configured. Please set your API key in Settings.');
    }

    // Initialize totals for all nutrients
    double totalGrams = 0;
    double totalCalories = 0, totalProtein = 0, totalCarbs = 0, totalFat = 0;
    double totalFiber = 0, totalSugar = 0, totalSodium = 0;
    double totalVitaminC = 0, totalVitaminD = 0, totalCalcium = 0, totalIron = 0, totalPotassium = 0;
    double totalVitaminA = 0, totalVitaminE = 0, totalVitaminK = 0;
    double totalVitaminB1 = 0, totalVitaminB2 = 0, totalVitaminB3 = 0;
    double totalVitaminB6 = 0, totalVitaminB12 = 0, totalFolate = 0;
    double totalMagnesium = 0, totalZinc = 0, totalPhosphorus = 0;
    double totalSelenium = 0, totalIodine = 0, totalOmega3 = 0;

    for (final ingredient in ingredients) {
      if (ingredient.name.isEmpty) continue;

      // Convert amount to grams
      final grams = _convertToGrams(ingredient.amount, ingredient.unit);
      totalGrams += grams;
      
      // Build the query string with weight
      final query = '${grams.toStringAsFixed(0)}g ${ingredient.name}';
      
      // Get full nutrition analysis for this ingredient
      final result = await analyzeFood(query);
      
      // Sum all nutrients
      totalCalories += result.calories ?? 0;
      totalProtein += result.protein ?? 0;
      totalCarbs += result.carbs ?? 0;
      totalFat += result.fat ?? 0;
      totalFiber += result.fiber ?? 0;
      totalSugar += result.sugar ?? 0;
      totalSodium += result.sodium ?? 0;
      totalVitaminC += result.vitaminC ?? 0;
      totalVitaminD += result.vitaminD ?? 0;
      totalCalcium += result.calcium ?? 0;
      totalIron += result.iron ?? 0;
      totalPotassium += result.potassium ?? 0;
      totalVitaminA += result.vitaminA ?? 0;
      totalVitaminE += result.vitaminE ?? 0;
      totalVitaminK += result.vitaminK ?? 0;
      totalVitaminB1 += result.vitaminB1 ?? 0;
      totalVitaminB2 += result.vitaminB2 ?? 0;
      totalVitaminB3 += result.vitaminB3 ?? 0;
      totalVitaminB6 += result.vitaminB6 ?? 0;
      totalVitaminB12 += result.vitaminB12 ?? 0;
      totalFolate += result.folate ?? 0;
      totalMagnesium += result.magnesium ?? 0;
      totalZinc += result.zinc ?? 0;
      totalPhosphorus += result.phosphorus ?? 0;
      totalSelenium += result.selenium ?? 0;
      totalIodine += result.iodine ?? 0;
      totalOmega3 += result.omega3 ?? 0;
    }

    return FoodNutritionResult(
      name: mealName.isNotEmpty ? mealName : 'Mixed meal',
      servingSize: totalGrams,
      servingUnit: 'g',
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      fiber: totalFiber,
      sugar: totalSugar,
      sodium: totalSodium,
      vitaminC: totalVitaminC,
      vitaminD: totalVitaminD,
      calcium: totalCalcium,
      iron: totalIron,
      potassium: totalPotassium,
      healthScore: 7,
      vitaminA: totalVitaminA,
      vitaminE: totalVitaminE,
      vitaminK: totalVitaminK,
      vitaminB1: totalVitaminB1,
      vitaminB2: totalVitaminB2,
      vitaminB3: totalVitaminB3,
      vitaminB6: totalVitaminB6,
      vitaminB12: totalVitaminB12,
      folate: totalFolate,
      magnesium: totalMagnesium,
      zinc: totalZinc,
      phosphorus: totalPhosphorus,
      selenium: totalSelenium,
      iodine: totalIodine,
      omega3: totalOmega3,
    );
  }

  /// Convert amount with unit to grams
  double _convertToGrams(double amount, String unit) {
    switch (unit.toLowerCase()) {
      case 'g':
        return amount;
      case 'kg':
        return amount * 1000;
      case 'oz':
        return amount * 28.35;
      case 'lb':
        return amount * 453.6;
      case 'ml':
        return amount; // Approximate for water-like liquids
      case 'l':
        return amount * 1000;
      case 'cup':
      case 'cups':
        return amount * 240; // Approximate
      case 'tbsp':
        return amount * 15;
      case 'tsp':
        return amount * 5;
      case 'unit':
      case 'units':
      case 'piece':
      case 'pieces':
        return amount * 50; // Rough estimate per unit/piece
      case 'slice':
      case 'slices':
        return amount * 30; // Approximate slice
      case 'egg':
      case 'eggs':
        return amount * 50; // Average large egg ~50g
      default:
        return amount * 100; // Default to assuming amount is a serving
    }
  }

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
            'content': 'You are a nutrition expert. Always respond with valid JSON only, no markdown or explanation.',
          },
          {
            'role': 'system',
            'content': 'You are a USDA nutrition database. Return ONLY valid JSON with complete nutrition data. Include ALL vitamins and minerals with accurate non-zero values.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.1,
        'max_tokens': 1000,
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
        'max_tokens': 1000,
        'system': 'You are a USDA nutrition database. Return ONLY valid JSON with complete nutrition data. Include ALL vitamins and minerals with accurate non-zero values.',
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
            'content': 'You are a USDA nutrition database. Return ONLY valid JSON with complete nutrition data. Include ALL vitamins and minerals with accurate non-zero values.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.1,
        'max_tokens': 1000,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('DeepSeek API error: ${response.statusCode} - ${response.data}');
    }

    // DeepSeek uses OpenAI-compatible response format
    return response.data['choices'][0]['message']['content'] as String;
  }

  /// Get suggestions for what nutrients are missing based on daily intake
  List<String> getNutritionSuggestions(NutritionSummary summary) {
    final suggestions = <String>[];
    final rec = NutritionSummary.recommendedDaily;

    if (summary.protein < rec.protein * 0.7) {
      suggestions.add('🥩 Add more protein: eggs, chicken, fish, legumes, or Greek yogurt');
    }
    if (summary.fiber < rec.fiber * 0.7) {
      suggestions.add('🥬 Need more fiber: vegetables, whole grains, beans, or berries');
    }
    if (summary.vitaminC < rec.vitaminC * 0.7) {
      suggestions.add('🍊 Low vitamin C: citrus fruits, bell peppers, or broccoli');
    }
    if (summary.vitaminD < rec.vitaminD * 0.7) {
      suggestions.add('☀️ Low vitamin D: fatty fish, eggs, or fortified foods (also get sunlight!)');
    }
    if (summary.calcium < rec.calcium * 0.7) {
      suggestions.add('🥛 Need calcium: dairy, leafy greens, or fortified plant milk');
    }
    if (summary.iron < rec.iron * 0.7) {
      suggestions.add('🫘 Low iron: red meat, spinach, lentils, or fortified cereals');
    }
    if (summary.potassium < rec.potassium * 0.7) {
      suggestions.add('🍌 Need potassium: bananas, potatoes, avocados, or beans');
    }

    return suggestions;
  }

  /// Get food and meal recommendations based on nutritional deficiencies
  FoodRecommendations getRecommendations(NutritionSummary summary) {
    final rec = NutritionSummary.recommendedDaily;
    final quickFoods = <QuickFoodItem>[];
    final mealIdeas = <MealIdea>[];

    // Identify what's missing
    final needsProtein = summary.protein < rec.protein * 0.7;
    final needsFiber = summary.fiber < rec.fiber * 0.7;
    final needsVitaminC = summary.vitaminC < rec.vitaminC * 0.7;
    final needsVitaminD = summary.vitaminD < rec.vitaminD * 0.7;
    final needsCalcium = summary.calcium < rec.calcium * 0.7;
    final needsIron = summary.iron < rec.iron * 0.7;
    final needsPotassium = summary.potassium < rec.potassium * 0.7;

    // Quick foods database
    if (needsProtein) {
      quickFoods.addAll([
        const QuickFoodItem('Greek Yogurt', '🥛', '17g protein per cup', ['protein', 'calcium']),
        const QuickFoodItem('Hard Boiled Eggs (2)', '🥚', '12g protein', ['protein', 'vitaminD']),
        const QuickFoodItem('Handful of Almonds', '🥜', '6g protein + healthy fats', ['protein', 'fiber']),
        const QuickFoodItem('Cottage Cheese', '🧀', '14g protein per half cup', ['protein', 'calcium']),
        const QuickFoodItem('Canned Tuna', '🐟', '20g protein per can', ['protein', 'vitaminD']),
      ]);
    }

    if (needsFiber) {
      quickFoods.addAll([
        const QuickFoodItem('Apple with Skin', '🍎', '4g fiber', ['fiber', 'vitaminC']),
        const QuickFoodItem('Handful of Berries', '🫐', '4g fiber per cup', ['fiber', 'vitaminC']),
        const QuickFoodItem('Avocado Half', '🥑', '5g fiber + potassium', ['fiber', 'potassium']),
        const QuickFoodItem('Carrot Sticks', '🥕', '3g fiber + vitamin A', ['fiber']),
        const QuickFoodItem('Oatmeal', '🥣', '4g fiber per cup', ['fiber', 'iron']),
      ]);
    }

    if (needsVitaminC) {
      quickFoods.addAll([
        const QuickFoodItem('Orange', '🍊', '70mg vitamin C', ['vitaminC', 'fiber']),
        const QuickFoodItem('Bell Pepper Slices', '🫑', '150mg vitamin C per pepper', ['vitaminC']),
        const QuickFoodItem('Kiwi', '🥝', '64mg vitamin C each', ['vitaminC', 'fiber']),
        const QuickFoodItem('Strawberries', '🍓', '85mg vitamin C per cup', ['vitaminC', 'fiber']),
      ]);
    }

    if (needsCalcium) {
      quickFoods.addAll([
        const QuickFoodItem('Glass of Milk', '🥛', '300mg calcium', ['calcium', 'vitaminD', 'protein']),
        const QuickFoodItem('Cheese Stick', '🧀', '200mg calcium', ['calcium', 'protein']),
        const QuickFoodItem('Fortified Orange Juice', '🍊', '350mg calcium per cup', ['calcium', 'vitaminC']),
      ]);
    }

    if (needsIron) {
      quickFoods.addAll([
        const QuickFoodItem('Spinach (cooked)', '🥬', '6mg iron per cup', ['iron', 'fiber', 'vitaminC']),
        const QuickFoodItem('Pumpkin Seeds', '🎃', '2mg iron per oz', ['iron', 'protein']),
        const QuickFoodItem('Dark Chocolate', '🍫', '3mg iron per oz', ['iron']),
      ]);
    }

    if (needsPotassium) {
      quickFoods.addAll([
        const QuickFoodItem('Banana', '🍌', '420mg potassium', ['potassium', 'fiber']),
        const QuickFoodItem('Baked Potato', '🥔', '900mg potassium', ['potassium', 'fiber']),
        const QuickFoodItem('Coconut Water', '🥥', '600mg potassium per cup', ['potassium']),
      ]);
    }

    if (needsVitaminD) {
      quickFoods.addAll([
        const QuickFoodItem('Salmon', '🐟', '15mcg vitamin D per 3oz', ['vitaminD', 'protein']),
        const QuickFoodItem('Fortified Cereal', '🥣', '2-3mcg vitamin D per serving', ['vitaminD', 'iron']),
        const QuickFoodItem('Egg Yolks (2)', '🥚', '2mcg vitamin D', ['vitaminD', 'protein']),
      ]);
    }

    // Meal ideas based on what's needed
    if (needsProtein && needsFiber) {
      mealIdeas.add(const MealIdea(
        'Chicken Stir Fry',
        'Grilled chicken breast with mixed vegetables (broccoli, peppers, snap peas) over brown rice',
        '~35g protein, 8g fiber',
        ['protein', 'fiber', 'vitaminC'],
      ));
    }

    if (needsProtein && needsCalcium) {
      mealIdeas.add(const MealIdea(
        'Greek Yogurt Parfait',
        'Greek yogurt layered with granola, berries, and a drizzle of honey',
        '~20g protein, 300mg calcium',
        ['protein', 'calcium', 'fiber'],
      ));
    }

    if (needsIron && needsVitaminC) {
      mealIdeas.add(const MealIdea(
        'Spinach Salad with Citrus',
        'Fresh spinach with orange segments, strawberries, and grilled chicken. Vitamin C helps iron absorption!',
        '~6mg iron, 80mg vitamin C',
        ['iron', 'vitaminC', 'protein'],
      ));
    }

    if (needsFiber && needsPotassium) {
      mealIdeas.add(const MealIdea(
        'Sweet Potato Buddha Bowl',
        'Roasted sweet potato, black beans, avocado, and quinoa with tahini dressing',
        '~12g fiber, 900mg potassium',
        ['fiber', 'potassium', 'protein'],
      ));
    }

    if (needsVitaminD && needsProtein) {
      mealIdeas.add(const MealIdea(
        'Salmon with Vegetables',
        'Baked salmon fillet with roasted asparagus and a side salad',
        '~30g protein, 15mcg vitamin D',
        ['vitaminD', 'protein', 'fiber'],
      ));
    }

    if (needsCalcium && needsFiber) {
      mealIdeas.add(const MealIdea(
        'Veggie Omelet with Toast',
        'Three-egg omelet with cheese, spinach, and tomatoes. Whole grain toast on the side',
        '~20g protein, 350mg calcium',
        ['calcium', 'protein', 'fiber'],
      ));
    }

    // General balanced meals if multiple deficiencies
    if (quickFoods.length > 3) {
      mealIdeas.add(const MealIdea(
        'Power Smoothie',
        'Blend: banana, spinach, Greek yogurt, milk, berries, and a spoon of nut butter',
        'Covers multiple nutrients in one drink',
        ['protein', 'calcium', 'potassium', 'fiber', 'vitaminC'],
      ));
    }

    // Remove duplicates from quick foods
    final uniqueFoods = <String, QuickFoodItem>{};
    for (final food in quickFoods) {
      uniqueFoods[food.name] = food;
    }

    return FoodRecommendations(
      quickFoods: uniqueFoods.values.toList()..shuffle()..take(6),
      mealIdeas: mealIdeas,
      deficientNutrients: [
        if (needsProtein) 'Protein',
        if (needsFiber) 'Fiber',
        if (needsVitaminC) 'Vitamin C',
        if (needsVitaminD) 'Vitamin D',
        if (needsCalcium) 'Calcium',
        if (needsIron) 'Iron',
        if (needsPotassium) 'Potassium',
      ],
    );
  }

  /// Get AI-generated personalized meal recommendation based on multi-day nutrition patterns
  Future<String> getAIMealRecommendation(MultiDayNutritionOverview overview, {String? preferences}) async {
    final suggestions = await getAIMealSuggestions(overview, count: 1, preferences: preferences);
    return suggestions.isNotEmpty ? suggestions.first : 'Unable to generate recommendation.';
  }

  /// Get multiple AI-generated meal suggestions based on multi-day nutrition patterns
  Future<List<String>> getAIMealSuggestions(MultiDayNutritionOverview overview, {int count = 4, String? preferences}) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('API key not configured');
    }

    // Check if there are any deficiencies to address
    if (!overview.hasDeficiencies && overview.todayIntake.getDeficiencies().isEmpty) {
      return ["You're doing great! Your nutrition has been well-balanced recently. Keep it up!"];
    }

    final nutritionContext = overview.toAISummary();

    // Build preferences section
    String preferencesSection = '';
    if (preferences != null && preferences.isNotEmpty) {
      preferencesSection = '''

USER TASTE PREFERENCES (use to customize suggestions):
$preferences

These preferences help personalize HOW you address the nutritional needs. Find alternative ingredients that:
- Still provide the needed nutrients
- Incorporate foods they feel like eating (when possible)
- NEVER include foods they want to avoid
''';
    }

    final prompt = '''
You're a helpful nutritionist. Based on the user's CURRENT nutrition status today, suggest $count different specific, practical meals or snacks.

$nutritionContext$preferencesSection

PRIMARY GOAL: Address nutritional deficiencies identified above.
SECONDARY GOAL: Customize suggestions based on user taste preferences (if provided).

CRITICAL RULES:
- FIRST: Identify which nutrients are lacking and need to be addressed
- THEN: Find meals that provide those nutrients while respecting taste preferences
- If a macro is ALREADY MET/EXCEEDED, DO NOT suggest meals high in that nutrient!
- For example: If protein is at 150%, suggest carb-focused meals like fruit, grains, vegetables - NOT protein dishes
- If calories are exceeded, suggest low-calorie nutrient-dense options like salads, fruits, vegetables
- PRIORITIZE fixing the "STILL NEED MORE OF" nutrients and "LOW MICRONUTRIENTS"
- Suggest foods rich in the specific vitamins/minerals that are low${preferences != null ? '\n- When user has preferences: find ALTERNATIVE ingredients that provide the same nutrients but match their taste preferences\n- NEVER suggest foods they want to avoid - find substitutes that provide similar nutrition' : ''}

Requirements:
- Provide exactly $count different meal suggestions
- Format: "Meal Name: Brief description" (one per line, numbered)
- Keep each to 1-2 sentences
- Be specific about key ingredients and what nutrients they provide
- Focus on what they STILL NEED, avoid what they've EXCEEDED
- Vary meal types (snack, light meal, etc.)
- IMPORTANT: Plain text only, NO JSON, NO quotes around text, NO markdown

Respond in this EXACT format:
1. Meal Name: Description focusing on the nutrients it provides.
2. Meal Name: Description focusing on the nutrients it provides.
''';

    try {
      final response = await _callAI(prompt);
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('MEAL SUGGESTIONS - Raw AI response:');
      debugPrint(response);
      debugPrint('═══════════════════════════════════════════════════════════');
      final parsed = _parseMultipleSuggestions(response, count);
      debugPrint('MEAL SUGGESTIONS - Parsed ${parsed.length} suggestions');
      for (var i = 0; i < parsed.length; i++) {
        debugPrint('  ${i + 1}. ${parsed[i]}');
      }
      return parsed;
    } catch (e) {
      debugPrint('MEAL SUGGESTIONS ERROR: $e');
      return ['Unable to generate recommendations. Please try again.'];
    }
  }

  /// Parse multiple meal suggestions from AI response
  List<String> _parseMultipleSuggestions(String response, int expectedCount) {
    var cleaned = response.trim();
    
    // Remove markdown code blocks if present
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'^```\w*\n?'), '').replaceAll(RegExp(r'\n?```$'), '');
    }

    // Try to parse as JSON first (AI might return JSON despite instructions)
    try {
      final decoded = jsonDecode(cleaned);
      final suggestions = _extractSuggestionsFromJson(decoded);
      if (suggestions.isNotEmpty) {
        return suggestions.take(expectedCount).toList();
      }
    } catch (_) {
      // Not JSON, parse as plain text
    }

    // Split by numbered lines (1., 2., etc.)
    final lines = cleaned.split(RegExp(r'\n+'));
    final suggestions = <String>[];

    for (final line in lines) {
      final trimmed = _cleanSuggestionText(line);
      // Skip JSON-like lines (keys like "field_name": or just braces/brackets)
      if (_isJsonArtifact(trimmed)) {
        continue;
      }
      if (trimmed.isNotEmpty && trimmed.contains(':')) {
        suggestions.add(trimmed);
      }
    }

    // If parsing failed, return the whole response as a single suggestion
    if (suggestions.isEmpty) {
      return [_cleanMealSuggestion(cleaned)];
    }

    return suggestions.take(expectedCount).toList();
  }

  /// Check if a line looks like a JSON artifact rather than a meal suggestion
  bool _isJsonArtifact(String text) {
    final trimmed = text.trim();
    // Empty or just punctuation
    if (trimmed.isEmpty || RegExp(r'^[\[\]\{\},]+$').hasMatch(trimmed)) {
      return true;
    }
    // Looks like a JSON key (snake_case or camelCase ending with quote-colon)
    if (RegExp(r'^"?[a-z_][a-z0-9_]*"?\s*:\s*[\[\{]?$', caseSensitive: false).hasMatch(trimmed)) {
      return true;
    }
    // Just a number or boolean
    if (RegExp(r'^(null|true|false|\d+\.?\d*)$').hasMatch(trimmed)) {
      return true;
    }
    // Very short text that's likely a JSON value (under 3 chars or just digits)
    if (trimmed.length < 3 || RegExp(r'^\d+$').hasMatch(trimmed)) {
      return true;
    }
    return false;
  }

  /// Recursively extract meal suggestions from JSON structure
  List<String> _extractSuggestionsFromJson(dynamic json) {
    final results = <String>[];
    
    if (json is List) {
      for (final item in json) {
        if (item is String && item.contains(':') && !_isJsonArtifact(item)) {
          results.add(_cleanSuggestionText(item));
        } else if (item is Map<String, dynamic>) {
          // Try to extract meal name and description from object
          final extracted = _extractMealFromObject(item);
          if (extracted != null) {
            results.add(extracted);
          }
        } else {
          results.addAll(_extractSuggestionsFromJson(item));
        }
      }
    } else if (json is Map<String, dynamic>) {
      // Look for common array field names
      final arrayKeys = ['suggestions', 'meals', 'meal_suggestions', 'recommendations', 'ideas', 'items', 'results'];
      for (final key in arrayKeys) {
        if (json.containsKey(key) && json[key] is List) {
          results.addAll(_extractSuggestionsFromJson(json[key]));
          if (results.isNotEmpty) return results;
        }
      }
      // Search all values for arrays
      for (final value in json.values) {
        if (value is List || value is Map) {
          results.addAll(_extractSuggestionsFromJson(value));
          if (results.isNotEmpty) return results;
        }
      }
    }
    
    return results;
  }

  /// Extract meal suggestion from a JSON object with name/description fields
  String? _extractMealFromObject(Map<String, dynamic> obj) {
    // Common field name patterns for meal name
    final nameKeys = ['name', 'meal', 'meal_name', 'title', 'dish'];
    // Common field name patterns for description
    final descKeys = ['description', 'desc', 'details', 'info', 'summary', 'about'];
    
    String? name;
    String? description;
    
    for (final key in nameKeys) {
      if (obj.containsKey(key) && obj[key] is String) {
        name = obj[key] as String;
        break;
      }
    }
    
    for (final key in descKeys) {
      if (obj.containsKey(key) && obj[key] is String) {
        description = obj[key] as String;
        break;
      }
    }
    
    if (name != null && name.isNotEmpty) {
      if (description != null && description.isNotEmpty) {
        return '$name: $description';
      }
      return name;
    }
    
    return null;
  }

  /// Clean up a single suggestion text
  String _cleanSuggestionText(String text) {
    var cleaned = text.trim();
    
    // Remove leading quotes and numbers like "1.", '"1.', '2.', etc.
    cleaned = cleaned.replaceFirst(RegExp(r'''^["']*\d+[.\)]\s*'''), '');
    
    // Remove leading quotes
    cleaned = cleaned.replaceFirst(RegExp(r'''^["']+'''), '');
    
    // Remove trailing quotes
    cleaned = cleaned.replaceFirst(RegExp(r'''["']+$'''), '');
    
    // Remove trailing commas
    cleaned = cleaned.replaceFirst(RegExp(r',\s*$'), '');
    
    // Remove JSON-like artifacts
    cleaned = cleaned.replaceFirst(RegExp(r'^\s*[\[\{]'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'[\]\}]\s*$'), '');
    
    return cleaned.trim();
  }

  /// Generate a detailed recipe for a meal
  Future<MealRecipe> generateRecipe(String mealName) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('API key not configured');
    }

    final prompt = '''
Generate a detailed recipe for: $mealName

Respond with ONLY this JSON format:
{
  "name": "$mealName",
  "servings": <number of servings>,
  "prepTime": "<prep time, e.g. '15 mins'>",
  "cookTime": "<cook time, e.g. '30 mins'>",
  "difficulty": "<Easy/Medium/Hard>",
  "ingredients": [
    {"item": "<ingredient name>", "amount": "<quantity with unit>"},
    ...
  ],
  "instructions": [
    "<step 1>",
    "<step 2>",
    ...
  ],
  "nutritionPerServing": {
    "calories": <number>,
    "protein": <grams>,
    "carbs": <grams>,
    "fat": <grams>,
    "fiber": <grams>
  },
  "tips": "<optional cooking tip or variation>"
}
''';

    try {
      final response = await _callAI(prompt);
      return _parseRecipeResponse(response, mealName);
    } catch (e) {
      debugPrint('Error generating recipe: $e');
      throw Exception('Failed to generate recipe: $e');
    }
  }

  /// Parse the recipe response from AI
  MealRecipe _parseRecipeResponse(String response, String mealName) {
    var cleaned = response.trim();
    
    // Remove markdown code blocks if present
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'^```\w*\n?'), '').replaceAll(RegExp(r'\n?```$'), '');
    }
    
    // Try to extract JSON
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
    if (jsonMatch != null) {
      cleaned = jsonMatch.group(0)!;
    }

    try {
      final data = jsonDecode(cleaned) as Map<String, dynamic>;
      
      // Parse ingredients
      final ingredientsList = (data['ingredients'] as List<dynamic>?)?.map((item) {
        if (item is Map<String, dynamic>) {
          return RecipeIngredient(
            item: item['item'] as String? ?? '',
            amount: item['amount'] as String? ?? '',
          );
        }
        return RecipeIngredient(item: item.toString(), amount: '');
      }).toList() ?? [];

      // Parse instructions
      final instructionsList = (data['instructions'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList() ?? [];

      // Parse nutrition
      final nutritionData = data['nutritionPerServing'] as Map<String, dynamic>?;

      return MealRecipe(
        name: data['name'] as String? ?? mealName,
        servings: (data['servings'] as num?)?.toInt() ?? 2,
        prepTime: data['prepTime'] as String? ?? '15 mins',
        cookTime: data['cookTime'] as String? ?? '30 mins',
        difficulty: data['difficulty'] as String? ?? 'Medium',
        ingredients: ingredientsList,
        instructions: instructionsList,
        caloriesPerServing: (nutritionData?['calories'] as num?)?.toDouble(),
        proteinPerServing: (nutritionData?['protein'] as num?)?.toDouble(),
        carbsPerServing: (nutritionData?['carbs'] as num?)?.toDouble(),
        fatPerServing: (nutritionData?['fat'] as num?)?.toDouble(),
        fiberPerServing: (nutritionData?['fiber'] as num?)?.toDouble(),
        tips: data['tips'] as String?,
      );
    } catch (e) {
      debugPrint('Failed to parse recipe JSON: $e');
      // Return a basic recipe with just the name
      return MealRecipe(
        name: mealName,
        servings: 2,
        prepTime: 'Unknown',
        cookTime: 'Unknown',
        difficulty: 'Unknown',
        ingredients: [],
        instructions: ['Recipe generation failed. Please try again.'],
      );
    }
  }
  
  /// Legacy method for single-day recommendations (kept for compatibility)
  Future<String> getAIMealRecommendationForDay(NutritionSummary summary, {String? preferences}) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('API key not configured');
    }

    final deficiencies = summary.getDeficiencies();
    if (deficiencies.isEmpty) {
      return "You're doing great! Your nutrition looks balanced today. Keep it up!";
    }

    final deficiencyList = deficiencies.map((d) => '${d.name}: ${d.current.toStringAsFixed(0)}/${d.recommended.toStringAsFixed(0)} ${d.unit} (${d.percentage.toStringAsFixed(0)}%)').join('\n');

    final prompt = '''
You're a helpful nutritionist. Suggest ONE specific meal or snack based on today's nutritional gaps.

Today's intake: ${summary.calories.toStringAsFixed(0)} cal, ${summary.protein.toStringAsFixed(0)}g protein, ${summary.fiber.toStringAsFixed(0)}g fiber

Low nutrients today:
$deficiencyList
${preferences != null ? '\nDietary preferences: $preferences' : ''}

Requirements:
- Start with meal name and colon (e.g., "Greek Yogurt Parfait:")
- 2-3 sentences max
- Be specific about ingredients
- No JSON formatting

Example: Spinach & Feta Omelet: A 3-egg omelet with spinach, feta, and tomatoes. Great for iron and calcium.
''';

    try {
      final response = await _callAI(prompt);
      return _cleanMealSuggestion(response);
    } catch (e) {
      return 'Unable to generate recommendation.';
    }
  }

  /// Clean up the meal suggestion response - handle JSON or plain text
  String _cleanMealSuggestion(String response) {
    var cleaned = response.trim();
    
    // Remove markdown code blocks if present
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'^```\w*\n?'), '').replaceAll(RegExp(r'\n?```$'), '');
    }
    
    // Try to parse as JSON in case the AI returned structured data
    try {
      final data = jsonDecode(cleaned);
      if (data is Map<String, dynamic>) {
        // Check common fields the AI might use
        if (data.containsKey('suggestion')) {
          return data['suggestion'] as String;
        }
        if (data.containsKey('meal')) {
          return data['meal'] as String;
        }
        if (data.containsKey('recommendation')) {
          return data['recommendation'] as String;
        }
        if (data.containsKey('response')) {
          return data['response'] as String;
        }
        if (data.containsKey('text')) {
          return data['text'] as String;
        }
        // If it's JSON but no known field, return the first string value
        for (final value in data.values) {
          if (value is String && value.length > 20) {
            return value;
          }
        }
      }
    } catch (_) {
      // Not JSON, use as plain text
    }
    
    // Remove surrounding quotes if present
    if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
        (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    
    return cleaned;
  }
}

/// Collection of food recommendations
class FoodRecommendations {
  const FoodRecommendations({
    required this.quickFoods,
    required this.mealIdeas,
    required this.deficientNutrients,
  });

  final List<QuickFoodItem> quickFoods;
  final List<MealIdea> mealIdeas;
  final List<String> deficientNutrients;

  bool get hasRecommendations => quickFoods.isNotEmpty || mealIdeas.isNotEmpty;
}

/// A quick food item that can help fill nutritional gaps
class QuickFoodItem {
  const QuickFoodItem(this.name, this.emoji, this.benefit, this.nutrients);

  final String name;
  final String emoji;
  final String benefit;
  final List<String> nutrients;
}

/// A complete meal idea
class MealIdea {
  const MealIdea(this.name, this.description, this.nutritionHighlight, this.nutrients);

  final String name;
  final String description;
  final String nutritionHighlight;
  final List<String> nutrients;
}

/// Result from nutrition analysis
class FoodNutritionResult {
  const FoodNutritionResult({
    required this.name,
    this.servingSize,
    this.servingUnit,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
    this.vitaminC,
    this.vitaminD,
    this.calcium,
    this.iron,
    this.potassium,
    this.healthScore,
    this.error,
    // Additional vitamins
    this.vitaminA,
    this.vitaminE,
    this.vitaminK,
    this.vitaminB1,
    this.vitaminB2,
    this.vitaminB3,
    this.vitaminB6,
    this.vitaminB12,
    this.folate,
    // Additional minerals
    this.magnesium,
    this.zinc,
    this.phosphorus,
    this.selenium,
    this.iodine,
    // Fatty acids
    this.omega3,
  });

  final String name;
  final double? servingSize;
  final String? servingUnit;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;
  final double? sugar;
  final double? sodium;
  final double? vitaminC;
  final double? vitaminD;
  final double? calcium;
  final double? iron;
  final double? potassium;
  final double? healthScore;
  final String? error;
  // Additional vitamins
  final double? vitaminA;
  final double? vitaminE;
  final double? vitaminK;
  final double? vitaminB1;
  final double? vitaminB2;
  final double? vitaminB3;
  final double? vitaminB6;
  final double? vitaminB12;
  final double? folate;
  // Additional minerals
  final double? magnesium;
  final double? zinc;
  final double? phosphorus;
  final double? selenium;
  final double? iodine;
  // Fatty acids
  final double? omega3;

  bool get hasError => error != null;

  /// Convert to FoodEntry
  FoodEntry toFoodEntry(String id, DateTime timestamp, {String? originalInput}) {
    return FoodEntry(
      id: id,
      name: name,
      timestamp: timestamp,
      originalInput: originalInput,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sugar: sugar,
      sodium: sodium,
      vitaminC: vitaminC,
      vitaminD: vitaminD,
      calcium: calcium,
      iron: iron,
      potassium: potassium,
      // Additional vitamins
      vitaminA: vitaminA,
      vitaminE: vitaminE,
      vitaminK: vitaminK,
      vitaminB1: vitaminB1,
      vitaminB2: vitaminB2,
      vitaminB3: vitaminB3,
      vitaminB6: vitaminB6,
      vitaminB12: vitaminB12,
      folate: folate,
      // Additional minerals
      magnesium: magnesium,
      zinc: zinc,
      phosphorus: phosphorus,
      selenium: selenium,
      iodine: iodine,
      // Fatty acids
      omega3: omega3,
      healthScore: healthScore,
      servingSize: servingSize,
      servingUnit: servingUnit,
    );
  }
}

/// Nutrition data per 100g for a single ingredient
class IngredientNutritionPer100g {
  const IngredientNutritionPer100g({
    required this.ingredientName,
    this.caloriesPer100g = 0,
    this.proteinPer100g = 0,
    this.carbsPer100g = 0,
    this.fatPer100g = 0,
    this.fiberPer100g = 0,
  });

  final String ingredientName;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double fiberPer100g;
}

/// Structured ingredient with name, amount, and unit
class StructuredIngredient {
  const StructuredIngredient({
    required this.name,
    required this.amount,
    required this.unit,
  });

  final String name;
  final double amount;
  final String unit;
}

/// Parsed food input with extracted food name and weight in grams
class _ParsedFoodInput {
  const _ParsedFoodInput(this.foodName, this.grams);

  final String foodName;
  final double grams;
}

/// A detailed recipe for a meal
class MealRecipe {
  const MealRecipe({
    required this.name,
    required this.servings,
    required this.prepTime,
    required this.cookTime,
    required this.difficulty,
    required this.ingredients,
    required this.instructions,
    this.caloriesPerServing,
    this.proteinPerServing,
    this.carbsPerServing,
    this.fatPerServing,
    this.fiberPerServing,
    this.tips,
  });

  final String name;
  final int servings;
  final String prepTime;
  final String cookTime;
  final String difficulty;
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;
  final double? caloriesPerServing;
  final double? proteinPerServing;
  final double? carbsPerServing;
  final double? fatPerServing;
  final double? fiberPerServing;
  final String? tips;

  String get totalTime {
    // Try to parse and add prep + cook times
    final prepMins = _parseMinutes(prepTime);
    final cookMins = _parseMinutes(cookTime);
    if (prepMins != null && cookMins != null) {
      final total = prepMins + cookMins;
      if (total >= 60) {
        final hours = total ~/ 60;
        final mins = total % 60;
        return mins > 0 ? '$hours hr $mins mins' : '$hours hr';
      }
      return '$total mins';
    }
    return '$prepTime + $cookTime';
  }

  int? _parseMinutes(String time) {
    final match = RegExp(r'(\d+)').firstMatch(time);
    if (match != null) {
      final num = int.tryParse(match.group(1)!);
      if (time.toLowerCase().contains('hr') || time.toLowerCase().contains('hour')) {
        return (num ?? 0) * 60;
      }
      return num;
    }
    return null;
  }
}

/// An ingredient in a recipe
class RecipeIngredient {
  const RecipeIngredient({
    required this.item,
    required this.amount,
  });

  final String item;
  final String amount;
}

