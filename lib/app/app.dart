import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../localization/app_localizations.dart';
import '../screens/achievements/achievements_screen.dart';
import '../screens/daily/daily_screen.dart';
import '../screens/game/game_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/leaderboard/leaderboard_screen.dart';
import '../screens/remove_ads/remove_ads_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../services/achievement_service.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import '../services/audio_service.dart';
import '../services/daily_challenge_service.dart';
import '../services/haptic_service.dart';
import '../services/leaderboard_service.dart';
import '../services/purchase_service.dart';
import '../services/progression_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../utils/game_constants.dart';
import '../widgets/kyrgyz_pattern.dart';
import 'app_services.dart';
import 'routes.dart';

class TashRushApp extends StatefulWidget {
  const TashRushApp({
    required this.storage,
    required this.settings,
    required this.analytics,
    required this.ads,
    required this.audio,
    required this.haptics,
    required this.daily,
    required this.achievements,
    required this.leaderboard,
    required this.purchase,
    required this.progression,
    super.key,
  });
  final StorageService storage;
  final SettingsService settings;
  final AnalyticsService analytics;
  final AdService ads;
  final AudioService audio;
  final HapticService haptics;
  final DailyChallengeService daily;
  final AchievementService achievements;
  final LeaderboardService leaderboard;
  final PurchaseService purchase;
  final ProgressionService progression;

  @override
  State<TashRushApp> createState() => _TashRushAppState();
}

class _TashRushAppState extends State<TashRushApp> with WidgetsBindingObserver {
  StorageService get storage => widget.storage;
  SettingsService get settings => widget.settings;
  AnalyticsService get analytics => widget.analytics;
  AdService get ads => widget.ads;
  AudioService get audio => widget.audio;
  HapticService get haptics => widget.haptics;
  DailyChallengeService get daily => widget.daily;
  AchievementService get achievements => widget.achievements;
  LeaderboardService get leaderboard => widget.leaderboard;
  PurchaseService get purchase => widget.purchase;
  ProgressionService get progression => widget.progression;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(audio.resumeAfterLifecycle());
    } else {
      unawaited(audio.pauseForLifecycle());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppServices(
        storage: storage,
        settings: settings,
        analytics: analytics,
        ads: ads,
        audio: audio,
        haptics: haptics,
        daily: daily,
        achievements: achievements,
        leaderboard: leaderboard,
        purchase: purchase,
        progression: progression,
        child: AnimatedBuilder(
          animation: Listenable.merge([settings, progression]),
          builder: (context, _) {
            final journeyTheme = progression.selected;
            audio.enabled = settings.value.sound;
            audio.musicEnabled = settings.value.music;
            audio.effectsVolume = settings.value.soundVolume;
            audio.musicVolume = settings.value.musicVolume;
            unawaited(audio.syncMusicPreference());
            haptics.enabled = settings.value.vibration;
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Tash Rush',
              locale: settings.value.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: ThemeData(
                useMaterial3: true,
                scaffoldBackgroundColor: Colors.transparent,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: journeyTheme.accent,
                  primary: journeyTheme.accent,
                  secondary: RushPalette.gold,
                  surface: RushPalette.surface,
                  brightness: Brightness.light,
                ),
                textTheme: ThemeData.light().textTheme.apply(
                      bodyColor: RushPalette.ink,
                      displayColor: RushPalette.ink,
                    ),
                appBarTheme: const AppBarTheme(
                  centerTitle: true,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  backgroundColor: Colors.transparent,
                  foregroundColor: RushPalette.ink,
                  titleTextStyle: TextStyle(
                    color: RushPalette.ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .3,
                  ),
                ),
                dialogTheme: DialogThemeData(
                  backgroundColor: RushPalette.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: const BorderSide(
                      color: RushPalette.gold,
                      width: 1.5,
                    ),
                  ),
                ),
                bottomSheetTheme: const BottomSheetThemeData(
                  backgroundColor: RushPalette.surface,
                  surfaceTintColor: Colors.transparent,
                ),
                listTileTheme: const ListTileThemeData(
                  iconColor: RushPalette.coral,
                  textColor: RushPalette.ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                  ),
                ),
                switchTheme: SwitchThemeData(
                  thumbColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? RushPalette.gold
                        : RushPalette.surface,
                  ),
                  trackColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? RushPalette.coral
                        : const Color(0xFFD8C9B8),
                  ),
                ),
                snackBarTheme: const SnackBarThemeData(
                  backgroundColor: RushPalette.ink,
                  contentTextStyle: TextStyle(color: RushPalette.surface),
                  behavior: SnackBarBehavior.floating,
                ),
                filledButtonTheme: FilledButtonThemeData(
                  style: FilledButton.styleFrom(
                    backgroundColor: RushPalette.coral,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(
                        color: RushPalette.gold,
                        width: 1.2,
                      ),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .25,
                    ),
                  ),
                ),
              ),
              builder: (context, child) => KyrgyzPatternBackground(
                canvasColor: journeyTheme.canvas,
                sandColor: journeyTheme.sand,
                accentColor: journeyTheme.accent,
                child: child ?? const SizedBox.shrink(),
              ),
              routes: {
                AppRoutes.home: (_) => const HomeScreen(),
                AppRoutes.game: (_) => const GameScreen(),
                AppRoutes.daily: (_) => const DailyScreen(),
                AppRoutes.achievements: (_) => const AchievementsScreen(),
                AppRoutes.leaderboard: (_) => const LeaderboardScreen(),
                AppRoutes.settings: (_) => const SettingsScreen(),
                AppRoutes.removeAds: (_) => const RemoveAdsScreen(),
              },
            );
          },
        ),
      );
}
