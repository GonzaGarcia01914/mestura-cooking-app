import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../l10n/app_localizations.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  // Icon animations
  late final AnimationController _iconController;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconRotation;

  // Background gradient drift
  late final AnimationController _bgController;

  // Indeterminate ring
  late final AnimationController _ringController;

  // Typewriter text (anulable para no fallar si no llegó a crearse)
  Ticker? _textTicker;
  String _fullText = '';
  String _displayedText = '';
  int _charIndex = 0;

  // Tips carousel
  Timer? _tipsTimer;
  int _tipIndex = 0;
  List<String> _tips = const [];

  @override
  void initState() {
    super.initState();

    // Icon: gentle pump + rotation
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _iconScale = Tween(begin: 0.96, end: 1.06).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );
    _iconRotation = Tween(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0, 1, curve: Curves.linear),
      ),
    );

    // Background drift
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    // Indeterminate ring
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Init text & tips after context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l10n = AppLocalizations.of(context);

      setState(() {
        _fullText = l10n?.loadingMessage ?? 'Cocinando la receta...';
        _tips = [
          l10n?.loadingTip1 ??
              'Consejo: prueba con especias ahumadas para más sabor.',
          l10n?.loadingTip2 ??
              'Consejo: tuesta las especias 30s para despertar aromas.',
          l10n?.loadingTip3 ??
              'Consejo: guarda el agua de cocción para ajustar textura.',
          l10n?.loadingTip4 ??
              'Consejo: ácido al final (limón/vinagre) realza todo.',
          l10n?.loadingTip5 ?? 'Consejo: sal en capas, no toda al final.',
        ];
        if (_tips.isNotEmpty) {
          _tipIndex = DateTime.now().millisecond % _tips.length;
        }
      });

      // Typewriter ticker
      _textTicker = createTicker((_) {
        if (_charIndex < _fullText.length) {
          setState(() {
            _displayedText += _fullText[_charIndex];
            _charIndex++;
          });
        } else {
          _textTicker?.stop();
        }
      })..start();

      // Tips carousel cada 2.5s
      _tipsTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
        if (!mounted || _tips.isEmpty) return;
        setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
      });
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _bgController.dispose();
    _ringController.dispose();
    _textTicker?.dispose();
    _tipsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final surface = theme.colorScheme.surface;

    final tipText = _tips.isEmpty ? '' : _tips[_tipIndex % _tips.length];

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            // Animated gradient background
            AnimatedBuilder(
              animation: _bgController,
              builder: (context, _) {
                final t = _bgController.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1 + 2 * t, -1),
                      end: Alignment(1 - 2 * t, 1),
                      colors: [
                        color.withValues(alpha: 0.12),
                        surface,
                        color.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Soft floating blobs (subtle)
            IgnorePointer(
              child: CustomPaint(
                painter: _BlobPainter(color.withValues(alpha: 0.06)),
                size: Size.infinite,
              ),
            ),

            // Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cooking ring + icon
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _ringController,
                          builder: (context, _) {
                            return CustomPaint(
                              size: const Size.square(140),
                              painter: _IndeterminateRingPainter(
                                progress: _ringController.value,
                                color: color,
                                trackColor: color.withValues(alpha: 0.15),
                              ),
                            );
                          },
                        ),
                        AnimatedBuilder(
                          animation: Listenable.merge([_iconController]),
                          builder: (context, _) {
                            return Transform.rotate(
                              angle: _iconRotation.value / 12, // muy sutil
                              child: Transform.scale(
                                scale: _iconScale.value,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 24,
                                        spreadRadius: 1,
                                        color: color.withValues(alpha: 0.25),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Icon(
                                      Icons.local_dining,
                                      size: 48,
                                      color: onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Typewriter loading message
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _displayedText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Pulsing dots under the message
                  const _PulsingDots(),

                  const SizedBox(height: 20),

                  // Stage chips
                  _StageChips(primary: color),

                  const SizedBox(height: 20),

                  // Rotating cooking tips
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder:
                        (child, anim) => SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.25),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOut,
                            ),
                          ),
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                    child: Padding(
                      key: ValueKey(_tipIndex),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        tipText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.75,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter para un anillo indeterminado con SweepGradient “horno”
class _IndeterminateRingPainter extends CustomPainter {
  _IndeterminateRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 8.0;
    final rect =
        Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);

    // Pista
    final trackPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = trackColor
          ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    // Segmento animado
    final sweep =
        (0.6 + 0.4 * math.sin(progress * 2 * math.pi)) * math.pi / 1.5;
    final start = (progress * 2 * math.pi);

    final segPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: start,
            endAngle: start + sweep,
            colors: [
              color.withValues(alpha: 0.0),
              color.withValues(alpha: 0.25),
              color.withValues(alpha: 0.9),
            ],
            stops: const [0.0, 0.25, 1.0],
            transform: GradientRotation(start),
          ).createShader(rect);
    canvas.drawArc(rect, start, sweep, false, segPaint);
  }

  @override
  bool shouldRepaint(covariant _IndeterminateRingPainter old) {
    return old.progress != progress ||
        old.color != color ||
        old.trackColor != trackColor;
  }
}

class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with TickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _a = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.titleLarge;
    return AnimatedBuilder(
      animation: _a,
      builder: (context, _) {
        double f(int i) =>
            (math.sin((_a.value * 2 * math.pi) + i * 0.7) + 1) / 2;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final scale = 0.8 + 0.25 * f(i);
            final dy = (1 - f(i)) * 2.0;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(
                scale: scale,
                child: Text('•', style: baseStyle?.copyWith(letterSpacing: 2)),
              ),
            );
          }),
        );
      },
    );
  }
}

class _StageChips extends StatefulWidget {
  const _StageChips({required this.primary});
  final Color primary;

  @override
  State<_StageChips> createState() => _StageChipsState();
}

class _StageChipsState extends State<_StageChips> {
  static const _stages = [
    'Preparando',
    'Mezclando',
    'Sazonando',
    'Cocinando',
    'Emplatando',
  ];
  int _active = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (mounted) {
        setState(() => _active = (_active + 1) % _stages.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < _stages.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color:
                  i == _active
                      ? widget.primary.withValues(alpha: 0.18)
                      : theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.6,
                      ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color:
                    i == _active
                        ? widget.primary.withValues(alpha: 0.35)
                        : theme.dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: i == _active ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    i == _active ? Icons.check_circle : Icons.hourglass_bottom,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Text(_stages[i], style: theme.textTheme.labelMedium),
              ],
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
