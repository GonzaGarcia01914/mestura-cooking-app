// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Mestura';

  @override
  String get shoppingMenu => 'Список покупок';

  @override
  String get shoppingTitle => 'Список покупок';

  @override
  String get shoppingAddPlaceholder => 'Добавить элемент';

  @override
  String get shoppingAddTooltip => 'Добавить';

  @override
  String get shoppingRemoveTooltip => 'Удалить';

  @override
  String get shoppingEmpty => 'Список покупок пуст';

  @override
  String get homePrompt => 'Что бы вы хотели?';

  @override
  String get advancedOptions => 'Расширенные параметры';

  @override
  String get numberOfGuests => 'Количество гостей';

  @override
  String get maxCalories => 'Максимум калорий';

  @override
  String get perServing => '(на порцию)';

  @override
  String get includeMacros => 'Включить макроэлементы (примерно)';

  @override
  String get includeMacrosSubtitle => 'Добавляет калории и макроэлементы на порцию.';

  @override
  String get reset => 'Сбросить';

  @override
  String get timeAvailable => 'Доступное время';

  @override
  String get timeUnder15 => '< 15 мин';

  @override
  String get time30 => '30 мин';

  @override
  String get time60 => '1 ч';

  @override
  String get time120 => '2 ч';

  @override
  String get timeNoLimit => 'Без ограничений';

  @override
  String get skillLevel => 'Уровень навыков';

  @override
  String get skillBasic => 'Базовый';

  @override
  String get skillStandard => 'Стандартный';

  @override
  String get skillElevated => 'Продвинутый';

  @override
  String get skillAny => 'Любой';

  @override
  String get searchButton => 'Сгенерировать рецепт';

  @override
  String get surpriseButton => 'Удиви меня';

  @override
  String get ingredientsTitle => 'Ингредиенты';

  @override
  String get stepsTitle => 'Шаги';

  @override
  String get rewriteButton => 'Переписать без удалённых ингредиентов';

  @override
  String get savedTitle => 'Сохранённые рецепты';

  @override
  String get noSavedRecipes => 'У вас ещё нет сохранённых рецептов';

  @override
  String get filterTips => 'Советы';

  @override
  String get filterIngredients => 'Ингредиенты';

  @override
  String get filterDate => 'Дата';

  @override
  String get saveButton => 'Сохранить';

  @override
  String get savedConfirmation => 'Рецепт сохранён!';

  @override
  String get shareButton => 'Поделиться';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get preferenceVegan => 'Веганский';

  @override
  String get preferenceGlutenFree => 'Без глютена';

  @override
  String get language => 'Язык';

  @override
  String get languageSettingLabel => 'Язык приложения';

  @override
  String get subscription => 'Аккаунт / Подписка';

  @override
  String get theme => 'Тема';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get inappropriateInput => 'Ваш запрос не подходит для рецепта. Попробуйте другую идею.';

  @override
  String get loadingMessage => 'Готовим рецепт...';

  @override
  String get loadingTip1 => 'Совет: используйте копчёные специи для более глубокого вкуса.';

  @override
  String get loadingTip2 => 'Совет: поджарьте специи 30 секунд, чтобы раскрыть аромат.';

  @override
  String get loadingTip3 => 'Совет: сохраняйте воду после варки, чтобы регулировать текстуру.';

  @override
  String get loadingTip4 => 'Совет: капля кислоты (лимон/уксус) оживит любое блюдо.';

  @override
  String get loadingTip5 => 'Совет: солите слоями, а не всё в конце.';

  @override
  String get loadingStagePreparing => 'Подготовка';

  @override
  String get loadingStageMixing => 'Смешивание';

  @override
  String get loadingStageSeasoning => 'Приправление';

  @override
  String get loadingStageCooking => 'Приготовление';

  @override
  String get loadingStagePlating => 'Подача';

  @override
  String get nutritionFactsTitle => 'Пищевая ценность (примерно)';

  @override
  String get nutritionPerServing => 'На порцию';

  @override
  String get nutritionCalories => 'Калории';

  @override
  String get nutritionProtein => 'Белки';

  @override
  String get nutritionCarbs => 'Углеводы';

  @override
  String get nutritionFat => 'Жиры';

  @override
  String get nutritionFiber => 'Клетчатка';

  @override
  String get nutritionSugar => 'Сахар';

  @override
  String get nutritionSodium => 'Натрий';

  @override
  String get dialogDoneTitle => 'Готово!';

  @override
  String get dialogErrorTitle => 'Упс…';

  @override
  String get dialogOk => 'Понятно';

  @override
  String get useShoppingList => 'Сгенерировать из списка покупок';

  @override
  String get useShoppingListSubtitle => 'Использовать главным образом съедобные элементы из вашего списка покупок.';

  @override
  String get shoppingNoEdibleItems => 'В вашем списке покупок не найдено съедобных элементов.';

  @override
  String get preferencesMenu => 'Пищевые предпочтения';

  @override
  String get preferencesTitle => 'Пищевые предпочтения';

  @override
  String get preferencesSubtitle => 'Используются для персонализации рецептов';

  @override
  String get preferencesSectionDiet => 'Диета';

  @override
  String get preferencesSectionMedical => 'Медицинские';

  @override
  String get preferencesSectionAllergens => 'Аллергены для исключения';

  @override
  String get preferencesSectionIntolerances => 'Непереносимости';

  @override
  String get preferencesSectionReligion => 'Религия / Культура';

  @override
  String get preferencesDisliked => 'Нежелаемые ингредиенты';

  @override
  String get preferencesAddIngredientPlaceholder => 'Добавьте ингредиент и нажмите Enter';

  @override
  String get preferencesSave => 'Сохранить предпочтения';

  @override
  String get preferencesClear => 'Очистить всё';

  @override
  String get preferencesSaved => 'Предпочтения сохранены!';

  @override
  String get prefVegan => 'Веганская';

  @override
  String get prefVegetarian => 'Вегетарианская';

  @override
  String get prefVegetarianOvo => 'Вегетарианская (ово)';

  @override
  String get prefVegetarianLacto => 'Вегетарианская (лакто)';

  @override
  String get prefVegetarianStrict => 'Вегетарианская (без яиц/молочного)';

  @override
  String get prefPescetarian => 'Пескетарианская';

  @override
  String get prefFlexitarian => 'Флекситарианская';

  @override
  String get prefMediterranean => 'Средиземноморская';

  @override
  String get prefLowCarbKeto => 'Низкоуглев. / Кето';

  @override
  String get prefLowFat => 'С пониженным жиром';

  @override
  String get prefHighProtein => 'Высокобелковая';

  @override
  String get prefPaleo => 'Палео';

  @override
  String get prefWholeFoods => 'Натуральные продукты';

  @override
  String get prefNoUltraProcessed => 'Без ультрапереработанных';

  @override
  String get prefNoAlcohol => 'Без алкоголя';

  @override
  String get prefSpicyLow => 'Слабо острое';

  @override
  String get prefSpicyMedium => 'Средне острое';

  @override
  String get prefSpicyHigh => 'Очень острое';

  @override
  String get prefOrganic => 'Органическое';

  @override
  String get prefGlutenFree => 'Без глютена';

  @override
  String get prefLowFodmap => 'Низкий FODMAP';

  @override
  String get prefLowSodium => 'Мало натрия';

  @override
  String get prefLowSugar => 'Мало сахара / для диабетиков';

  @override
  String get prefLowCholesterol => 'Низкий холестерин';

  @override
  String get prefLowPurine => 'Низкопуриновая';

  @override
  String get prefLowOxalatePotassium => 'Низкий оксалат / калий';

  @override
  String get prefLactoseFree => 'Без лактозы';

  @override
  String get allergenGluten => 'Глютен';

  @override
  String get allergenCrustaceans => 'Ракообразные';

  @override
  String get allergenEggs => 'Яйца';

  @override
  String get allergenFish => 'Рыба';

  @override
  String get allergenPeanuts => 'Арахис';

  @override
  String get allergenSoy => 'Соя';

  @override
  String get allergenMilk => 'Молоко';

  @override
  String get allergenTreeNuts => 'Орехи';

  @override
  String get allergenCelery => 'Сельдерей';

  @override
  String get allergenMustard => 'Горчица';

  @override
  String get allergenSesame => 'Кунжут';

  @override
  String get allergenSulphites => 'Диоксид серы и сульфиты';

  @override
  String get allergenLupin => 'Люпин';

  @override
  String get allergenMolluscs => 'Моллюски';

  @override
  String get prefHalal => 'Халяль';

  @override
  String get prefKosher => 'Кошер';

  @override
  String get prefHindu => 'Индуистская (часто без говядины)';

  @override
  String get prefJain => 'Джайнизм (без корнеплодов; строгий вегет.)';

  @override
  String get prefBuddhist => 'Буддийская (зависит от региона)';

  @override
  String get prefLentFasting => 'Пост (без мяса в некоторые дни)';

  @override
  String get startCookingButton => 'Начать готовить';

  @override
  String get finalizeButton => 'Завершить';

  @override
  String get cookingSheetTitle => 'Рецепт готов!';

  @override
  String get cookingSheetTakePhotoShare => 'Сделать фото и поделиться';

  @override
  String get cookingSheetShareNoPhoto => 'Поделиться без фото';

  @override
  String get cookingSheetSaveRecipe => 'Сохранить рецепт';

  @override
  String get cookingSheetGoHome => 'Закрыть и на главную';

  @override
  String get timerStartTooltip => 'Старт';

  @override
  String get timerPauseTooltip => 'Пауза';

  @override
  String get timerResumeTooltip => 'Продолжить';

  @override
  String get timerDiscardTooltip => 'Отменить';

  @override
  String get timerDoneTitle => 'Время вышло!';

  @override
  String get timerDoneBody => 'Шаг рецепта завершён.';

  @override
  String cookingNotificationTitle(Object title) {
    return 'Готовим: $title';
  }

  @override
  String cookingOngoingBody(Object step) {
    return 'Шаг $step • обратный отсчёт';
  }

  @override
  String shareCookedText(Object link, Object title) {
    return 'Я только что приготовил(а) «$title»! Попробуйте приложение: $link';
  }

  @override
  String shoppingAddedItem(String item) {
    return '$item добавлено в список покупок!';
  }
}
