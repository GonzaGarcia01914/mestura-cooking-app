// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Mestura';

  @override
  String get homePrompt => '何を作りたいですか？';

  @override
  String get advancedOptions => '詳細オプション';

  @override
  String get numberOfGuests => '人数';

  @override
  String get maxCalories => '最大カロリー';

  @override
  String get perServing => '（1人分）';

  @override
  String get includeMacros => 'マクロを含める（推定）';

  @override
  String get includeMacrosSubtitle => '1人分のカロリーとマクロを追加します。';

  @override
  String get reset => 'リセット';

  @override
  String get timeAvailable => '利用可能な時間';

  @override
  String get timeUnder15 => '< 15 分';

  @override
  String get time30 => '30 分';

  @override
  String get time60 => '1 時間';

  @override
  String get time120 => '2 時間';

  @override
  String get timeNoLimit => '制限なし';

  @override
  String get skillLevel => 'スキルレベル';

  @override
  String get skillBasic => '初級';

  @override
  String get skillStandard => '標準';

  @override
  String get skillElevated => '上級';

  @override
  String get skillAny => '指定なし';

  @override
  String get searchButton => 'レシピを生成';

  @override
  String get surpriseButton => 'おまかせ';

  @override
  String get ingredientsTitle => '材料';

  @override
  String get stepsTitle => '手順';

  @override
  String get rewriteButton => '選択した材料を除いて書き直す';

  @override
  String get savedTitle => '保存したレシピ';

  @override
  String get noSavedRecipes => 'まだレシピを保存していません';

  @override
  String get filterTips => 'ヒント';

  @override
  String get filterIngredients => '材料';

  @override
  String get filterDate => '日付';

  @override
  String get saveButton => '保存';

  @override
  String get savedConfirmation => 'レシピを保存しました！';

  @override
  String get shareButton => '共有';

  @override
  String get settingsTitle => '設定';

  @override
  String get preferenceVegan => 'ヴィーガン';

  @override
  String get preferenceGlutenFree => 'グルテンフリー';

  @override
  String get language => '言語';

  @override
  String get languageSettingLabel => 'アプリの言語';

  @override
  String get subscription => 'アカウント / サブスクリプション';

  @override
  String get theme => 'テーマ';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get inappropriateInput => 'その入力はレシピに適していません。別のアイデアを試してください。';

  @override
  String get loadingMessage => 'レシピを調理中...';

  @override
  String get loadingTip1 => 'ヒント: スモークスパイスでより深い風味に。';

  @override
  String get loadingTip2 => 'ヒント: スパイスを30秒ほど炒って香りを引き出そう。';

  @override
  String get loadingTip3 => 'ヒント: 茹で汁をとっておくと食感の調整に役立ちます。';

  @override
  String get loadingTip4 => 'ヒント: 少量の酸味（レモン/酢）が料理を引き立てます。';

  @override
  String get loadingTip5 => 'ヒント: 一度に入れず、少しずつ塩を加えましょう。';

  @override
  String get loadingStagePreparing => '準備中';

  @override
  String get loadingStageMixing => '混合';

  @override
  String get loadingStageSeasoning => '味付け';

  @override
  String get loadingStageCooking => '調理';

  @override
  String get loadingStagePlating => '盛り付け';

  @override
  String get nutritionFactsTitle => '栄養成分 (概算)';

  @override
  String get nutritionPerServing => '1人分あたり';

  @override
  String get nutritionCalories => 'カロリー';

  @override
  String get nutritionProtein => 'たんぱく質';

  @override
  String get nutritionCarbs => '炭水化物';

  @override
  String get nutritionFat => '脂質';

  @override
  String get nutritionFiber => '食物繊維';

  @override
  String get nutritionSugar => '糖質';

  @override
  String get nutritionSodium => 'ナトリウム';

  @override
  String get dialogDoneTitle => '完了!';

  @override
  String get dialogErrorTitle => 'おっと…';

  @override
  String get dialogOk => 'OK';

  @override
  String get preferencesMenu => '食事の好み';

  @override
  String get preferencesTitle => '食事の好み';

  @override
  String get preferencesSubtitle => 'レシピのパーソナライズに使用します';

  @override
  String get preferencesSectionDiet => '食事';

  @override
  String get preferencesSectionMedical => '医療';

  @override
  String get preferencesSectionAllergens => '避けたいアレルゲン';

  @override
  String get preferencesSectionIntolerances => '不耐性';

  @override
  String get preferencesSectionReligion => '宗教 / 文化';

  @override
  String get preferencesDisliked => '苦手な食材';

  @override
  String get preferencesAddIngredientPlaceholder => '食材を追加してEnterキーを押してください';

  @override
  String get preferencesSave => '設定を保存';

  @override
  String get preferencesClear => 'すべてクリア';

  @override
  String get preferencesSaved => '設定を保存しました';

  @override
  String get prefVegan => 'ヴィーガン';

  @override
  String get prefVegetarian => 'ベジタリアン';

  @override
  String get prefVegetarianOvo => 'ベジタリアン（オボ）';

  @override
  String get prefVegetarianLacto => 'ベジタリアン（ラクト）';

  @override
  String get prefVegetarianStrict => 'ベジタリアン（卵・乳製品なし）';

  @override
  String get prefPescetarian => 'ペスカタリアン';

  @override
  String get prefFlexitarian => 'フレキシタリアン';

  @override
  String get prefMediterranean => '地中海食';

  @override
  String get prefLowCarbKeto => '低炭水化物 / ケト';

  @override
  String get prefLowFat => '低脂肪';

  @override
  String get prefHighProtein => '高たんぱく';

  @override
  String get prefPaleo => 'パレオ';

  @override
  String get prefWholeFoods => 'ホールフード';

  @override
  String get prefNoUltraProcessed => '超加工食品なし';

  @override
  String get prefNoAlcohol => 'アルコールなし';

  @override
  String get prefSpicyLow => '辛さ控えめ';

  @override
  String get prefSpicyMedium => '中辛';

  @override
  String get prefSpicyHigh => '辛口';

  @override
  String get prefOrganic => 'オーガニック';

  @override
  String get prefGlutenFree => 'グルテンフリー';

  @override
  String get prefLowFodmap => '低FODMAP';

  @override
  String get prefLowSodium => '低ナトリウム';

  @override
  String get prefLowSugar => '低糖（糖尿病向け）';

  @override
  String get prefLowCholesterol => '低コレステロール';

  @override
  String get prefLowPurine => '低プリン体';

  @override
  String get prefLowOxalatePotassium => '低シュウ酸/カリウム';

  @override
  String get prefLactoseFree => '乳糖不耐';

  @override
  String get allergenGluten => 'グルテン';

  @override
  String get allergenCrustaceans => '甲殻類';

  @override
  String get allergenEggs => '卵';

  @override
  String get allergenFish => '魚';

  @override
  String get allergenPeanuts => 'ピーナッツ';

  @override
  String get allergenSoy => '大豆';

  @override
  String get allergenMilk => '乳';

  @override
  String get allergenTreeNuts => '木の実（ナッツ類）';

  @override
  String get allergenCelery => 'セロリ';

  @override
  String get allergenMustard => 'マスタード';

  @override
  String get allergenSesame => 'ごま';

  @override
  String get allergenSulphites => '亜硫酸塩';

  @override
  String get allergenLupin => 'ルピナス';

  @override
  String get allergenMolluscs => '軟体動物';

  @override
  String get prefHalal => 'ハラール';

  @override
  String get prefKosher => 'コーシャ';

  @override
  String get prefHindu => 'ヒンドゥー（牛肉を避けることが多い）';

  @override
  String get prefJain => 'ジャイナ（根菜なし・厳格な菜食）';

  @override
  String get prefBuddhist => '仏教（地域により異なる）';

  @override
  String get prefLentFasting => '四旬節/断食（一部の日は肉なし）';

  @override
  String get startCookingButton => '料理を開始';

  @override
  String get finalizeButton => '完了';

  @override
  String get cookingSheetTitle => 'レシピ完了！';

  @override
  String get cookingSheetTakePhotoShare => '写真を撮って共有';

  @override
  String get cookingSheetSaveRecipe => 'レシピを保存';

  @override
  String get cookingSheetGoHome => '閉じてホームへ';

  @override
  String get timerStartTooltip => '開始';

  @override
  String get timerPauseTooltip => '一時停止';

  @override
  String get timerResumeTooltip => '再開';

  @override
  String get timerDiscardTooltip => '破棄';

  @override
  String get timerDoneTitle => '時間です！';

  @override
  String get timerDoneBody => '調理のステップが終了しました。';

  @override
  String cookingNotificationTitle(String title) {
    return '調理中: $title';
  }

  @override
  String cookingOngoingBody(String step) {
    return 'ステップ $step • カウントダウン';
  }

  @override
  String shareCookedText(String title, String link) {
    return '\"$title\"を作りました！ アプリを試してね: $link';
  }
}
