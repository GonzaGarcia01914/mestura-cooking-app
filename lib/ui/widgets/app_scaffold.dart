import 'package:flutter/material.dart';
import 'app_background.dart';

/// Scaffold base que ya incluye el fondo animado.
/// Usa [body] como contenido principal y [appBar]/[drawer] si lo necesitas.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    this.drawer,
    required this.body,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset = false,
  });

  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget body;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: appBar,
      drawer: drawer,
      body: Stack(children: [const AppBackground(), body]),
    );
  }
}
