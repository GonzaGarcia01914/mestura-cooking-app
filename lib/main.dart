import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('locale'); // 'es' o 'en'

  runApp(MyApp(savedLocale: savedLocale));
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
    if (widget.savedLocale != null) {
      return Locale(widget.savedLocale!);
    }
    final systemLocale =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return (systemLocale == 'es') ? const Locale('es') : const Locale('en');
  }

  void changeLocale(Locale newLocale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', newLocale.languageCode);
    setState(() {
      _locale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return App(locale: _locale);
  }
}
