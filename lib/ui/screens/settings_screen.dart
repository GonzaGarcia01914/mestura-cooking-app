import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<SettingsScreen> {
  String _selected = 'en'; // valor por defecto

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selected = prefs.getString('locale') ??
          (Localizations.localeOf(context).languageCode == 'es' ? 'es' : 'en');
    });
  }

  Future<void> _changeLanguage(String langCode) async {
    setState(() => _selected = langCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', langCode);
    MyApp.setLocale(context, Locale(langCode));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.languageSettingLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              value: 'es',
              groupValue: _selected,
              onChanged: (lang) {
                if (lang != null) _changeLanguage(lang);
              },
              title: const Text('Español'),
            ),
            RadioListTile<String>(
              value: 'en',
              groupValue: _selected,
              onChanged: (lang) {
                if (lang != null) _changeLanguage(lang);
              },
              title: const Text('English'),
            ),
          ],
        ),
      ),
    );
  }
}
