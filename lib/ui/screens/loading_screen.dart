import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../l10n/app_localizations.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconAnimation;

  late String _fullText;
  String _displayedText = '';
  int _charIndex = 0;
  late Ticker _textTicker;

  @override
  void initState() {
    super.initState();

    // Animación para el icono
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _iconAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(_iconController);

    // Texto de carga localizado
    _fullText =
        AppLocalizations.of(context)?.loadingMessage ??
        'Cocinando la receta...';

    // Ticker para escribir letra por letra
    _textTicker = createTicker((_) {
      if (_charIndex < _fullText.length) {
        setState(() {
          _displayedText += _fullText[_charIndex];
          _charIndex++;
        });
      } else {
        _textTicker.stop();
      }
    })..start();
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _iconAnimation,
              child: Icon(
                Icons.local_dining,
                size: 60,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _displayedText,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
