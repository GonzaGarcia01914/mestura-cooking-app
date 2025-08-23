import 'package:flutter/material.dart';

class AppTitle extends StatelessWidget {
  const AppTitle(this.text, {super.key, this.align = TextAlign.center});

  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.bold,
      height: 1.2,
    );
    return Text(text, textAlign: align, style: t);
  }
}
