import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/services/ad_service.dart';
import 'app.dart';
import 'core/providers.dart';
import 'core/services/notification_service.dart';
import 'core/services/deeplink_service.dart';

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

Future<void> main() async {
  // Asegura binding y configura manejadores de error
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  // Inicializaciones previas a runApp (en paralelo para reducir el tiempo de arranque)
  await Future.wait([
    _initFirebase(),
    _initAds(),
    NotificationService.init(),
  ]);

  final savedLocale = await _loadSavedLocale();
  final initialLocale = _initialLocale(savedLocale);

  // Ejecuta la app dentro de una zona protegida
  runZonedGuarded(
    () {
      runApp(
        ProviderScope(
          overrides: [
            // En Riverpod 2, StateProvider.overrideWith espera devolver el estado (Locale)
            localeProvider.overrideWith((ref) => initialLocale),
          ],
          child: const MyApp(),
        ),
      );
      // Inicializa escucha de Dynamic Links
      // No depende de Provider; usa navigatorKey global
      // ignore: discarded_futures
      DeepLinkService.init();
    },
    (error, stack) {
      debugPrint('Uncaught zone error: $error');
    },
  );
}

Locale _initialLocale(String? saved) {
  if (saved != null) {
    return Locale(saved);
  }
  final sys = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  const supported = [
    'en',
    'es',
    'ru',
    'de',
    'pl',
    'pt',
    'fr',
    'ja',
    'zh',
    'ko',
    'it',
    'gn',
  ];
  return supported.contains(sys) ? Locale(sys) : const Locale('en');
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const App();
  }
}
