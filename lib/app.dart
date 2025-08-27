import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../l10n/app_localizations.dart';

import 'ui/screens/home_screen.dart';
import 'ui/screens/saved_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'core/theme/app_theme.dart';

class App extends StatelessWidget {
  final Locale locale;

  const App({super.key, required this.locale});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mestura',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      locale: locale, // ✅ usamos el locale pasado desde main.dart
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
      },
    );
  }
}
