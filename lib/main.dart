import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/services/ad_service.dart';
import 'app.dart';

Future<void> _initFirebase() async {
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Firebase.initializeApp();

  final o = Firebase.app().options;
  debugPrint('[FB] project=${o.projectId} appId=${o.appId} apiKey=${o.apiKey}');

  // App Check: Debug en desarrollo, automático en release.
  await FirebaseAppCheck.instance.activate(
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
  );

  await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

  try {
    final t = await FirebaseAppCheck.instance.getToken(true); // fuerza refresh
    debugPrint('[AppCheck] token length=${t?.length ?? 0}');
  } catch (e) {
    debugPrint('[AppCheck] getToken error: $e');
  }

  // Auth anónimo si no hay usuario. No detenemos la app si falla.
  try {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  } catch (e) {
    debugPrint('Anon sign-in failed: $e');
  }
}

Future<void> _initAds() async {
  // ⚠️ Cambia/añade tus device IDs de test si necesitas
  await MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(
      testDeviceIds: const ['462F30F4A2A3772D5AD31DF0C6EC32B6'],
    ),
  );
  await MobileAds.instance.initialize();
  // Precarga en segundo plano (no bloquear UI)
  // ignore: discarded_futures
  unawaited(AdService.instance.preload());
}

Future<String?> _loadSavedLocale() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('locale');
}

void main() {
  // Captura errores fuera del framework
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // (Opcional) Captura errores de Flutter
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.dumpErrorToConsole(details);
      };

      await _initFirebase();
      await _initAds();

      final savedLocale = await _loadSavedLocale();
      runApp(MyApp(savedLocale: savedLocale));
    },
    (error, stack) {
      debugPrint('Uncaught zone error: $error');
    },
  );
}

class MyApp extends StatefulWidget {
  final String? savedLocale;
  const MyApp({super.key, this.savedLocale});

  @override
  State<MyApp> createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    final state = context.findAncestorStateOfType<_MyAppState>();
    state?.changeLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = _initialLocale();
  }

  Locale _initialLocale() {
    if (widget.savedLocale != null) {
      return Locale(widget.savedLocale!);
    }
    final sys = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return (sys == 'es') ? const Locale('es') : const Locale('en');
  }

  Future<void> changeLocale(Locale newLocale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', newLocale.languageCode);
    if (mounted) setState(() => _locale = newLocale);
  }

  @override
  Widget build(BuildContext context) {
    // Tu widget raíz
    return App(locale: _locale);
  }
}
