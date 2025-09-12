// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mestura';

  @override
  String get shoppingMenu => 'Shopping list';

  @override
  String get shoppingTitle => 'Shopping list';

  @override
  String get shoppingAddPlaceholder => 'Add item';

  @override
  String get shoppingAddTooltip => 'Add';

  @override
  String get shoppingRemoveTooltip => 'Remove';

  @override
  String get shoppingEmpty => 'Shopping list is empty';

  @override
  String get homePrompt => 'What are you in the mood for?';

  @override
  String get advancedOptions => 'Advanced Options';

  @override
  String get numberOfGuests => 'Number of Guests';

  @override
  String get maxCalories => 'Max calories';

  @override
  String get perServing => '(per serving)';

  @override
  String get includeMacros => 'Include macros (estimated)';

  @override
  String get includeMacrosSubtitle => 'Adds calories and macronutrients per serving.';

  @override
  String get reset => 'Reset';

  @override
  String get timeAvailable => 'Time available';

  @override
  String get timeUnder15 => '< 15 min';

  @override
  String get time30 => '30 min';

  @override
  String get time60 => '1 h';

  @override
  String get time120 => '2 h';

  @override
  String get timeNoLimit => 'No limit';

  @override
  String get skillLevel => 'Skill level';

  @override
  String get skillBasic => 'Basic';

  @override
  String get skillStandard => 'Standard';

  @override
  String get skillElevated => 'Advanced';

  @override
  String get skillAny => 'Any';

  @override
  String get searchButton => 'Generate recipe';

  @override
  String get surpriseButton => 'Surprise me';

  @override
  String get ingredientsTitle => 'Ingredients';

  @override
  String get stepsTitle => 'Steps';

  @override
  String get rewriteButton => 'Rewrite without removed ingredients';

  @override
  String get savedTitle => 'Saved Recipes';

  @override
  String get noSavedRecipes => 'You don\'t have any saved recipes yet';

  @override
  String get filterTips => 'Tips';

  @override
  String get filterIngredients => 'Ingredients';

  @override
  String get filterDate => 'Date';

  @override
  String get saveButton => 'Save';

  @override
  String get savedConfirmation => 'Recipe saved!';

  @override
  String get shareButton => 'Share';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get preferenceVegan => 'Vegan';

  @override
  String get preferenceGlutenFree => 'Gluten-free';

  @override
  String get language => 'Language';

  @override
  String get languageSettingLabel => 'App language';

  @override
  String get subscription => 'Account / Subscription';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get inappropriateInput => 'Your request is not appropriate for a recipe. Try another idea.';

  @override
  String get loadingMessage => 'Cooking the recipe...';

  @override
  String get loadingTip1 => 'Tip: Try smoked spices for deeper flavor.';

  @override
  String get loadingTip2 => 'Tip: Toast spices for 30s to unlock aromas.';

  @override
  String get loadingTip3 => 'Tip: Save cooking water to adjust texture.';

  @override
  String get loadingTip4 => 'Tip: A splash of acid (lemon/vinegar) brightens any dish.';

  @override
  String get loadingTip5 => 'Tip: Salt in layers, not all at the end.';

  @override
  String get loadingStagePreparing => 'Preparing';

  @override
  String get loadingStageMixing => 'Mixing';

  @override
  String get loadingStageSeasoning => 'Seasoning';

  @override
  String get loadingStageCooking => 'Cooking';

  @override
  String get loadingStagePlating => 'Plating';

  @override
  String get nutritionFactsTitle => 'Nutrition facts (approx.)';

  @override
  String get nutritionPerServing => 'Per serving';

  @override
  String get nutritionCalories => 'Calories';

  @override
  String get nutritionProtein => 'Protein';

  @override
  String get nutritionCarbs => 'Carbs';

  @override
  String get nutritionFat => 'Fat';

  @override
  String get nutritionFiber => 'Fiber';

  @override
  String get nutritionSugar => 'Sugar';

  @override
  String get nutritionSodium => 'Sodium';

  @override
  String get dialogDoneTitle => 'Done!';

  @override
  String get dialogErrorTitle => 'Oops…';

  @override
  String get dialogOk => 'Got it';

  @override
  String get useShoppingList => 'Generate from shopping list';

  @override
  String get useShoppingListSubtitle => 'Use primarily edible items from your shopping list.';

  @override
  String get shoppingNoEdibleItems => 'No edible items were found in your shopping list.';

  @override
  String get preferencesMenu => 'Dietary preferences';

  @override
  String get preferencesTitle => 'Dietary preferences';

  @override
  String get preferencesSubtitle => 'Used to personalize recipes';

  @override
  String get preferencesSectionDiet => 'Diet';

  @override
  String get preferencesSectionMedical => 'Medical';

  @override
  String get preferencesSectionAllergens => 'Allergens to avoid';

  @override
  String get preferencesSectionIntolerances => 'Intolerances';

  @override
  String get preferencesSectionReligion => 'Religion / Culture';

  @override
  String get preferencesDisliked => 'Disliked ingredients';

  @override
  String get preferencesAddIngredientPlaceholder => 'Add ingredient and press Enter';

  @override
  String get preferencesSave => 'Save preferences';

  @override
  String get preferencesClear => 'Clear all';

  @override
  String get preferencesSaved => 'Preferences saved!';

  @override
  String get prefVegan => 'Vegan';

  @override
  String get prefVegetarian => 'Vegetarian';

  @override
  String get prefVegetarianOvo => 'Vegetarian (ovo)';

  @override
  String get prefVegetarianLacto => 'Vegetarian (lacto)';

  @override
  String get prefVegetarianStrict => 'Vegetarian (no egg/dairy)';

  @override
  String get prefPescetarian => 'Pescetarian';

  @override
  String get prefFlexitarian => 'Flexitarian';

  @override
  String get prefMediterranean => 'Mediterranean';

  @override
  String get prefLowCarbKeto => 'Low-carb / Keto';

  @override
  String get prefLowFat => 'Low fat';

  @override
  String get prefHighProtein => 'High protein';

  @override
  String get prefPaleo => 'Paleo';

  @override
  String get prefWholeFoods => 'Whole foods';

  @override
  String get prefNoUltraProcessed => 'No ultra-processed';

  @override
  String get prefNoAlcohol => 'No alcohol';

  @override
  String get prefSpicyLow => 'Low spice';

  @override
  String get prefSpicyMedium => 'Medium spice';

  @override
  String get prefSpicyHigh => 'High spice';

  @override
  String get prefOrganic => 'Organic';

  @override
  String get prefGlutenFree => 'Gluten-free';

  @override
  String get prefLowFodmap => 'Low FODMAP';

  @override
  String get prefLowSodium => 'Low sodium';

  @override
  String get prefLowSugar => 'Low sugar / diabetic';

  @override
  String get prefLowCholesterol => 'Low cholesterol';

  @override
  String get prefLowPurine => 'Low purine';

  @override
  String get prefLowOxalatePotassium => 'Low oxalate / potassium';

  @override
  String get prefLactoseFree => 'Lactose-free';

  @override
  String get allergenGluten => 'Gluten';

  @override
  String get allergenCrustaceans => 'Crustaceans';

  @override
  String get allergenEggs => 'Eggs';

  @override
  String get allergenFish => 'Fish';

  @override
  String get allergenPeanuts => 'Peanuts';

  @override
  String get allergenSoy => 'Soy';

  @override
  String get allergenMilk => 'Milk';

  @override
  String get allergenTreeNuts => 'Tree nuts';

  @override
  String get allergenCelery => 'Celery';

  @override
  String get allergenMustard => 'Mustard';

  @override
  String get allergenSesame => 'Sesame';

  @override
  String get allergenSulphites => 'Sulphites';

  @override
  String get allergenLupin => 'Lupin';

  @override
  String get allergenMolluscs => 'Molluscs';

  @override
  String get prefHalal => 'Halal';

  @override
  String get prefKosher => 'Kosher';

  @override
  String get prefHindu => 'Hindu (often avoids beef)';

  @override
  String get prefJain => 'Jain (no roots; strict vegetarian)';

  @override
  String get prefBuddhist => 'Buddhist (varies by region)';

  @override
  String get prefLentFasting => 'Lent / fasting (no meat on some days)';

  @override
  String get startCookingButton => 'Start cooking';

  @override
  String get finalizeButton => 'Finish';

  @override
  String get cookingSheetTitle => 'Recipe completed!';

  @override
  String get cookingSheetTakePhotoShare => 'Take photo and share';

  @override
  String get cookingSheetShareNoPhoto => 'Share without photo';

  @override
  String get cookingSheetSaveRecipe => 'Save recipe';

  @override
  String get cookingSheetGoHome => 'Close and go home';

  @override
  String get timerStartTooltip => 'Start';

  @override
  String get timerPauseTooltip => 'Pause';

  @override
  String get timerResumeTooltip => 'Resume';

  @override
  String get timerDiscardTooltip => 'Discard';

  @override
  String get timerDoneTitle => 'Time’s up!';

  @override
  String get timerDoneBody => 'The recipe step has finished.';

  @override
  String cookingNotificationTitle(Object title) {
    return 'Cooking: $title';
  }

  @override
  String cookingOngoingBody(Object step) {
    return 'Step $step • countdown';
  }

  @override
  String shareCookedText(Object link, Object title) {
    return 'I just cooked \"$title\"! Try the app: $link';
  }

  @override
  String shoppingAddedItem(String item) {
    return '$item added to the shopping list!';
  }
}
