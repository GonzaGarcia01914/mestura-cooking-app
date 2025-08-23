import 'package:flutter/material.dart';

/// Fondo animado con gradiente y blobs suaves.
class AppBackground extends StatefulWidget {
  const AppBackground({super.key});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bg;

  @override
  void initState() {
    super.initState();
    _bg = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _bg,
          builder: (_, __) {
            final t = _bg.value;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1 + 2 * t, -1),
                  end: Alignment(1 - 2 * t, 1),
                  colors: [
                    cs.primary.withOpacity(0.12),
                    cs.surface,
                    cs.primary.withOpacity(0.08),
                  ],
                ),
              ),
            );
          },
        ),
        IgnorePointer(
          child: CustomPaint(
            painter: _BlobPainter(
              Theme.of(context).colorScheme.primary.withOpacity(0.06),
            ),
            size: Size.infinite,
          ),
        ),
      ],
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    void blob(Offset c, double rx, double ry, double rot) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rot);
      final rect = Rect.fromCenter(center: Offset.zero, width: rx, height: ry);
      canvas.drawOval(rect, paint);
      canvas.restore();
    }

    blob(Offset(size.width * 0.2, size.height * 0.25), 220, 160, 0.3);
    blob(Offset(size.width * 0.8, size.height * 0.2), 180, 140, -0.4);
    blob(Offset(size.width * 0.5, size.height * 0.85), 260, 190, 0.1);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) =>
      oldDelegate.color != color;
}
