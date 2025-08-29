class ShoppingItem {
  final String text;
  final bool done;

  const ShoppingItem({required this.text, this.done = false});

  ShoppingItem copyWith({String? text, bool? done}) =>
      ShoppingItem(text: text ?? this.text, done: done ?? this.done);

  factory ShoppingItem.fromJson(Map<String, dynamic> json) =>
      ShoppingItem(text: json['text'] as String? ?? '', done: json['done'] as bool? ?? false);

  Map<String, dynamic> toJson() => {
        'text': text,
        'done': done,
      };
}

