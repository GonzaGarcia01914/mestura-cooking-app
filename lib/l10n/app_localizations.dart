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

  /// No description provided for @timeAvailable.
  ///
  /// In en, this message translates to:
  /// **'Time available'**
  String get timeAvailable;

  /// No description provided for @timeUnder15.
  ///
  /// In en, this message translates to:
  /// **'< 15 min'**
  String get timeUnder15;

  /// No description provided for @time30.
  ///
  /// In en, this message translates to:
  /// **'30 min'**
  String get time30;

  /// No description provided for @time60.
  ///
  /// In en, this message translates to:
  /// **'1 h'**
  String get time60;

  /// No description provided for @time120.
  ///
  /// In en, this message translates to:
  /// **'2 h'**
  String get time120;

  /// No description provided for @timeNoLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get timeNoLimit;

  /// No description provided for @skillLevel.
  ///
  /// In en, this message translates to:
  /// **'Skill level'**
  String get skillLevel;

  /// No description provided for @skillBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get skillBasic;

  /// No description provided for @skillStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get skillStandard;

  /// No description provided for @skillElevated.
  ///
  /// In en, this message translates to:
  /// **'Elevated'**
  String get skillElevated;

  /// No description provided for @skillAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get skillAny;

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

  /// No description provided for @preferencesMenu.
  ///
  /// In en, this message translates to:
  /// **'Dietary preferences'**
  String get preferencesMenu;

  /// No description provided for @preferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Dietary preferences'**
  String get preferencesTitle;

  /// No description provided for @preferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used to personalize recipes'**
  String get preferencesSubtitle;

  /// No description provided for @preferencesSectionDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get preferencesSectionDiet;

  /// No description provided for @preferencesSectionMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get preferencesSectionMedical;

  /// No description provided for @preferencesSectionAllergens.
  ///
  /// In en, this message translates to:
  /// **'Allergens to avoid'**
  String get preferencesSectionAllergens;

  /// No description provided for @preferencesSectionIntolerances.
  ///
  /// In en, this message translates to:
  /// **'Intolerances'**
  String get preferencesSectionIntolerances;

  /// No description provided for @preferencesSectionReligion.
  ///
  /// In en, this message translates to:
  /// **'Religious / Cultural'**
  String get preferencesSectionReligion;

  /// No description provided for @preferencesDisliked.
  ///
  /// In en, this message translates to:
  /// **'Disliked ingredients'**
  String get preferencesDisliked;

  /// No description provided for @preferencesAddIngredientPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient and press Enter'**
  String get preferencesAddIngredientPlaceholder;

  /// No description provided for @preferencesSave.
  ///
  /// In en, this message translates to:
  /// **'Save preferences'**
  String get preferencesSave;

  /// No description provided for @preferencesClear.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get preferencesClear;

  /// No description provided for @preferencesSaved.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved!'**
  String get preferencesSaved;

  /// No description provided for @prefVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get prefVegan;

  /// No description provided for @prefVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get prefVegetarian;

  /// No description provided for @prefVegetarianOvo.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian (ovo)'**
  String get prefVegetarianOvo;

  /// No description provided for @prefVegetarianLacto.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian (lacto)'**
  String get prefVegetarianLacto;

  /// No description provided for @prefVegetarianStrict.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian (no egg/dairy)'**
  String get prefVegetarianStrict;

  /// No description provided for @prefPescetarian.
  ///
  /// In en, this message translates to:
  /// **'Pescetarian'**
  String get prefPescetarian;

  /// No description provided for @prefFlexitarian.
  ///
  /// In en, this message translates to:
  /// **'Flexitarian'**
  String get prefFlexitarian;

  /// No description provided for @prefMediterranean.
  ///
  /// In en, this message translates to:
  /// **'Mediterranean'**
  String get prefMediterranean;

  /// No description provided for @prefLowCarbKeto.
  ///
  /// In en, this message translates to:
  /// **'Low-carb / Keto'**
  String get prefLowCarbKeto;

  /// No description provided for @prefLowFat.
  ///
  /// In en, this message translates to:
  /// **'Low-fat'**
  String get prefLowFat;

  /// No description provided for @prefHighProtein.
  ///
  /// In en, this message translates to:
  /// **'High-protein'**
  String get prefHighProtein;

  /// No description provided for @prefPaleo.
  ///
  /// In en, this message translates to:
  /// **'Paleo'**
  String get prefPaleo;

  /// No description provided for @prefWholeFoods.
  ///
  /// In en, this message translates to:
  /// **'Whole foods'**
  String get prefWholeFoods;

  /// No description provided for @prefNoUltraProcessed.
  ///
  /// In en, this message translates to:
  /// **'No ultra-processed'**
  String get prefNoUltraProcessed;

  /// No description provided for @prefNoAlcohol.
  ///
  /// In en, this message translates to:
  /// **'No alcohol'**
  String get prefNoAlcohol;

  /// No description provided for @prefSpicyLow.
  ///
  /// In en, this message translates to:
  /// **'Low spicy'**
  String get prefSpicyLow;

  /// No description provided for @prefSpicyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium spicy'**
  String get prefSpicyMedium;

  /// No description provided for @prefSpicyHigh.
  ///
  /// In en, this message translates to:
  /// **'High spicy'**
  String get prefSpicyHigh;

  /// No description provided for @prefOrganic.
  ///
  /// In en, this message translates to:
  /// **'Organic'**
  String get prefOrganic;

  /// No description provided for @prefGlutenFree.
  ///
  /// In en, this message translates to:
  /// **'Gluten-free'**
  String get prefGlutenFree;

  /// No description provided for @prefLowFodmap.
  ///
  /// In en, this message translates to:
  /// **'Low FODMAP'**
  String get prefLowFodmap;

  /// No description provided for @prefLowSodium.
  ///
  /// In en, this message translates to:
  /// **'Low sodium'**
  String get prefLowSodium;

  /// No description provided for @prefLowSugar.
  ///
  /// In en, this message translates to:
  /// **'Low sugar / Diabetic-friendly'**
  String get prefLowSugar;

  /// No description provided for @prefLowCholesterol.
  ///
  /// In en, this message translates to:
  /// **'Low cholesterol'**
  String get prefLowCholesterol;

  /// No description provided for @prefLowPurine.
  ///
  /// In en, this message translates to:
  /// **'Low purines'**
  String get prefLowPurine;

  /// No description provided for @prefLowOxalatePotassium.
  ///
  /// In en, this message translates to:
  /// **'Low oxalates / potassium'**
  String get prefLowOxalatePotassium;

  /// No description provided for @prefLactoseFree.
  ///
  /// In en, this message translates to:
  /// **'Lactose-free'**
  String get prefLactoseFree;

  /// No description provided for @allergenGluten.
  ///
  /// In en, this message translates to:
  /// **'Gluten'**
  String get allergenGluten;

  /// No description provided for @allergenCrustaceans.
  ///
  /// In en, this message translates to:
  /// **'Crustaceans'**
  String get allergenCrustaceans;

  /// No description provided for @allergenEggs.
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get allergenEggs;

  /// No description provided for @allergenFish.
  ///
  /// In en, this message translates to:
  /// **'Fish'**
  String get allergenFish;

  /// No description provided for @allergenPeanuts.
  ///
  /// In en, this message translates to:
  /// **'Peanuts'**
  String get allergenPeanuts;

  /// No description provided for @allergenSoy.
  ///
  /// In en, this message translates to:
  /// **'Soy'**
  String get allergenSoy;

  /// No description provided for @allergenMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get allergenMilk;

  /// No description provided for @allergenTreeNuts.
  ///
  /// In en, this message translates to:
  /// **'Tree nuts'**
  String get allergenTreeNuts;

  /// No description provided for @allergenCelery.
  ///
  /// In en, this message translates to:
  /// **'Celery'**
  String get allergenCelery;

  /// No description provided for @allergenMustard.
  ///
  /// In en, this message translates to:
  /// **'Mustard'**
  String get allergenMustard;

  /// No description provided for @allergenSesame.
  ///
  /// In en, this message translates to:
  /// **'Sesame'**
  String get allergenSesame;

  /// No description provided for @allergenSulphites.
  ///
  /// In en, this message translates to:
  /// **'Sulphites'**
  String get allergenSulphites;

  /// No description provided for @allergenLupin.
  ///
  /// In en, this message translates to:
  /// **'Lupin'**
  String get allergenLupin;

  /// No description provided for @allergenMolluscs.
  ///
  /// In en, this message translates to:
  /// **'Molluscs'**
  String get allergenMolluscs;

  /// No description provided for @prefHalal.
  ///
  /// In en, this message translates to:
  /// **'Halal'**
  String get prefHalal;

  /// No description provided for @prefKosher.
  ///
  /// In en, this message translates to:
  /// **'Kosher'**
  String get prefKosher;

  /// No description provided for @prefHindu.
  ///
  /// In en, this message translates to:
  /// **'Hindu (often avoids beef)'**
  String get prefHindu;

  /// No description provided for @prefJain.
  ///
  /// In en, this message translates to:
  /// **'Jain (no roots; strict vegetarian)'**
  String get prefJain;

  /// No description provided for @prefBuddhist.
  ///
  /// In en, this message translates to:
  /// **'Buddhist (varies by region)'**
  String get prefBuddhist;

  /// No description provided for @prefLentFasting.
  ///
  /// In en, this message translates to:
  /// **'Lent / fasting (no meat certain days)'**
  String get prefLentFasting;

  /// No description provided for @startCookingButton.
  ///
  /// In en, this message translates to:
  /// **'Start cooking'**
  String get startCookingButton;

  /// No description provided for @finalizeButton.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finalizeButton;

  /// No description provided for @cookingSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Recipe completed!'**
  String get cookingSheetTitle;

  /// No description provided for @cookingSheetTakePhotoShare.
  ///
  /// In en, this message translates to:
  /// **'Take photo and share'**
  String get cookingSheetTakePhotoShare;

  /// No description provided for @cookingSheetShareNoPhoto.
  ///
  /// In en, this message translates to:
  /// **'Share without photo'**
  String get cookingSheetShareNoPhoto;

  /// No description provided for @cookingSheetSaveRecipe.
  ///
  /// In en, this message translates to:
  /// **'Save recipe'**
  String get cookingSheetSaveRecipe;

  /// No description provided for @cookingSheetGoHome.
  ///
  /// In en, this message translates to:
  /// **'Close and go to Home'**
  String get cookingSheetGoHome;

  /// No description provided for @timerStartTooltip.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get timerStartTooltip;

  /// No description provided for @timerPauseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get timerPauseTooltip;

  /// No description provided for @timerResumeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get timerResumeTooltip;

  /// No description provided for @timerDiscardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get timerDiscardTooltip;

  /// No description provided for @timerDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up!'**
  String get timerDoneTitle;

  /// No description provided for @timerDoneBody.
  ///
  /// In en, this message translates to:
  /// **'The cooking step has finished.'**
  String get timerDoneBody;

  /// No description provided for @cookingNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Cooking: {title}'**
  String cookingNotificationTitle(String title);

  /// No description provided for @cookingOngoingBody.
  ///
  /// In en, this message translates to:
  /// **'Step {step} • countdown'**
  String cookingOngoingBody(String step);

  /// No description provided for @shareCookedText.
  ///
  /// In en, this message translates to:
  /// **'I just cooked \"{title}\"! Try the app: {link}'**
  String shareCookedText(String title, String link);
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
