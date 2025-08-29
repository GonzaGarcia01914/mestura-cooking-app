import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mestura/core/services/ad_service.dart';
import 'package:mestura/app.dart';
import 'package:mestura/core/providers.dart';
import 'package:mestura/core/services/notification_service.dart';
import 'package:mestura/core/services/deeplink_service.dart';

Future<void> _initFirebase() async {
  // Web path: configurable via --dart-define to avoid blank page when not configured
  if (kIsWeb) {
    const enableWeb = bool.fromEnvironment(
      'ENABLE_FIREBASE_WEB',
      defaultValue: false,
    );
    if (!enableWeb) {
      debugPrint('[FB] Web init skipped (ENABLE_FIREBASE_WEB=false)');
      return;
    }

    const apiKey = String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
    const appId = String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '');
    const messagingSenderId = String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: '',
    );
    const projectId = String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: '',
    );
    const authDomain = String.fromEnvironment(
      'FIREBASE_AUTH_DOMAIN',
      defaultValue: '',
    );
    const storageBucket = String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: '',
    );
    const measurementId = String.fromEnvironment(
      'FIREBASE_MEASUREMENT_ID',
      defaultValue: '',
    );

    if ([apiKey, appId, messagingSenderId, projectId].any((e) => e.isEmpty)) {
      debugPrint('[FB] Missing web config. Skipping Firebase init.');
      return;
    }

    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        authDomain: authDomain.isEmpty ? null : authDomain,
        storageBucket: storageBucket.isEmpty ? null : storageBucket,
        measurementId: measurementId.isEmpty ? null : measurementId,
      ),
    );

    const siteKey = String.fromEnvironment(
      'FIREBASE_RECAPTCHA_KEY',
      defaultValue: '',
    );
    if (siteKey.isNotEmpty) {
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider(siteKey),
      );
      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
    }

    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
    } catch (e) {
      debugPrint('Anon sign-in (web) failed: $e');
    }
    return;
  }

  await Firebase.initializeApp();

  final o = Firebase.app().options;
  // Avoid logging apiKey value in production
  debugPrint('[FB] project=${o.projectId} appId=${o.appId}');

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
  if (kIsWeb) return; // Google Mobile Ads no soportado en web
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
  runZonedGuarded(
    () async {
      // Asegura binding y configura manejadores de error (MISMA ZONA que runApp)
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.dumpErrorToConsole(details);
      };

      // Inicializaciones en segundo plano para no bloquear el arranque (especialmente en web)
      unawaited(_initFirebase());
      unawaited(_initAds());
      if (!kIsWeb) {
        // ignore: discarded_futures
        unawaited(NotificationService.init());
      }

      final savedLocale = await _loadSavedLocale();
      final initialLocale = _initialLocale(savedLocale);

      runApp(
        ProviderScope(
          overrides: [localeProvider.overrideWith((ref) => initialLocale)],
          child: const MyApp(),
        ),
      );

      // Inicializa escucha de Dynamic Links (no aplica en web)
      if (!kIsWeb) {
        // ignore: discarded_futures
        DeepLinkService.init();
      }
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
