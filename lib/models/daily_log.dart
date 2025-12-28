import 'package:hive/hive.dart';

part 'daily_log.g.dart';

/// Represents a single day's tracked health data.
/// Each day has one DailyLog entry, identified by date string (yyyy-MM-dd).
@HiveType(typeId: 0)
class DailyLog extends HiveObject {
  DailyLog({
    required this.date,
    this.waterLiters = 0.0,
    this.exerciseMinutes = 0,
    this.sunlightMinutes = 0,
    this.sleepHours = 0.0,
    List<FoodEntry>? foodEntries,
    this.notes = '',
    this.socialMinutes = 0,
  }) : foodEntries = foodEntries ?? [];

  /// Date in yyyy-MM-dd format (used as key)
  @HiveField(0)
  final String date;

  /// Water intake in liters
  @HiveField(1)
  double waterLiters;

  /// Exercise duration in minutes
  @HiveField(2)
  int exerciseMinutes;

  /// Sunlight exposure in minutes
  @HiveField(3)
  int sunlightMinutes;

  /// Sleep duration in hours
  @HiveField(4)
  double sleepHours;

  /// List of food entries for the day
  @HiveField(5)
  List<FoodEntry> foodEntries;

  /// Optional notes for the day
  @HiveField(6)
  String notes;

  /// Social interaction in minutes
  @HiveField(7)
  int socialMinutes;

  /// Creates a copy with updated fields
  DailyLog copyWith({
    String? date,
    double? waterLiters,
    int? exerciseMinutes,
    int? sunlightMinutes,
    double? sleepHours,
    List<FoodEntry>? foodEntries,
    String? notes,
    int? socialMinutes,
  }) {
    return DailyLog(
      date: date ?? this.date,
      waterLiters: waterLiters ?? this.waterLiters,
      exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
      sunlightMinutes: sunlightMinutes ?? this.sunlightMinutes,
      sleepHours: sleepHours ?? this.sleepHours,
      foodEntries: foodEntries ?? List.from(this.foodEntries),
      notes: notes ?? this.notes,
      socialMinutes: socialMinutes ?? this.socialMinutes,
    );
  }

  /// Calculate total nutrition for the day
  NutritionSummary get nutritionSummary {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    double totalSugar = 0;
    double totalSodium = 0;
    double totalVitaminC = 0;
    double totalVitaminD = 0;
    double totalCalcite = 0;
    double totalIron = 0;
    double totalPotassium = 0;

    for (final entry in foodEntries) {
      totalCalories += entry.calories ?? 0;
      totalProtein += entry.protein ?? 0;
      totalCarbs += entry.carbs ?? 0;
      totalFat += entry.fat ?? 0;
      totalFiber += entry.fiber ?? 0;
      totalSugar += entry.sugar ?? 0;
      totalSodium += entry.sodium ?? 0;
      totalVitaminC += entry.vitaminC ?? 0;
      totalVitaminD += entry.vitaminD ?? 0;
      totalCalcite += entry.calcium ?? 0;
      totalIron += entry.iron ?? 0;
      totalPotassium += entry.potassium ?? 0;
    }

    return NutritionSummary(
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      fiber: totalFiber,
      sugar: totalSugar,
      sodium: totalSodium,
      vitaminC: totalVitaminC,
      vitaminD: totalVitaminD,
      calcium: totalCalcite,
      iron: totalIron,
      potassium: totalPotassium,
    );
  }
}

/// Represents a single food entry with optional AI-analyzed nutrition data.
@HiveType(typeId: 1)
class FoodEntry extends HiveObject {
  FoodEntry({
    required this.id,
    required this.name,
    required this.timestamp,
    this.originalInput,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.healthScore,
    this.imagePath,
    this.aiAnalysis,
    this.fiber,
    this.sugar,
    this.sodium,
    this.vitaminC,
    this.vitaminD,
    this.calcium,
    this.iron,
    this.potassium,
    this.servingSize,
    this.servingUnit,
  });

  /// Unique identifier
  @HiveField(0)
  final String id;

  /// Food name/description
  @HiveField(1)
  String name;

  /// When the food was logged
  @HiveField(2)
  final DateTime timestamp;

  /// Calories (kcal)
  @HiveField(3)
  double? calories;

  /// Protein in grams
  @HiveField(4)
  double? protein;

  /// Carbohydrates in grams
  @HiveField(5)
  double? carbs;

  /// Fat in grams
  @HiveField(6)
  double? fat;

