import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/services/ad_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Marca este teléfono como test device para AdMob
  await MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(
      testDeviceIds: const ['462F30F4A2A3772D5AD31DF0C6EC32B6'],
    ),
  );

  // Inicializa el SDK
  await MobileAds.instance.initialize();

  // Preferencias y arranque sin bloquear por anuncios/UMP
  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('locale');
  runApp(MyApp(savedLocale: savedLocale));

  // Precarga de anuncios en background (no bloquear la UI)
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(AdService.instance.preload());
  });
}

class MyApp extends StatefulWidget {
  final String? savedLocale;
  const MyApp({super.key, this.savedLocale});

  @override
  State<MyApp> createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    final _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.changeLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = _getInitialLocale();
  }

  Locale _getInitialLocale() {
    if (widget.savedLocale != null) return Locale(widget.savedLocale!);
    final systemLocale =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return (systemLocale == 'es') ? const Locale('es') : const Locale('en');
  }

  Future<void> changeLocale(Locale newLocale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', newLocale.languageCode);
    setState(() => _locale = newLocale);
  }

  @override
  Widget build(BuildContext context) => App(locale: _locale);
}
