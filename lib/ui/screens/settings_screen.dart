import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isVegan = false;
  bool isGlutenFree = false;
  ThemeMode themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text(
              s.settingsTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Preferencias alimenticias
            Text(
              s.preferenceVegan,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            CheckboxListTile(
              title: Text(s.preferenceVegan),
              value: isVegan,
              onChanged: (value) => setState(() => isVegan = value ?? false),
            ),
            CheckboxListTile(
              title: Text(s.preferenceGlutenFree),
              value: isGlutenFree,
              onChanged:
                  (value) => setState(() => isGlutenFree = value ?? false),
            ),
            const Divider(height: 32),

            // Idioma
            ListTile(
              title: Text(s.language),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Aquí podrías abrir un modal o pantalla para cambiar idioma
              },
            ),

            // Cuenta
            ListTile(
              title: Text(s.subscription),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Aquí se abriría gestión de cuenta / subscripción
              },
            ),

            // Tema claro/oscuro
            const Divider(height: 32),
            Text(s.theme),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<ThemeMode>(
                    title: Text(s.themeLight),
                    value: ThemeMode.light,
                    groupValue: themeMode,
                    onChanged: (mode) => setState(() => themeMode = mode!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<ThemeMode>(
                    title: Text(s.themeDark),
                    value: ThemeMode.dark,
                    groupValue: themeMode,
                    onChanged: (mode) => setState(() => themeMode = mode!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
