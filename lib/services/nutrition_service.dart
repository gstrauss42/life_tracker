import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

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

  /// Analyze a food description and return estimated nutrition data
  Future<FoodNutritionResult> analyzeFood(String foodDescription) async {

    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('API key not configured. Please set your API key in Settings.');
    }

    final prompt = '''
You are a nutrition calculator. Calculate accurate nutrition for this food.

Input: $foodDescription

Instructions:
1. If weights are specified (e.g. "500g chicken"), calculate nutrition for that EXACT weight
2. Use standard nutrition database values (USDA) per 100g, then scale to actual weight
3. For multiple ingredients, calculate each separately then SUM all values
4. If no weight specified, estimate a typical serving size

Be accurate - protein especially matters. For meats, remember raw protein content is typically 20-31g per 100g depending on the cut.

Respond with ONLY this JSON (no other text):
{
  "name": "short meal name",
  "servingSize": <total grams>,
  "servingUnit": "g",
  "calories": <number>,
  "protein": <number>,
  "carbs": <number>,
  "fat": <number>,
  "fiber": <number>,
  "sugar": <number>,
  "sodium": <number>,
  "vitaminC": <number>,
  "vitaminD": <number>,
  "calcium": <number>,
  "iron": <number>,
  "potassium": <number>,
  "healthScore": <1-10>
}
''';

    try {
      final response = await _callAI(prompt);
      final result = _parseResponse(response, foodDescription);
      return result;
    } catch (e) {
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

  /// Analyze structured ingredients - gets per-100g values and calculates totals in code
  Future<FoodNutritionResult> analyzeStructuredIngredients({
    required String mealName,
    required List<StructuredIngredient> ingredients,
  }) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('API key not configured. Please set your API key in Settings.');
    }

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    double totalGrams = 0;

    for (final ingredient in ingredients) {
      if (ingredient.name.isEmpty) continue;

      // Get per-100g nutrition for this ingredient
      final per100g = await getNutritionPer100g(ingredient.name);
      
      // Convert amount to grams
      final grams = _convertToGrams(ingredient.amount, ingredient.unit);
      totalGrams += grams;
      
      // Calculate actual nutrition (our math, not AI's)
      final multiplier = grams / 100.0;
      totalCalories += per100g.caloriesPer100g * multiplier;
      totalProtein += per100g.proteinPer100g * multiplier;
      totalCarbs += per100g.carbsPer100g * multiplier;
      totalFat += per100g.fatPer100g * multiplier;
      totalFiber += per100g.fiberPer100g * multiplier;
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
      sugar: 0,
      sodium: 0,
      vitaminC: 0,
      vitaminD: 0,
      calcium: 0,
      iron: 0,
      potassium: 0,
      healthScore: 7,
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
      case 'cups':
        return amount * 240; // Approximate
      case 'tbsp':
        return amount * 15;
      case 'tsp':
        return amount * 5;
      case 'units':
        return amount * 50; // Rough estimate per unit
      default:
        return amount;
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
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.3,
        'max_tokens': 500,
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
        'max_tokens': 500,
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
            'content': 'You are a nutrition expert. When asked for JSON, respond with valid JSON only (no markdown). Otherwise respond naturally and helpfully.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.3,
        'max_tokens': 500,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('DeepSeek API error: ${response.statusCode} - ${response.data}');
    }

    // DeepSeek uses OpenAI-compatible response format
    return response.data['choices'][0]['message']['content'] as String;
  }

  FoodNutritionResult _parseResponse(String response, String originalName) {
    try {
      // Clean up response - remove markdown code blocks if present
      var cleaned = response.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'^```\w*\n?'), '').replaceAll(RegExp(r'\n?```$'), '');
      }

      final data = jsonDecode(cleaned) as Map<String, dynamic>;

      return FoodNutritionResult(
        name: data['name'] as String? ?? originalName,
        servingSize: (data['servingSize'] as num?)?.toDouble(),
        servingUnit: data['servingUnit'] as String?,
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
      );
    } catch (e) {
      return FoodNutritionResult(
        name: originalName,
        error: 'Failed to parse nutrition data: $e',
      );
    }
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
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('API key not configured');
    }

    // Check if there are any deficiencies to address
    if (!overview.hasDeficiencies && overview.todayIntake.getDeficiencies().isEmpty) {
      return "You're doing great! Your nutrition has been well-balanced recently. Keep it up!";
    }

    final nutritionContext = overview.toAISummary();

    final prompt = '''
You're a helpful nutritionist. Based on the user's nutrition patterns over the past week, suggest ONE specific, practical meal or snack.

$nutritionContext
${preferences != null ? '\nDietary preferences: $preferences' : ''}

Requirements:
- Start with the meal name followed by a colon (e.g., "Salmon Buddha Bowl:" or "Greek Yogurt Parfait:")
- Keep it to 2-3 sentences max
- Be specific about key ingredients
- Focus on addressing their CONSISTENT deficiencies (nutrients they're regularly low on), not just today
- Make it realistic and appetizing
- Vary your suggestions - consider different cuisines and meal types
- Respond with ONLY the suggestion text, no JSON formatting or markdown

Example response:
Spinach & Feta Omelet: A 3-egg omelet with sautéed spinach, feta cheese, and cherry tomatoes. This helps with your ongoing iron and calcium needs while adding quality protein.
''';

    try {
      final response = await _callAI(prompt);
      return _cleanMealSuggestion(response);
    } catch (e) {
      return 'Unable to generate recommendation. Try some of the suggested foods above!';
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

