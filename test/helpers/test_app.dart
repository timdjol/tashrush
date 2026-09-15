import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tash_rush/app/app_services.dart';
import 'package:tash_rush/localization/app_localizations.dart';
import 'package:tash_rush/services/achievement_service.dart';
import 'package:tash_rush/services/ad_service.dart';
import 'package:tash_rush/services/analytics_service.dart';
import 'package:tash_rush/services/audio_service.dart';
import 'package:tash_rush/services/daily_challenge_service.dart';
import 'package:tash_rush/services/haptic_service.dart';
import 'package:tash_rush/services/leaderboard_service.dart';
import 'package:tash_rush/services/progression_service.dart';
import 'package:tash_rush/services/purchase_service.dart';
import 'package:tash_rush/services/settings_service.dart';
import 'package:tash_rush/services/storage_service.dart';

class TestConsentService implements ConsentService {
  const TestConsentService({this.allowed = false});
  final bool allowed;

  @override
  Future<bool> mayRequestAds() async => allowed;

  @override
  Future<bool> privacyOptionsRequired() async => false;

  @override
  Future<void> showPrivacyOptions() async {}
}

class TestAppServices {
  TestAppServices._({
    required this.storage,
    required this.analytics,
    required this.purchase,
    required this.ads,
    required this.leaderboard,
  });

  final StorageService storage;
  final AnalyticsService analytics;
  final PurchaseService purchase;
  final AdService ads;
  final LocalLeaderboardService leaderboard;

  static Future<TestAppServices> create({
    Map<String, Object> preferences = const {},
  }) async {
    SharedPreferences.setMockInitialValues(preferences);
    final storage = await StorageService.create();
    final analytics = AnalyticsService();
    final purchase = PlaceholderPurchaseService();
    return TestAppServices._(
      storage: storage,
      analytics: analytics,
      purchase: purchase,
      ads: AdService(
        analytics: analytics,
        consent: const TestConsentService(),
        storage: storage,
        purchase: purchase,
      ),
      leaderboard: LocalLeaderboardService(storage),
    );
  }

  Widget wrap(Widget child) {
    final audio = AudioService();
    return AppServices(
      storage: storage,
      settings: SettingsService(storage),
      analytics: analytics,
      ads: ads,
      audio: audio,
      haptics: HapticService(),
      daily: DailyChallengeService(storage),
      achievements: AchievementService(storage, analytics),
      leaderboard: leaderboard,
      purchase: purchase,
      progression: ProgressionService(storage),
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    );
  }
}
