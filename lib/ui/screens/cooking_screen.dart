import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/recipe.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/share_recipe_service.dart';
import '../../core/services/storage_service.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/frosted_container.dart';
import '../widgets/app_primary_button.dart';

class CookingScreen extends StatefulWidget {
  const CookingScreen({super.key, required this.recipe});

  final RecipeModel recipe;

  @override
  State<CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends State<CookingScreen> with WidgetsBindingObserver {
  late final List<String> steps;
  int index = 0;
  late final PageController _pageCtrl;
  late final List<Duration?> _stepTimes;

  // Timer state
  Duration? detected;
  Duration remaining = Duration.zero;
  bool running = false;
  bool hasStarted = false;
  Timer? ticker;
  DateTime? startedAt;
  int? scheduledId;
  bool _inForeground = true;
  int _lastDirection = 0; // -1 izquierda, +1 derecha

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    steps = widget.recipe.steps;
    _pageCtrl = PageController(viewportFraction: 0.9, initialPage: index);
    _stepTimes = steps.map(_extractDuration).toList(growable: false);
    _detectForCurrentStep();
  }

  @override
  void dispose() {
    ticker?.cancel();
    if (scheduledId != null) {
      NotificationService.cancel(scheduledId!);
    }
    _pageCtrl.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _inForeground = true;
      NotificationService.cancelOngoingCountdown();
    } else if (state == AppLifecycleState.paused) {
      _inForeground = false;
      _updateBackgroundOngoingNotification();
    }
  }

  void _detectForCurrentStep() {
    detected = _stepTimes[index];
    if (detected != null) {
      remaining = detected!;
    } else {
      remaining = Duration.zero;
    }
    _stopTimer(clearNotif: true);
    hasStarted = false;
    setState(() {});
  }

  static Duration? _extractDuration(String text) {
    final lower = text.toLowerCase();
    int totalSeconds = 0;

    // Patrones multi-idioma para horas/minutos/segundos
    final List<MapEntry<RegExp, int Function(Match)>> regexPairs = [
      // Horas
      MapEntry(
        RegExp(r"(\d+)\s*(h|hr|hrs|hour|hours|hora|horas|stunde|stunden|std\.?|heure|heures|час|часа|часов|ч|godzina|godziny|godz\.?|g|시간|時間|小时|小時|时|時)"),
        (m) => int.parse(m.group(1)!) * 3600,
      ),
      // Minutos
      MapEntry(
        RegExp(r"(\d+)\s*(m|min|mins|min\.?|minute|minutes|minuto|minutos|minuten|minuty|minuta|мин|минут(?:а|ы)?|分钟|分鐘|分|분)"),
        (m) => int.parse(m.group(1)!) * 60,
      ),
      // Segundos
      MapEntry(
        RegExp(r"(\d+)\s*(s|sec|secs|second|seconds|seg|segundo|segundos|sek|sekunde|sekunden|sek\.?|seconde|secondes|sekundy|sekund|сек|секунд(?:а|ы)?|秒|초)"),
        (m) => int.parse(m.group(1)!),
      ),
    ];

    for (final entry in regexPairs) {
      for (final m in entry.key.allMatches(lower)) {
        totalSeconds += entry.value(m);
      }
    }

    if (totalSeconds <= 0) return null;
    return Duration(seconds: totalSeconds);
  }

  void _startTimer() async {
    if (detected == null) return;
    ticker?.cancel();
    running = true;
    hasStarted = true;
    startedAt = DateTime.now();
    ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        remaining -= const Duration(seconds: 1);
        if (remaining.inSeconds <= 0) {
          remaining = Duration.zero;
          running = false;
          t.cancel();
        }
      });
    });
    // Programa notificación al final
    final target = DateTime.now().add(remaining);
    final s = AppLocalizations.of(context)!;
    scheduledId = await NotificationService.scheduleAlarm(
      when: target,
      title: s.timerDoneTitle,
      body: s.timerDoneBody,
    );
    setState(() {});
    _updateBackgroundOngoingNotification();
  }

  void _pauseTimer() async {
    if (!running) return;
    ticker?.cancel();
    running = false;
    if (scheduledId != null) {
      await NotificationService.cancel(scheduledId!);
      scheduledId = null;
    }
    setState(() {});
    NotificationService.cancelOngoingCountdown();
  }

  void _resumeTimer() {
    if (detected == null || running || remaining.inSeconds <= 0) return;
    _startTimer();
  }

  void _stopTimer({bool clearNotif = false}) async {
    ticker?.cancel();
    running = false;
    hasStarted = false;
    if (clearNotif && scheduledId != null) {
      await NotificationService.cancel(scheduledId!);
      scheduledId = null;
    }
    NotificationService.cancelOngoingCountdown();
  }

  void _updateBackgroundOngoingNotification() {
    if (!_inForeground && hasStarted && remaining.inSeconds > 0) {
      final ends = DateTime.now().add(remaining);
      final s = AppLocalizations.of(context)!;
      NotificationService.showOngoingCountdown(
        endsAt: ends,
        title: s.cookingNotificationTitle(widget.recipe.title),
        body: s.cookingOngoingBody('${index + 1}'),
      );
    }
  }

  void _prev() {
    if (index == 0) return;
    _stopTimer(clearNotif: true);
    _pageCtrl.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _next() {
    if (index >= steps.length - 1) return;
    _stopTimer(clearNotif: true);
    _pageCtrl.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Future<void> _shareFinish() async {
    if (!mounted) return;
    final s = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s.cookingSheetTitle, style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 12),
                AppPrimaryButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _takeAndSharePhoto();
                  },
                  child: Text(s.cookingSheetTakePhotoShare),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _shareTextOnly();
                  },
                  child: Text(s.cookingSheetShareNoPhoto),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _saveRecipeFromCooking();
                  },
                  child: Text(s.cookingSheetSaveRecipe),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text(s.cookingSheetGoHome),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _takeAndSharePhoto() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (photo == null) return;
      final s = AppLocalizations.of(context)!;
      // Genera un Dynamic Link que contiene la receta compartida
      final shareUri = await ShareRecipeService.createShareLink(widget.recipe);
      final text = s.shareCookedText(widget.recipe.title, shareUri.toString());
      await Share.shareXFiles([XFile(photo.path)], text: text, subject: s.shareButton);
    } catch (_) {}
  }

  Future<void> _shareTextOnly() async {
    try {
      final s = AppLocalizations.of(context)!;
      final shareUri = await ShareRecipeService.createShareLink(widget.recipe);
      final text = s.shareCookedText(widget.recipe.title, shareUri.toString());
      await Share.share(text, subject: s.shareButton);
    } catch (_) {}
  }

  Future<void> _saveRecipeFromCooking() async {
    final storage = StorageService();
    await storage.saveRecipe(widget.recipe);
    if (!mounted) return;
    final s = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.savedConfirmation)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final step = steps[index];

    final size = MediaQuery.of(context).size;
    return AppScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppTopBar(
        title: Text(AppLocalizations.of(context)!.cookingNotificationTitle(widget.recipe.title)),
        blurSigma: 0,
        tintOpacity: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  '${index + 1}/${steps.length}',
                  textAlign: TextAlign.center,
                  style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 12),
              // Centro: tarjetas con efecto tipo stack + swipe
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // PageView con efecto de escala para look de cartas
                      SizedBox(
                        height: size.height * 0.56,
                        child: PageView.builder(
                          controller: _pageCtrl,
                          itemCount: steps.length,
                          onPageChanged: (i) {
                            _stopTimer(clearNotif: true);
                            setState(() {
                              _lastDirection = (i > index) ? 1 : -1;
                              index = i;
                            });
                            _detectForCurrentStep();
                            _updateBackgroundOngoingNotification();
                          },
                          itemBuilder: (context, i) {
                            return AnimatedBuilder(
                              animation: _pageCtrl,
                              builder: (context, child) {
                                double scale = 1.0;
                                double angle = 0.0;
                                if (_pageCtrl.position.hasContentDimensions) {
                                  final page = _pageCtrl.page ?? _pageCtrl.initialPage.toDouble();
                                  final dist = (page - i).abs();
                                  scale = 1.0 - (dist.clamp(0.0, 1.0)) * 0.06; // 0.94 para vecinos
                                  angle = (page - i) * 0.04; // ~2.3º de tilt
                                }
                                return Transform.scale(
                                  scale: scale,
                                  child: Transform.rotate(
                                    angle: angle,
                                    child: child,
                                  ),
                                );
                              },
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 640),
                                  child: FrostedContainer(
                                    borderRadius: const BorderRadius.all(Radius.circular(18)),
                                    padding: const EdgeInsets.all(18),
                                    child: SingleChildScrollView(
                                      child: Text(
                                        steps[i],
                                        style: t.textTheme.titleLarge?.copyWith(height: 1.35),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    ],
                  ),
                ),
              ),

              // Flechas debajo de las tarjetas, en los extremos y grandes
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(minimumSize: const Size(64, 64), padding: const EdgeInsets.all(12)),
                      iconSize: 34,
                      onPressed: index == 0 ? null : _prev,
                      icon: const Icon(Icons.arrow_back_ios_new),
                      tooltip: 'Anterior',
                    ),
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(minimumSize: const Size(64, 64), padding: const EdgeInsets.all(12)),
                      iconSize: 34,
                      onPressed: index >= steps.length - 1 ? null : _next,
                      icon: const Icon(Icons.arrow_forward_ios),
                      tooltip: 'Siguiente',
                    ),
                  ],
                ),
              ),

              // Controles de temporizador con animación de entrada/salida similar
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) {
                  final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
                  final begin = Offset(_lastDirection >= 0 ? 0.15 : -0.15, 0);
                  return FadeTransition(
                    opacity: curved,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
                      child: child,
                    ),
                  );
                },
                child: (detected != null)
                    ? Padding(
                        key: ValueKey('timer-$index'),
                        padding: const EdgeInsets.only(top: 8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: _TimerControls(
                            remaining: remaining,
                            running: running,
                            hasStarted: hasStarted,
                            onStart: _startTimer,
                            onPause: _pauseTimer,
                            onResume: _resumeTimer,
                            onDiscard: () {
                              _stopTimer(clearNotif: true);
                              setState(() {
                                detected = null;
                                remaining = Duration.zero;
                              });
                            },
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // Al finalizar no hay botón fijo; mostramos hoja de opciones
              if (index >= steps.length - 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: AppPrimaryButton(
                    onPressed: _shareFinish,
                    child: Text(AppLocalizations.of(context)!.finalizeButton),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerControls extends StatelessWidget {
  const _TimerControls({
    required this.remaining,
    required this.running,
    required this.hasStarted,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onDiscard,
  });

  final Duration remaining;
  final bool running;
  final bool hasStarted;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return FrostedContainer(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (!running && remaining.inSeconds > 0 && !hasStarted)
                IconButton.filled(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow),
                  tooltip: AppLocalizations.of(context)!.timerStartTooltip,
                ),
              if (running)
                IconButton.filled(
                  onPressed: onPause,
                  icon: const Icon(Icons.pause),
                  tooltip: AppLocalizations.of(context)!.timerPauseTooltip,
                ),
              if (!running && remaining.inSeconds > 0 && hasStarted)
                IconButton.filled(
                  onPressed: onResume,
                  icon: const Icon(Icons.play_arrow),
                  tooltip: AppLocalizations.of(context)!.timerResumeTooltip,
                ),
              Expanded(
                child: Center(
                  child: Text(
                    _fmt(remaining),
                    style: t.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              IconButton.outlined(
                onPressed: onDiscard,
                icon: const Icon(Icons.close),
                tooltip: AppLocalizations.of(context)!.timerDiscardTooltip,
              ),
            ],
          )
        ],
      ),
    );
  }
}
