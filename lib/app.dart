import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'ui/screens/home_screen.dart';
import 'ui/screens/recipe_screen.dart';
import 'ui/screens/rewrite_screen.dart';
import 'ui/screens/saved_screen.dart';
import 'ui/screens/settings_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mestura',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        fontFamily: 'Roboto',
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('es')],
      home: const HomeScreen(),
      routes: {
        '/rewrite': (_) => const RewriteScreen(),
        '/saved': (_) => const SavedScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
