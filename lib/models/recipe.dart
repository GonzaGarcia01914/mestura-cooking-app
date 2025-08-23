class RecipeModel {
  final String title;
  final List<String> ingredients;
  final List<String> steps;
  String image;

  RecipeModel({
    required this.title,
    required this.ingredients,
    required this.steps,
    required this.image,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      title: json['title'] ?? 'Untitled',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      steps: List<String>.from(json['steps'] ?? []),
      image: json['image'],
    );
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
