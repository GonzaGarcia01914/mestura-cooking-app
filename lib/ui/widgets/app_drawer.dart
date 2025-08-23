import 'dart:ui';
import 'package:flutter/material.dart';

class AppSideDrawer extends StatelessWidget {
  const AppSideDrawer({
    super.key,
    required this.header,
    required this.items,
    this.footer,
  });

  final Widget header;
  final List<Widget> items;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Drawer(
      elevation: 0,
      backgroundColor: cs.surface.withOpacity(0.92),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          children: [
            header,
            const SizedBox(height: 12),
            Divider(color: cs.outlineVariant.withOpacity(0.35), height: 24),
            ...items,
            if (footer != null) ...[
              const SizedBox(height: 12),
              Divider(color: cs.outlineVariant.withOpacity(0.2), height: 24),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
