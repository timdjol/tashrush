import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ky.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ky'),
    Locale('ru')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Tash Rush'**
  String get appTitle;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @dailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge'**
  String get dailyChallenge;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @best.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get best;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @combo.
  ///
  /// In en, this message translates to:
  /// **'Combo'**
  String get combo;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameOver;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @removeAds.
  ///
  /// In en, this message translates to:
  /// **'Remove Ads — \$2.99'**
  String get removeAds;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @soundVolume.
  ///
  /// In en, this message translates to:
  /// **'Effects volume'**
  String get soundVolume;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @musicVolume.
  ///
  /// In en, this message translates to:
  /// **'Music volume'**
  String get musicVolume;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @lines.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get lines;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @highestCombo.
  ///
  /// In en, this message translates to:
  /// **'Highest Combo'**
  String get highestCombo;

  /// No description provided for @dailyStreak.
  ///
  /// In en, this message translates to:
  /// **'Daily streak'**
  String get dailyStreak;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @specialBlocks.
  ///
  /// In en, this message translates to:
  /// **'Special blocks'**
  String get specialBlocks;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @adNotReady.
  ///
  /// In en, this message translates to:
  /// **'Rewarded ad is not ready. Try again soon.'**
  String get adNotReady;

  /// No description provided for @adLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading ad…'**
  String get adLoading;

  /// No description provided for @retryAd.
  ///
  /// In en, this message translates to:
  /// **'Retry ad'**
  String get retryAd;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @achievementBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get achievementBeginner;

  /// No description provided for @achievementMaster.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get achievementMaster;

  /// No description provided for @achievementComboKing.
  ///
  /// In en, this message translates to:
  /// **'Combo King'**
  String get achievementComboKing;

  /// No description provided for @achievementLineCrusher.
  ///
  /// In en, this message translates to:
  /// **'Line Crusher'**
  String get achievementLineCrusher;

  /// No description provided for @achievementVeteran.
  ///
  /// In en, this message translates to:
  /// **'Veteran'**
  String get achievementVeteran;

  /// No description provided for @scorePoints.
  ///
  /// In en, this message translates to:
  /// **'Score points'**
  String get scorePoints;

  /// No description provided for @reachCombo.
  ///
  /// In en, this message translates to:
  /// **'Reach combo'**
  String get reachCombo;

  /// No description provided for @clearLines.
  ///
  /// In en, this message translates to:
  /// **'Clear lines'**
  String get clearLines;

  /// No description provided for @playGames.
  ///
  /// In en, this message translates to:
  /// **'Play games'**
  String get playGames;

  /// No description provided for @tutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get tutorialTitle;

  /// No description provided for @tutorialDrag.
  ///
  /// In en, this message translates to:
  /// **'Drag a piece onto free cells. It floats above your finger for a clear view.'**
  String get tutorialDrag;

  /// No description provided for @tutorialClear.
  ///
  /// In en, this message translates to:
  /// **'Fill a complete row or column to clear it and build a combo.'**
  String get tutorialClear;

  /// No description provided for @tutorialSpecials.
  ///
  /// In en, this message translates to:
  /// **'Frozen cells need two hits. Bombs clear 3×3. Gold gives bonus points.'**
  String get tutorialSpecials;

  /// No description provided for @tutorialStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s rush!'**
  String get tutorialStart;

  /// No description provided for @coins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get coins;

  /// No description provided for @claimReward.
  ///
  /// In en, this message translates to:
  /// **'Claim reward'**
  String get claimReward;

  /// No description provided for @rewardClaimed.
  ///
  /// In en, this message translates to:
  /// **'Reward claimed'**
  String get rewardClaimed;

  /// No description provided for @journeyThemes.
  ///
  /// In en, this message translates to:
  /// **'Journey themes'**
  String get journeyThemes;

  /// No description provided for @themeAlaToo.
  ///
  /// In en, this message translates to:
  /// **'Ala-Too'**
  String get themeAlaToo;

  /// No description provided for @themeIssykKul.
  ///
  /// In en, this message translates to:
  /// **'Issyk-Kul'**
  String get themeIssykKul;

  /// No description provided for @themeOsh.
  ///
  /// In en, this message translates to:
  /// **'Osh warmth'**
  String get themeOsh;

  /// No description provided for @unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// No description provided for @achievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement unlocked!'**
  String get achievementUnlocked;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ky', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ky':
      return AppLocalizationsKy();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
