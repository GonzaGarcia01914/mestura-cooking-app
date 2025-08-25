import 'dart:ui';

import 'package:flutter/material.dart';

class GlassAlert extends StatelessWidget {
  const GlassAlert({
    super.key,
    required this.title,
    required this.message,
    required this.okLabel,
    required this.onOk,
    this.icon,
    this.iconColor,
    this.accentColor,
  });

  final String title;
  final String message;
  final String okLabel;
  final VoidCallback onOk;
  final IconData? icon;
  final Color? accentColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final Color accent = accentColor ?? cs.error;
    final IconData leadingIcon = icon ?? Icons.error_outline;
    final Color leadingIconColor = iconColor ?? cs.error;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.86,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.70),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                blurRadius: 32,
                spreadRadius: -8,
                color: Colors.black.withOpacity(0.28),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono dentro de círculo sutil
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(leadingIcon, size: 30, color: leadingIconColor),
              ),
              const SizedBox(height: 12),

              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onOk,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(okLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
