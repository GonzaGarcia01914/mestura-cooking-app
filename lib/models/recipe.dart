class RecipeModel {
  final String title;
  final List<String> ingredients;
  final List<String> steps;
  String? image;

  RecipeModel({
    required this.title,
    required this.ingredients,
    required this.steps,
    this.image,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      title: (json['title'] ?? 'Untitled').toString(),
      ingredients: List<String>.from(
        (json['ingredients'] ?? const <String>[]) as List,
      ),
      steps: List<String>.from((json['steps'] ?? const <String>[]) as List),
      image: json['image']?.toString(),
    );
    // La validación de campos obligatorios se hace en OpenAIService para no romper compatibilidad aquí.
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'ingredients': ingredients,
      'steps': steps,
      'image': image,
    };
  }
}
