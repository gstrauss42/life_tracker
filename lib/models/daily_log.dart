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
    double totalCalcium = 0;
    double totalIron = 0;
    double totalPotassium = 0;
    // Additional vitamins
    double totalVitaminA = 0;
    double totalVitaminE = 0;
    double totalVitaminK = 0;
    double totalVitaminB1 = 0;
    double totalVitaminB2 = 0;
    double totalVitaminB3 = 0;
    double totalVitaminB6 = 0;
    double totalVitaminB12 = 0;
    double totalFolate = 0;
    // Additional minerals
    double totalMagnesium = 0;
    double totalZinc = 0;
    double totalPhosphorus = 0;
    double totalSelenium = 0;
    double totalIodine = 0;
    // Fatty acids
    double totalOmega3 = 0;

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
      totalCalcium += entry.calcium ?? 0;
      totalIron += entry.iron ?? 0;
      totalPotassium += entry.potassium ?? 0;
      // Additional vitamins
      totalVitaminA += entry.vitaminA ?? 0;
      totalVitaminE += entry.vitaminE ?? 0;
      totalVitaminK += entry.vitaminK ?? 0;
      totalVitaminB1 += entry.vitaminB1 ?? 0;
      totalVitaminB2 += entry.vitaminB2 ?? 0;
      totalVitaminB3 += entry.vitaminB3 ?? 0;
      totalVitaminB6 += entry.vitaminB6 ?? 0;
      totalVitaminB12 += entry.vitaminB12 ?? 0;
      totalFolate += entry.folate ?? 0;
      // Additional minerals
      totalMagnesium += entry.magnesium ?? 0;
      totalZinc += entry.zinc ?? 0;
      totalPhosphorus += entry.phosphorus ?? 0;
      totalSelenium += entry.selenium ?? 0;
      totalIodine += entry.iodine ?? 0;
      // Fatty acids
      totalOmega3 += entry.omega3 ?? 0;
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
      calcium: totalCalcium,
      iron: totalIron,
      potassium: totalPotassium,
      // Additional vitamins
      vitaminA: totalVitaminA,
      vitaminE: totalVitaminE,
      vitaminK: totalVitaminK,
      vitaminB1: totalVitaminB1,
      vitaminB2: totalVitaminB2,
      vitaminB3: totalVitaminB3,
      vitaminB6: totalVitaminB6,
      vitaminB12: totalVitaminB12,
      folate: totalFolate,
      // Additional minerals
      magnesium: totalMagnesium,
      zinc: totalZinc,
      phosphorus: totalPhosphorus,
      selenium: totalSelenium,
      iodine: totalIodine,
      // Fatty acids
      omega3: totalOmega3,
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

  // === Additional Vitamins ===

  /// Vitamin A in mcg RAE
  @HiveField(21)
  double? vitaminA;

  /// Vitamin E in mg
  @HiveField(22)
  double? vitaminE;

  /// Vitamin K in mcg
  @HiveField(23)
  double? vitaminK;

  /// Vitamin B1 (Thiamin) in mg
  @HiveField(24)
  double? vitaminB1;

  /// Vitamin B2 (Riboflavin) in mg
  @HiveField(25)
  double? vitaminB2;

  /// Vitamin B3 (Niacin) in mg
  @HiveField(26)
  double? vitaminB3;

  /// Vitamin B6 in mg
  @HiveField(27)
  double? vitaminB6;

  /// Vitamin B12 in mcg
  @HiveField(28)
  double? vitaminB12;

  /// Folate in mcg DFE
  @HiveField(29)
  double? folate;

  // === Additional Minerals ===

  /// Magnesium in mg
  @HiveField(30)
  double? magnesium;

  /// Zinc in mg
  @HiveField(31)
  double? zinc;

  /// Phosphorus in mg
  @HiveField(32)
  double? phosphorus;

  /// Selenium in mcg
  @HiveField(33)
  double? selenium;

  /// Iodine in mcg
  @HiveField(34)
  double? iodine;

  // === Fatty Acids ===

  /// Omega-3 fatty acids in g
  @HiveField(35)
  double? omega3;
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
    // Additional vitamins
    this.vitaminA = 0,
    this.vitaminE = 0,
    this.vitaminK = 0,
    this.vitaminB1 = 0,
    this.vitaminB2 = 0,
    this.vitaminB3 = 0,
    this.vitaminB6 = 0,
    this.vitaminB12 = 0,
    this.folate = 0,
    // Additional minerals
    this.magnesium = 0,
    this.zinc = 0,
    this.phosphorus = 0,
    this.selenium = 0,
    this.iodine = 0,
    // Fatty acids
    this.omega3 = 0,
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
  // Additional vitamins
  final double vitaminA;
  final double vitaminE;
  final double vitaminK;
  final double vitaminB1;
  final double vitaminB2;
  final double vitaminB3;
  final double vitaminB6;
  final double vitaminB12;
  final double folate;
  // Additional minerals
  final double magnesium;
  final double zinc;
  final double phosphorus;
  final double selenium;
  final double iodine;
  // Fatty acids
  final double omega3;

  /// Recommended daily values (general adult)
  static const recommendedDaily = NutritionSummary(
    calories: 2000,
    protein: 50,       // grams
    carbs: 275,        // grams
    fat: 78,           // grams
    fiber: 28,         // grams
    sugar: 50,         // grams (max)
    sodium: 2300,      // mg (max)
    vitaminC: 90,      // mg
    vitaminD: 20,      // mcg
    calcium: 1000,     // mg
    iron: 18,          // mg
    potassium: 4700,   // mg
    // Additional vitamins
    vitaminA: 900,     // mcg RAE
    vitaminE: 15,      // mg
    vitaminK: 120,     // mcg
    vitaminB1: 1.2,    // mg (Thiamin)
    vitaminB2: 1.3,    // mg (Riboflavin)
    vitaminB3: 16,     // mg (Niacin)
    vitaminB6: 1.7,    // mg
    vitaminB12: 2.4,   // mcg
    folate: 400,       // mcg DFE
    // Additional minerals
    magnesium: 420,    // mg
    zinc: 11,          // mg
    phosphorus: 700,   // mg
    selenium: 55,      // mcg
    iodine: 150,       // mcg
    // Fatty acids
    omega3: 1.6,       // g (ALA recommendation)
  );

  /// Get deficiencies (nutrients below 50% of recommended)
  List<NutrientDeficiency> getDeficiencies() {
    final deficiencies = <NutrientDeficiency>[];
    final rec = NutritionSummary.recommendedDaily;

    // Macros
    if (protein < rec.protein * 0.5) {
      deficiencies.add(NutrientDeficiency('Protein', protein, rec.protein, 'g'));
    }
    if (fiber < rec.fiber * 0.5) {
      deficiencies.add(NutrientDeficiency('Fiber', fiber, rec.fiber, 'g'));
    }

    // Original vitamins
    if (vitaminC < rec.vitaminC * 0.5) {
      deficiencies.add(NutrientDeficiency('Vitamin C', vitaminC, rec.vitaminC, 'mg'));
    }
    if (vitaminD < rec.vitaminD * 0.5) {
      deficiencies.add(NutrientDeficiency('Vitamin D', vitaminD, rec.vitaminD, 'mcg'));
    }

    // Additional vitamins
    if (vitaminA < rec.vitaminA * 0.5) {
      deficiencies.add(NutrientDeficiency('Vitamin A', vitaminA, rec.vitaminA, 'mcg'));
    }
    if (vitaminE < rec.vitaminE * 0.5) {
      deficiencies.add(NutrientDeficiency('Vitamin E', vitaminE, rec.vitaminE, 'mg'));
    }
    if (vitaminK < rec.vitaminK * 0.5) {
      deficiencies.add(NutrientDeficiency('Vitamin K', vitaminK, rec.vitaminK, 'mcg'));
    }
    if (vitaminB1 < rec.vitaminB1 * 0.5) {
      deficiencies.add(NutrientDeficiency('Vitamin B1', vitaminB1, rec.vitaminB1, 'mg'));
    }
    if (vitaminB2 < rec.vitaminB2 * 0.5) {
      deficiencies.add(NutrientDeficiency('Vitamin B2', vitaminB2, rec.vitaminB2, 'mg'));
    }
    if (vitaminB3 < rec.vitaminB3 * 0.5) {
      deficiencies.add(NutrientDeficiency('Vitamin B3', vitaminB3, rec.vitaminB3, 'mg'));
    }
    if (vitaminB6 < rec.vitaminB6 * 0.5) {
      deficiencies.add(NutrientDeficiency('Vitamin B6', vitaminB6, rec.vitaminB6, 'mg'));
    }
    if (vitaminB12 < rec.vitaminB12 * 0.5) {
      deficiencies.add(NutrientDeficiency('Vitamin B12', vitaminB12, rec.vitaminB12, 'mcg'));
    }
    if (folate < rec.folate * 0.5) {
      deficiencies.add(NutrientDeficiency('Folate', folate, rec.folate, 'mcg'));
    }

    // Original minerals
    if (calcium < rec.calcium * 0.5) {
      deficiencies.add(NutrientDeficiency('Calcium', calcium, rec.calcium, 'mg'));
    }
    if (iron < rec.iron * 0.5) {
      deficiencies.add(NutrientDeficiency('Iron', iron, rec.iron, 'mg'));
    }
    if (potassium < rec.potassium * 0.5) {
      deficiencies.add(NutrientDeficiency('Potassium', potassium, rec.potassium, 'mg'));
    }

    // Additional minerals
    if (magnesium < rec.magnesium * 0.5) {
      deficiencies.add(NutrientDeficiency('Magnesium', magnesium, rec.magnesium, 'mg'));
    }
    if (zinc < rec.zinc * 0.5) {
      deficiencies.add(NutrientDeficiency('Zinc', zinc, rec.zinc, 'mg'));
    }
    if (phosphorus < rec.phosphorus * 0.5) {
      deficiencies.add(NutrientDeficiency('Phosphorus', phosphorus, rec.phosphorus, 'mg'));
    }
    if (selenium < rec.selenium * 0.5) {
      deficiencies.add(NutrientDeficiency('Selenium', selenium, rec.selenium, 'mcg'));
    }
    if (iodine < rec.iodine * 0.5) {
      deficiencies.add(NutrientDeficiency('Iodine', iodine, rec.iodine, 'mcg'));
    }

    // Fatty acids
    if (omega3 < rec.omega3 * 0.5) {
      deficiencies.add(NutrientDeficiency('Omega-3', omega3, rec.omega3, 'g'));
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
    // Additional vitamins
    double totalVitaminA = 0, totalVitaminE = 0, totalVitaminK = 0;
    double totalVitaminB1 = 0, totalVitaminB2 = 0, totalVitaminB3 = 0;
    double totalVitaminB6 = 0, totalVitaminB12 = 0, totalFolate = 0;
    // Additional minerals
    double totalMagnesium = 0, totalZinc = 0, totalPhosphorus = 0;
    double totalSelenium = 0, totalIodine = 0;
    // Fatty acids
    double totalOmega3 = 0;
    
    // Track deficiency counts
    int proteinDefDays = 0, fiberDefDays = 0, vitCDefDays = 0, vitDDefDays = 0;
    int calciumDefDays = 0, ironDefDays = 0, potassiumDefDays = 0;
    // Additional vitamins
    int vitADefDays = 0, vitEDefDays = 0, vitKDefDays = 0;
    int vitB1DefDays = 0, vitB2DefDays = 0, vitB3DefDays = 0;
    int vitB6DefDays = 0, vitB12DefDays = 0, folateDefDays = 0;
    // Additional minerals
    int magnesiumDefDays = 0, zincDefDays = 0, phosphorusDefDays = 0;
    int seleniumDefDays = 0, iodineDefDays = 0;
    // Fatty acids
    int omega3DefDays = 0;

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
      // Additional vitamins
      totalVitaminA += ns.vitaminA;
      totalVitaminE += ns.vitaminE;
      totalVitaminK += ns.vitaminK;
      totalVitaminB1 += ns.vitaminB1;
      totalVitaminB2 += ns.vitaminB2;
      totalVitaminB3 += ns.vitaminB3;
      totalVitaminB6 += ns.vitaminB6;
      totalVitaminB12 += ns.vitaminB12;
      totalFolate += ns.folate;
      // Additional minerals
      totalMagnesium += ns.magnesium;
      totalZinc += ns.zinc;
      totalPhosphorus += ns.phosphorus;
      totalSelenium += ns.selenium;
      totalIodine += ns.iodine;
      // Fatty acids
      totalOmega3 += ns.omega3;

      // Count days with deficiencies (below 70% of daily value)
      if (ns.protein < rec.protein * 0.7) proteinDefDays++;
      if (ns.fiber < rec.fiber * 0.7) fiberDefDays++;
      if (ns.vitaminC < rec.vitaminC * 0.7) vitCDefDays++;
      if (ns.vitaminD < rec.vitaminD * 0.7) vitDDefDays++;
      if (ns.calcium < rec.calcium * 0.7) calciumDefDays++;
      if (ns.iron < rec.iron * 0.7) ironDefDays++;
      if (ns.potassium < rec.potassium * 0.7) potassiumDefDays++;
      // Additional vitamins
      if (ns.vitaminA < rec.vitaminA * 0.7) vitADefDays++;
      if (ns.vitaminE < rec.vitaminE * 0.7) vitEDefDays++;
      if (ns.vitaminK < rec.vitaminK * 0.7) vitKDefDays++;
      if (ns.vitaminB1 < rec.vitaminB1 * 0.7) vitB1DefDays++;
      if (ns.vitaminB2 < rec.vitaminB2 * 0.7) vitB2DefDays++;
      if (ns.vitaminB3 < rec.vitaminB3 * 0.7) vitB3DefDays++;
      if (ns.vitaminB6 < rec.vitaminB6 * 0.7) vitB6DefDays++;
      if (ns.vitaminB12 < rec.vitaminB12 * 0.7) vitB12DefDays++;
      if (ns.folate < rec.folate * 0.7) folateDefDays++;
      // Additional minerals
      if (ns.magnesium < rec.magnesium * 0.7) magnesiumDefDays++;
      if (ns.zinc < rec.zinc * 0.7) zincDefDays++;
      if (ns.phosphorus < rec.phosphorus * 0.7) phosphorusDefDays++;
      if (ns.selenium < rec.selenium * 0.7) seleniumDefDays++;
      if (ns.iodine < rec.iodine * 0.7) iodineDefDays++;
      // Fatty acids
      if (ns.omega3 < rec.omega3 * 0.7) omega3DefDays++;
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
      // Additional vitamins
      vitaminA: totalVitaminA / daysWithData,
      vitaminE: totalVitaminE / daysWithData,
      vitaminK: totalVitaminK / daysWithData,
      vitaminB1: totalVitaminB1 / daysWithData,
      vitaminB2: totalVitaminB2 / daysWithData,
      vitaminB3: totalVitaminB3 / daysWithData,
      vitaminB6: totalVitaminB6 / daysWithData,
      vitaminB12: totalVitaminB12 / daysWithData,
      folate: totalFolate / daysWithData,
      // Additional minerals
      magnesium: totalMagnesium / daysWithData,
      zinc: totalZinc / daysWithData,
      phosphorus: totalPhosphorus / daysWithData,
      selenium: totalSelenium / daysWithData,
      iodine: totalIodine / daysWithData,
      // Fatty acids
      omega3: totalOmega3 / daysWithData,
    );

    // Get today's intake (last log if it's today, otherwise empty)
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final todayLog = logs.where((l) => l.date == todayKey).firstOrNull;
    final todayIntake = todayLog?.nutritionSummary ?? const NutritionSummary();

    // Identify consistent deficiencies (deficient on 50%+ of days with data)
    final consistentDefs = <NutrientTrend>[];
    final threshold = daysWithData * 0.5;

    // Helper to add deficiency if threshold met
    void addIfDeficient(String name, double avg, double rec, String unit, int defDays) {
      if (defDays >= threshold) {
        consistentDefs.add(NutrientTrend(
          name: name,
          averageIntake: avg,
          recommended: rec,
          unit: unit,
          deficientDays: defDays,
          totalDays: daysWithData,
        ));
      }
    }

    // Check all nutrients
    addIfDeficient('Protein', avgIntake.protein, rec.protein, 'g', proteinDefDays);
    addIfDeficient('Fiber', avgIntake.fiber, rec.fiber, 'g', fiberDefDays);
    addIfDeficient('Vitamin C', avgIntake.vitaminC, rec.vitaminC, 'mg', vitCDefDays);
    addIfDeficient('Vitamin D', avgIntake.vitaminD, rec.vitaminD, 'mcg', vitDDefDays);
    addIfDeficient('Calcium', avgIntake.calcium, rec.calcium, 'mg', calciumDefDays);
    addIfDeficient('Iron', avgIntake.iron, rec.iron, 'mg', ironDefDays);
    addIfDeficient('Potassium', avgIntake.potassium, rec.potassium, 'mg', potassiumDefDays);
    // Additional vitamins
    addIfDeficient('Vitamin A', avgIntake.vitaminA, rec.vitaminA, 'mcg', vitADefDays);
    addIfDeficient('Vitamin E', avgIntake.vitaminE, rec.vitaminE, 'mg', vitEDefDays);
    addIfDeficient('Vitamin K', avgIntake.vitaminK, rec.vitaminK, 'mcg', vitKDefDays);
    addIfDeficient('Vitamin B1', avgIntake.vitaminB1, rec.vitaminB1, 'mg', vitB1DefDays);
    addIfDeficient('Vitamin B2', avgIntake.vitaminB2, rec.vitaminB2, 'mg', vitB2DefDays);
    addIfDeficient('Vitamin B3', avgIntake.vitaminB3, rec.vitaminB3, 'mg', vitB3DefDays);
    addIfDeficient('Vitamin B6', avgIntake.vitaminB6, rec.vitaminB6, 'mg', vitB6DefDays);
    addIfDeficient('Vitamin B12', avgIntake.vitaminB12, rec.vitaminB12, 'mcg', vitB12DefDays);
    addIfDeficient('Folate', avgIntake.folate, rec.folate, 'mcg', folateDefDays);
    // Additional minerals
    addIfDeficient('Magnesium', avgIntake.magnesium, rec.magnesium, 'mg', magnesiumDefDays);
    addIfDeficient('Zinc', avgIntake.zinc, rec.zinc, 'mg', zincDefDays);
    addIfDeficient('Phosphorus', avgIntake.phosphorus, rec.phosphorus, 'mg', phosphorusDefDays);
    addIfDeficient('Selenium', avgIntake.selenium, rec.selenium, 'mcg', seleniumDefDays);
    addIfDeficient('Iodine', avgIntake.iodine, rec.iodine, 'mcg', iodineDefDays);
    // Fatty acids
    addIfDeficient('Omega-3', avgIntake.omega3, rec.omega3, 'g', omega3DefDays);

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
    final rec = NutritionSummary.recommendedDaily;
    
    if (!hasEnoughData) {
      buffer.writeln('Limited data: Only $daysWithData day(s) of food tracking available.');
      if (todayIntake.calories > 0) {
        buffer.writeln('Today so far: ${todayIntake.calories.toStringAsFixed(0)} cal, ${todayIntake.protein.toStringAsFixed(0)}g protein');
      }
      return buffer.toString();
    }

    // Today's macro status is most important for immediate suggestions
    if (todayIntake.calories > 0) {
      buffer.writeln("TODAY'S MACRO STATUS (this is what matters most for suggestions):");
      
      // Calculate percentages
      final calPct = (todayIntake.calories / rec.calories * 100).round();
      final proteinPct = (todayIntake.protein / rec.protein * 100).round();
      final carbsPct = (todayIntake.carbs / rec.carbs * 100).round();
      final fatPct = (todayIntake.fat / rec.fat * 100).round();
      final fiberPct = (todayIntake.fiber / rec.fiber * 100).round();
      
      // Show what's exceeded vs what's still needed
      final exceeded = <String>[];
      final stillNeeded = <String>[];
      
      if (calPct >= 100) {
        exceeded.add('Calories ($calPct%)');
      } else {
        stillNeeded.add('Calories ($calPct% - need ${(rec.calories - todayIntake.calories).toStringAsFixed(0)} more)');
      }
      
      if (proteinPct >= 100) {
        exceeded.add('Protein ($proteinPct%)');
      } else {
        stillNeeded.add('Protein ($proteinPct% - need ${(rec.protein - todayIntake.protein).toStringAsFixed(0)}g more)');
      }
      
      if (carbsPct >= 100) {
        exceeded.add('Carbs ($carbsPct%)');
      } else {
        stillNeeded.add('Carbs ($carbsPct% - need ${(rec.carbs - todayIntake.carbs).toStringAsFixed(0)}g more)');
      }
      
      if (fatPct >= 100) {
        exceeded.add('Fat ($fatPct%)');
      } else {
        stillNeeded.add('Fat ($fatPct% - need ${(rec.fat - todayIntake.fat).toStringAsFixed(0)}g more)');
      }
      
      if (fiberPct >= 100) {
        exceeded.add('Fiber ($fiberPct%)');
      } else {
        stillNeeded.add('Fiber ($fiberPct% - need ${(rec.fiber - todayIntake.fiber).toStringAsFixed(0)}g more)');
      }
      
      if (exceeded.isNotEmpty) {
        buffer.writeln('ALREADY MET/EXCEEDED (avoid adding more): ${exceeded.join(", ")}');
      }
      if (stillNeeded.isNotEmpty) {
        buffer.writeln('STILL NEED MORE OF: ${stillNeeded.join(", ")}');
      }
      
      // Today's micronutrient deficiencies
      final microDeficiencies = <String>[];
      if (todayIntake.vitaminC < rec.vitaminC * 0.7) microDeficiencies.add('Vitamin C (${(todayIntake.vitaminC / rec.vitaminC * 100).round()}%)');
      if (todayIntake.vitaminD < rec.vitaminD * 0.7) microDeficiencies.add('Vitamin D (${(todayIntake.vitaminD / rec.vitaminD * 100).round()}%)');
      if (todayIntake.vitaminA < rec.vitaminA * 0.7) microDeficiencies.add('Vitamin A (${(todayIntake.vitaminA / rec.vitaminA * 100).round()}%)');
      if (todayIntake.vitaminE < rec.vitaminE * 0.7) microDeficiencies.add('Vitamin E (${(todayIntake.vitaminE / rec.vitaminE * 100).round()}%)');
      if (todayIntake.vitaminK < rec.vitaminK * 0.7) microDeficiencies.add('Vitamin K (${(todayIntake.vitaminK / rec.vitaminK * 100).round()}%)');
      if (todayIntake.calcium < rec.calcium * 0.7) microDeficiencies.add('Calcium (${(todayIntake.calcium / rec.calcium * 100).round()}%)');
      if (todayIntake.iron < rec.iron * 0.7) microDeficiencies.add('Iron (${(todayIntake.iron / rec.iron * 100).round()}%)');
      if (todayIntake.potassium < rec.potassium * 0.7) microDeficiencies.add('Potassium (${(todayIntake.potassium / rec.potassium * 100).round()}%)');
      if (todayIntake.magnesium < rec.magnesium * 0.7) microDeficiencies.add('Magnesium (${(todayIntake.magnesium / rec.magnesium * 100).round()}%)');
      if (todayIntake.folate < rec.folate * 0.7) microDeficiencies.add('Folate (${(todayIntake.folate / rec.folate * 100).round()}%)');
      
      if (microDeficiencies.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('LOW MICRONUTRIENTS TODAY: ${microDeficiencies.join(", ")}');
      }
      
      buffer.writeln('');
    } else {
      buffer.writeln('No food logged today yet.');
      buffer.writeln('');
    }

    // Weekly context (secondary)
    if (consistentDeficiencies.isNotEmpty) {
      buffer.writeln('Weekly patterns (nutrients consistently low):');
      for (final def in consistentDeficiencies.take(4)) {
        buffer.writeln('- ${def.name}: averaging ${def.averageIntake.toStringAsFixed(0)}${def.unit} vs ${def.recommended.toStringAsFixed(0)}${def.unit} goal');
      }
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

