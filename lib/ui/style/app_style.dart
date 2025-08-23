import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;

@immutable
class AppStyle extends ThemeExtension<AppStyle> {
  const AppStyle({
    required this.radius,
    required this.padding,
    required this.elevation,
    required this.animMs,
    required this.blurSigma,
  });

  final double radius;
  final EdgeInsets padding;
  final double elevation;
  final int animMs;
  final double blurSigma;

  static const AppStyle fallback = AppStyle(
    radius: 12,
    padding: EdgeInsets.all(16),
    elevation: 2,
    animMs: 300,
    blurSigma: 10,
  );

  @override
  AppStyle copyWith({
    double? radius,
    EdgeInsets? padding,
    double? elevation,
    int? animMs,
    double? blurSigma,
  }) {
    return AppStyle(
      radius: radius ?? this.radius,
      padding: padding ?? this.padding,
      elevation: elevation ?? this.elevation,
      animMs: animMs ?? this.animMs,
      blurSigma: blurSigma ?? this.blurSigma,
    );
  }

  @override
  AppStyle lerp(ThemeExtension<AppStyle>? other, double t) {
    if (other is! AppStyle) return this;
    return AppStyle(
      radius: lerpDouble(radius, other.radius, t)!,
      padding: EdgeInsets.lerp(padding, other.padding, t)!,
      elevation: lerpDouble(elevation, other.elevation, t)!,
      animMs: (animMs + (other.animMs - animMs) * t).round(),
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
    );
  }

  static AppStyle of(BuildContext context) =>
      Theme.of(context).extension<AppStyle>() ?? AppStyle.fallback;
}