  /// AI-generated health score (0-10)
  @HiveField(7)
  double? healthScore;

  /// Path to food image if captured
  @HiveField(8)
  String? imagePath;

  /// Raw AI analysis response for reference
  @HiveField(9)
  String? aiAnalysis;

  /// Fiber in grams
  @HiveField(10)
  double? fiber;

  /// Sugar in grams
  @HiveField(11)
  double? sugar;

  /// Sodium in mg
  @HiveField(12)
  double? sodium;

  /// Vitamin C in mg
  @HiveField(13)
  double? vitaminC;

  /// Vitamin D in mcg
  @HiveField(14)
  double? vitaminD;

  /// Calcium in mg
  @HiveField(15)
  double? calcium;

  /// Iron in mg
  @HiveField(16)
  double? iron;

  /// Potassium in mg
  @HiveField(17)
  double? potassium;

  /// Serving size amount
  @HiveField(18)
  double? servingSize;

  /// Serving size unit (g, ml, oz, cup, etc.)
  @HiveField(19)
  String? servingUnit;

  /// Original user input (before AI cleanup)
  @HiveField(20)
  String? originalInput;
}

/// Summary of daily nutrition intake
class NutritionSummary {
  const NutritionSummary({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.vitaminC = 0,
    this.vitaminD = 0,
    this.calcium = 0,
    this.iron = 0,
    this.potassium = 0,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final double vitaminC;
  final double vitaminD;
  final double calcium;
  final double iron;
  final double potassium;

  /// Recommended daily values (general adult)
  static const recommendedDaily = NutritionSummary(
    calories: 2000,
    protein: 50,      // grams
    carbs: 275,       // grams
    fat: 78,          // grams
    fiber: 28,        // grams
    sugar: 50,        // grams (max)
    sodium: 2300,     // mg (max)
    vitaminC: 90,     // mg
    vitaminD: 20,     // mcg
    calcium: 1000,    // mg
    iron: 18,         // mg
    potassium: 4700,  // mg
  );

  /// Get deficiencies (nutrients below 50% of recommended)
  List<NutrientDeficiency> getDeficiencies() {
    final deficiencies = <NutrientDeficiency>[];
    final rec = NutritionSummary.recommendedDaily;

    if (protein < rec.protein * 0.5) {
      deficiencies.add(NutrientDeficiency('Protein', protein, rec.protein, 'g'));
    }
    if (fiber < rec.fiber * 0.5) {
      deficiencies.add(NutrientDeficiency('Fiber', fiber, rec.fiber, 'g'));
    }
    if (vitaminC < rec.vitaminC * 0.5) {
      deficiencies.add(NutrientDeficiency('Vitamin C', vitaminC, rec.vitaminC, 'mg'));
    }
    if (vitaminD < rec.vitaminD * 0.5) {
      deficiencies.add(NutrientDeficiency('Vitamin D', vitaminD, rec.vitaminD, 'mcg'));
    }
    if (calcium < rec.calcium * 0.5) {
      deficiencies.add(NutrientDeficiency('Calcium', calcium, rec.calcium, 'mg'));
    }
    if (iron < rec.iron * 0.5) {
      deficiencies.add(NutrientDeficiency('Iron', iron, rec.iron, 'mg'));
    }
    if (potassium < rec.potassium * 0.5) {
      deficiencies.add(NutrientDeficiency('Potassium', potassium, rec.potassium, 'mg'));
    }

    return deficiencies;
  }

  /// Get percentage of daily value
  double getPercentage(double current, double recommended) {
    if (recommended == 0) return 0;
    return (current / recommended * 100).clamp(0, 200);
  }
}

/// Represents a nutrient deficiency
class NutrientDeficiency {
  const NutrientDeficiency(this.name, this.current, this.recommended, this.unit);
  
  final String name;
  final double current;
  final double recommended;
  final String unit;

  double get percentage => recommended > 0 ? (current / recommended * 100) : 0;
}

/// Multi-day nutrition overview for identifying real deficiency patterns
class MultiDayNutritionOverview {
  MultiDayNutritionOverview({
    required this.daysAnalyzed,
    required this.daysWithData,
    required this.averageIntake,
    required this.todayIntake,
    required this.consistentDeficiencies,
    required this.recentTrends,
  });

  /// How many days we looked back
  final int daysAnalyzed;
  
  /// How many of those days had food logged
  final int daysWithData;
  
  /// Average daily intake over the period
  final NutritionSummary averageIntake;
  
  /// Today's intake (for context)
  final NutritionSummary todayIntake;
  
  /// Nutrients that are consistently low (deficient on 50%+ of days with data)
  final List<NutrientTrend> consistentDeficiencies;
  
  /// Trends for each nutrient (improving, declining, stable)
  final Map<String, NutrientTrend> recentTrends;

  /// Create from a list of daily logs
  factory MultiDayNutritionOverview.fromLogs(List<DailyLog> logs, {int lookbackDays = 7}) {
    final rec = NutritionSummary.recommendedDaily;
    
    // Filter to logs that have food entries
    final logsWithFood = logs.where((log) => log.foodEntries.isNotEmpty).toList();
    final daysWithData = logsWithFood.length;
    
    if (daysWithData == 0) {
      return MultiDayNutritionOverview(
        daysAnalyzed: lookbackDays,
        daysWithData: 0,
        averageIntake: const NutritionSummary(),
        todayIntake: const NutritionSummary(),
        consistentDeficiencies: [],
        recentTrends: {},
      );
    }

    // Calculate totals and averages
    double totalCalories = 0, totalProtein = 0, totalCarbs = 0, totalFat = 0;
    double totalFiber = 0, totalVitaminC = 0, totalVitaminD = 0;
    double totalCalcium = 0, totalIron = 0, totalPotassium = 0;
    
    // Track deficiency counts
    int proteinDefDays = 0, fiberDefDays = 0, vitCDefDays = 0, vitDDefDays = 0;
    int calciumDefDays = 0, ironDefDays = 0, potassiumDefDays = 0;

    for (final log in logsWithFood) {
      final ns = log.nutritionSummary;
      totalCalories += ns.calories;
      totalProtein += ns.protein;
      totalCarbs += ns.carbs;
      totalFat += ns.fat;
      totalFiber += ns.fiber;
      totalVitaminC += ns.vitaminC;
      totalVitaminD += ns.vitaminD;
      totalCalcium += ns.calcium;
      totalIron += ns.iron;
      totalPotassium += ns.potassium;

      // Count days with deficiencies (below 70% of daily value)
      if (ns.protein < rec.protein * 0.7) proteinDefDays++;
      if (ns.fiber < rec.fiber * 0.7) fiberDefDays++;
      if (ns.vitaminC < rec.vitaminC * 0.7) vitCDefDays++;
      if (ns.vitaminD < rec.vitaminD * 0.7) vitDDefDays++;
      if (ns.calcium < rec.calcium * 0.7) calciumDefDays++;
      if (ns.iron < rec.iron * 0.7) ironDefDays++;
      if (ns.potassium < rec.potassium * 0.7) potassiumDefDays++;
    }

    final avgIntake = NutritionSummary(
      calories: totalCalories / daysWithData,
      protein: totalProtein / daysWithData,
      carbs: totalCarbs / daysWithData,
      fat: totalFat / daysWithData,
      fiber: totalFiber / daysWithData,
      vitaminC: totalVitaminC / daysWithData,
      vitaminD: totalVitaminD / daysWithData,
      calcium: totalCalcium / daysWithData,
      iron: totalIron / daysWithData,
      potassium: totalPotassium / daysWithData,
    );

    // Get today's intake (last log if it's today, otherwise empty)
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final todayLog = logs.where((l) => l.date == todayKey).firstOrNull;
    final todayIntake = todayLog?.nutritionSummary ?? const NutritionSummary();

    // Identify consistent deficiencies (deficient on 50%+ of days with data)
    final consistentDefs = <NutrientTrend>[];
    final threshold = daysWithData * 0.5;

    if (proteinDefDays >= threshold) {
      consistentDefs.add(NutrientTrend(
        name: 'Protein',
        averageIntake: avgIntake.protein,
        recommended: rec.protein,
        unit: 'g',
        deficientDays: proteinDefDays,
        totalDays: daysWithData,
      ));
    }
    if (fiberDefDays >= threshold) {
      consistentDefs.add(NutrientTrend(
        name: 'Fiber',
        averageIntake: avgIntake.fiber,
        recommended: rec.fiber,
        unit: 'g',
        deficientDays: fiberDefDays,
        totalDays: daysWithData,
      ));
    }
    if (vitCDefDays >= threshold) {
      consistentDefs.add(NutrientTrend(
        name: 'Vitamin C',
        averageIntake: avgIntake.vitaminC,
        recommended: rec.vitaminC,
        unit: 'mg',
        deficientDays: vitCDefDays,
        totalDays: daysWithData,
      ));
    }
    if (vitDDefDays >= threshold) {
      consistentDefs.add(NutrientTrend(
        name: 'Vitamin D',
        averageIntake: avgIntake.vitaminD,
        recommended: rec.vitaminD,
        unit: 'mcg',
        deficientDays: vitDDefDays,
        totalDays: daysWithData,
      ));
    }
    if (calciumDefDays >= threshold) {
      consistentDefs.add(NutrientTrend(
        name: 'Calcium',
        averageIntake: avgIntake.calcium,
        recommended: rec.calcium,
        unit: 'mg',
        deficientDays: calciumDefDays,
        totalDays: daysWithData,
      ));
    }
    if (ironDefDays >= threshold) {
      consistentDefs.add(NutrientTrend(
        name: 'Iron',
        averageIntake: avgIntake.iron,
        recommended: rec.iron,
        unit: 'mg',
        deficientDays: ironDefDays,
        totalDays: daysWithData,
      ));
    }
    if (potassiumDefDays >= threshold) {
      consistentDefs.add(NutrientTrend(
        name: 'Potassium',
        averageIntake: avgIntake.potassium,
        recommended: rec.potassium,
        unit: 'mg',
        deficientDays: potassiumDefDays,
        totalDays: daysWithData,
      ));
    }

    // Sort by severity (most days deficient first)
    consistentDefs.sort((a, b) => b.deficiencyRate.compareTo(a.deficiencyRate));

    return MultiDayNutritionOverview(
      daysAnalyzed: lookbackDays,
      daysWithData: daysWithData,
      averageIntake: avgIntake,
      todayIntake: todayIntake,
      consistentDeficiencies: consistentDefs,
      recentTrends: {},
    );
  }

  bool get hasEnoughData => daysWithData >= 2;
  bool get hasDeficiencies => consistentDeficiencies.isNotEmpty;

  /// Generate a concise summary for AI context
  String toAISummary() {
    final buffer = StringBuffer();
    
    if (!hasEnoughData) {
      buffer.writeln('Limited data: Only $daysWithData day(s) of food tracking available.');
      if (todayIntake.calories > 0) {
        buffer.writeln('Today so far: ${todayIntake.calories.toStringAsFixed(0)} cal, ${todayIntake.protein.toStringAsFixed(0)}g protein');
      }
      return buffer.toString();
    }

    buffer.writeln('Nutrition overview (last $daysAnalyzed days, $daysWithData days with data):');
    buffer.writeln('');
    buffer.writeln('Daily averages:');
    buffer.writeln('- Calories: ${averageIntake.calories.toStringAsFixed(0)} kcal');
    buffer.writeln('- Protein: ${averageIntake.protein.toStringAsFixed(0)}g (goal: 50g)');
    buffer.writeln('- Fiber: ${averageIntake.fiber.toStringAsFixed(0)}g (goal: 28g)');
    
    if (consistentDeficiencies.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Consistent deficiencies (nutrients low on most days):');
      for (final def in consistentDeficiencies.take(4)) {
        buffer.writeln('- ${def.name}: averaging ${def.averageIntake.toStringAsFixed(0)}${def.unit} vs ${def.recommended.toStringAsFixed(0)}${def.unit} goal (low on ${def.deficientDays}/${def.totalDays} days)');
      }
    } else {
      buffer.writeln('');
      buffer.writeln('No consistent deficiencies detected - nutrition generally balanced!');
    }

    if (todayIntake.calories > 0) {
      buffer.writeln('');
      buffer.writeln('Today so far: ${todayIntake.calories.toStringAsFixed(0)} cal, ${todayIntake.protein.toStringAsFixed(0)}g protein, ${todayIntake.fiber.toStringAsFixed(0)}g fiber');
    } else {
      buffer.writeln('');
      buffer.writeln('No food logged today yet.');
    }

    return buffer.toString();
  }
}

/// Trend data for a specific nutrient
class NutrientTrend {
  const NutrientTrend({
    required this.name,
    required this.averageIntake,
    required this.recommended,
    required this.unit,
    required this.deficientDays,
    required this.totalDays,
  });

  final String name;
  final double averageIntake;
  final double recommended;
  final String unit;
  final int deficientDays;
  final int totalDays;

  double get deficiencyRate => totalDays > 0 ? deficientDays / totalDays : 0;
  double get percentOfGoal => recommended > 0 ? (averageIntake / recommended * 100) : 0;
}

