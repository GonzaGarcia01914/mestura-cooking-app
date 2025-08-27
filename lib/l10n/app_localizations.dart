import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_gn.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('gn'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Mestura'**
  String get appTitle;

  /// No description provided for @homePrompt.
  ///
  /// In en, this message translates to:
  /// **'What would you like?'**
  String get homePrompt;

  /// No description provided for @advancedOptions.
  ///
  /// In en, this message translates to:
  /// **'Advanced options'**
  String get advancedOptions;

  /// No description provided for @numberOfGuests.
  ///
  /// In en, this message translates to:
  /// **'Number of Guests'**
  String get numberOfGuests;

  /// No description provided for @maxCalories.
  ///
  /// In en, this message translates to:
  /// **'Max calories'**
  String get maxCalories;

  /// No description provided for @perServing.
  ///
  /// In en, this message translates to:
  /// **'(per serving)'**
  String get perServing;

  /// No description provided for @includeMacros.
  ///
  /// In en, this message translates to:
  /// **'Include macros (estimated)'**
  String get includeMacros;

  /// No description provided for @includeMacrosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adds calories & macros per serving.'**
  String get includeMacrosSubtitle;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @searchButton.
  ///
  /// In en, this message translates to:
  /// **'Generate recipe'**
  String get searchButton;

  /// No description provided for @surpriseButton.
  ///
  /// In en, this message translates to:
  /// **'Surprise me'**
  String get surpriseButton;

  /// No description provided for @ingredientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredientsTitle;

  /// No description provided for @stepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get stepsTitle;

  /// No description provided for @rewriteButton.
  ///
  /// In en, this message translates to:
  /// **'Rewrite without selected ingredients'**
  String get rewriteButton;

  /// No description provided for @savedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Recipes'**
  String get savedTitle;

  /// No description provided for @noSavedRecipes.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t saved any recipes yet'**
  String get noSavedRecipes;

  /// No description provided for @filterTips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get filterTips;

  /// No description provided for @filterIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get filterIngredients;

  /// No description provided for @filterDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get filterDate;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @savedConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Recipe saved!'**
  String get savedConfirmation;

  /// No description provided for @shareButton.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButton;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @preferenceVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get preferenceVegan;

  /// No description provided for @preferenceGlutenFree.
  ///
  /// In en, this message translates to:
  /// **'Gluten-free'**
  String get preferenceGlutenFree;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSettingLabel.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get languageSettingLabel;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Account / Subscription'**
  String get subscription;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @inappropriateInput.
  ///
  /// In en, this message translates to:
  /// **'Your input is not appropriate for a recipe. Please try a different idea.'**
  String get inappropriateInput;

  /// No description provided for @loadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Cooking the recipe...'**
  String get loadingMessage;

  /// No description provided for @loadingTip1.
  ///
  /// In en, this message translates to:
  /// **'Tip: Try smoked spices for deeper flavor.'**
  String get loadingTip1;

  /// No description provided for @loadingTip2.
  ///
  /// In en, this message translates to:
  /// **'Tip: Toast spices for 30s to unlock aromas.'**
  String get loadingTip2;

  /// No description provided for @loadingTip3.
  ///
  /// In en, this message translates to:
  /// **'Tip: Save cooking water to adjust texture.'**
  String get loadingTip3;

  /// No description provided for @loadingTip4.
  ///
  /// In en, this message translates to:
  /// **'Tip: A splash of acid (lemon/vinegar) brightens any dish.'**
  String get loadingTip4;

  /// No description provided for @loadingTip5.
  ///
  /// In en, this message translates to:
  /// **'Tip: Salt in layers, not all at the end.'**
  String get loadingTip5;

  /// No description provided for @loadingStagePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get loadingStagePreparing;

  /// No description provided for @loadingStageMixing.
  ///
  /// In en, this message translates to:
  /// **'Mixing'**
  String get loadingStageMixing;

  /// No description provided for @loadingStageSeasoning.
  ///
  /// In en, this message translates to:
  /// **'Seasoning'**
  String get loadingStageSeasoning;

  /// No description provided for @loadingStageCooking.
  ///
  /// In en, this message translates to:
  /// **'Cooking'**
  String get loadingStageCooking;

  /// No description provided for @loadingStagePlating.
  ///
  /// In en, this message translates to:
  /// **'Plating'**
  String get loadingStagePlating;

  /// No description provided for @nutritionFactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition facts (approx.)'**
  String get nutritionFactsTitle;

  /// No description provided for @nutritionPerServing.
  ///
  /// In en, this message translates to:
  /// **'Per serving'**
  String get nutritionPerServing;

  /// No description provided for @nutritionCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get nutritionCalories;

  /// No description provided for @nutritionProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get nutritionProtein;

  /// No description provided for @nutritionCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get nutritionCarbs;

  /// No description provided for @nutritionFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get nutritionFat;

  /// No description provided for @nutritionFiber.
  ///
  /// In en, this message translates to:
  /// **'Fiber'**
  String get nutritionFiber;

  /// No description provided for @nutritionSugar.
  ///
  /// In en, this message translates to:
  /// **'Sugars'**
  String get nutritionSugar;

  /// No description provided for @nutritionSodium.
  ///
  /// In en, this message translates to:
  /// **'Sodium'**
  String get nutritionSodium;

  /// No description provided for @dialogDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Done!'**
  String get dialogDoneTitle;

  /// No description provided for @dialogErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Oops…'**
  String get dialogErrorTitle;

  /// No description provided for @dialogOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get dialogOk;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'es', 'fr', 'gn', 'it', 'ja', 'ko', 'pl', 'pt', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'gn': return AppLocalizationsGn();
    case 'it': return AppLocalizationsIt();
    case 'ja': return AppLocalizationsJa();
    case 'ko': return AppLocalizationsKo();
    case 'pl': return AppLocalizationsPl();
    case 'pt': return AppLocalizationsPt();
    case 'ru': return AppLocalizationsRu();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
