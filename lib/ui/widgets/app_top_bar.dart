import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.toolbarHeight = 72,
    this.blurSigma = 6, // 0 = sin blur
    this.tintOpacity = 0.04, // 0 = sin tinte
    this.overlayStyle, // si no pasas, se elige según tema
  });

  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double toolbarHeight;
  final double blurSigma;
  final double tintOpacity;
  final SystemUiOverlayStyle? overlayStyle;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final defaultOverlay =
        Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark;

    return AppBar(
      toolbarHeight: toolbarHeight,
      centerTitle: centerTitle,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent, // ← clave
      surfaceTintColor: Colors.transparent, // ← clave
      systemOverlayStyle: overlayStyle ?? defaultOverlay,
      title: DefaultTextStyle.merge(
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        child: title,
      ),
      leading: leading,
      actions: actions,
      // capa opcional (blur + tinte MUY sutil) sobre el fondo real que está detrás
      flexibleSpace:
          (blurSigma > 0 || tintOpacity > 0)
              ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(tintOpacity),
                  ),
                ),
              )
              : null,
      // sin línea inferior
      bottom: null,
    );
  }
}
