// recipe.dart

class RecipeModel {
  final String title;
  final List<String> ingredients;
  final List<String> steps;
  String? image;
  final NutritionInfo? nutrition;

  RecipeModel({
    required this.title,
    required this.ingredients,
    required this.steps,
    this.image,
    this.nutrition,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      title: (json['title'] ?? 'Untitled').toString(),
      ingredients: _stringList(json['ingredients']),
      steps: _stringList(json['steps']),
      image: json['image']?.toString(),
      nutrition:
          (json['nutrition'] is Map)
              ? NutritionInfo.fromJson(
                Map<String, dynamic>.from(json['nutrition'] as Map),
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'ingredients': ingredients,
      'steps': steps,
      'image': image,
      if (nutrition != null) 'nutrition': nutrition!.toJson(),
    };
  }

  // Helpers
  static List<String> _stringList(dynamic v) {
    if (v is List) {
      return v
          .where((e) => e != null)
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }
}

class NutritionInfo {
  final int? caloriesKcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;

  const NutritionInfo({
    this.caloriesKcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
  });

  /// Acepta tanto camelCase (preferido) como snake_case.
  factory NutritionInfo.fromJson(Map<String, dynamic> m) => NutritionInfo(
    caloriesKcal: _toInt(m['caloriesKcal'] ?? m['calories_kcal']),
    proteinG: _toDouble(m['proteinG'] ?? m['protein_g']),
    carbsG: _toDouble(m['carbsG'] ?? m['carbs_g']),
    fatG: _toDouble(m['fatG'] ?? m['fat_g']),
    fiberG: _toDouble(m['fiberG'] ?? m['fiber_g']),
    sugarG: _toDouble(m['sugarG'] ?? m['sugar_g']),
    sodiumMg: _toDouble(m['sodiumMg'] ?? m['sodium_mg']),
  );

  Map<String, dynamic> toJson() => {
    if (caloriesKcal != null) 'caloriesKcal': caloriesKcal,
    if (proteinG != null) 'proteinG': proteinG,
    if (carbsG != null) 'carbsG': carbsG,
    if (fatG != null) 'fatG': fatG,
    if (fiberG != null) 'fiberG': fiberG,
    if (sugarG != null) 'sugarG': sugarG,
    if (sodiumMg != null) 'sodiumMg': sodiumMg,
  };

  // Helpers numéricos robustos
  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
    // Si necesitas redondear strings con decimales, usa:
    // final d = double.tryParse(v.toString()); return d?.round();
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
