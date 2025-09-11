class FoodPreferences {
  final List<String> diet;
  final List<String> religion;
  final List<String> medical;
  final List<String> allergensAvoid;
  final List<String> intolerances;
  final List<String> dislikedIngredients;

  const FoodPreferences({
    this.diet = const [],
    this.religion = const [],
    this.medical = const [],
    this.allergensAvoid = const [],
    this.intolerances = const [],
    this.dislikedIngredients = const [],
  });

  FoodPreferences copyWith({
    List<String>? diet,
    List<String>? religion,
    List<String>? medical,
    List<String>? allergensAvoid,
    List<String>? intolerances,
    List<String>? dislikedIngredients,
  }) => FoodPreferences(
    diet: diet ?? this.diet,
    religion: religion ?? this.religion,
    medical: medical ?? this.medical,
    allergensAvoid: allergensAvoid ?? this.allergensAvoid,
    intolerances: intolerances ?? this.intolerances,
    dislikedIngredients: dislikedIngredients ?? this.dislikedIngredients,
  );

  Map<String, dynamic> toJson() => {
    'diet': diet,
    'religion': religion,
    'medical': medical,
    'allergens_avoid': allergensAvoid,
    'intolerances': intolerances,
    'disliked_ingredients': dislikedIngredients,
  };

  factory FoodPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FoodPreferences();
    List<String> ls(dynamic v) =>
        (v is List)
            ? v.where((e) => e != null).map((e) => e.toString()).toList()
            : const <String>[];
    return FoodPreferences(
      diet: ls(json['diet']),
      religion: ls(json['religion']),
      medical: ls(json['medical']),
      allergensAvoid: ls(json['allergens_avoid']),
      intolerances: ls(json['intolerances']),
      dislikedIngredients: ls(json['disliked_ingredients']),
    );
  }
}
