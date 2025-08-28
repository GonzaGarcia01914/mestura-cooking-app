import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';

import 'ui/screens/home_screen.dart';
import 'ui/screens/saved_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/preferences_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/providers.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      title: 'Mestura',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/saved': (_) => const SavedScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/preferences': (_) => const PreferencesScreen(),
      },
    );
  }
}
