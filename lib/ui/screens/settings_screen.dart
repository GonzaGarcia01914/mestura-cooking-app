import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../core/providers.dart';

// Design system
import '../widgets/app_scaffold.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/frosted_container.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _scrollCtrl = ScrollController();
  double _appBarTint = 0.0; // 0 = transparente, ~0.08 = máximo

  static const Map<String, String> _languages = {
    'es': 'Español',
    'en': 'English',
    'ru': 'Русский',
    'de': 'Deutsch',
    'pl': 'Polski',
    'pt': 'Português',
    'fr': 'Français',
    'ja': '日本語',
    'zh': '中文',
    'ko': '한국어',
    'it': 'Italiano',
    'gn': "Avañe'ẽ",
  };

  String _selected = 'en'; // valor por defecto

  @override
  void initState() {
    super.initState();
    _loadLanguage();

    _scrollCtrl.addListener(() {
      const maxTint = 0.08;
      final off = _scrollCtrl.hasClients ? _scrollCtrl.offset : 0.0;
      final t = (off / 48).clamp(0.0, 1.0) * maxTint;
      if ((t - _appBarTint).abs() > 0.004) setState(() => _appBarTint = t);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    // Compatibilidad: intenta 'locale', luego 'languageCode'
    final saved =
        prefs.getString('locale') ??
        prefs.getString('languageCode') ??
        Localizations.localeOf(context).languageCode;

    setState(() => _selected = _languages.keys.contains(saved) ? saved : 'en');
  }

  Future<void> _changeLanguage(String langCode) async {
    setState(() => _selected = langCode);
    final prefs = await SharedPreferences.getInstance();

    // Guarda ambas claves para mantener compatibilidad con otras pantallas
    await prefs.setString('locale', langCode);
    await prefs.setString('languageCode', langCode);

    ref.read(localeProvider.notifier).state = Locale(langCode);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final topPad = MediaQuery.of(context).padding.top + 72 + 8;

    return AppScaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppTopBar(
        title: Text(s.settingsTitle),
        leading: const BackButton(),
        blurSigma: _appBarTint > 0 ? 6 : 0,
        tintOpacity: _appBarTint,
      ),
      body: SingleChildScrollView(
        controller: _scrollCtrl,
        padding: EdgeInsets.fromLTRB(20, topPad, 20, 24),
        child: FrostedContainer(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.languageSettingLabel,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._languages.entries.map(
                (entry) => RadioListTile<String>(
                  value: entry.key,
                  groupValue: _selected,
                  onChanged: (lang) {
                    if (lang != null) _changeLanguage(lang);
                  },
                  title: Text(entry.value),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
