import 'dart:ui';
import 'package:flutter/material.dart';
import '../style/app_style.dart';

class FrostedContainer extends StatelessWidget {
  const FrostedContainer({
    super.key,
    this.child,
    this.padding,
    this.borderRadius,
  });

  final Widget? child;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = AppStyle.of(context);
    final br = borderRadius ?? BorderRadius.circular(style.radius);

    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: style.blurSigma,
          sigmaY: style.blurSigma,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.60),
            borderRadius: br,
            border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                blurRadius: 24,
                spreadRadius: -6,
                color: Colors.black.withOpacity(0.08),
              ),
            ],
          ),
          padding: padding ?? style.padding,
          child: child,
        ),
      ),
    );
  }
}
