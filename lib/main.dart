import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'services/achievement_service.dart';
import 'services/ad_service.dart';
import 'services/analytics_service.dart';
import 'services/audio_service.dart';
import 'services/booster_service.dart';
import 'services/daily_challenge_service.dart';
import 'services/haptic_service.dart';
import 'services/leaderboard_service.dart';
import 'services/notification_service.dart';
import 'services/purchase_service.dart';
import 'services/progression_service.dart';
import 'services/settings_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.create();
  FirebaseAnalytics? firebaseAnalytics;
  try {
    await Firebase.initializeApp();
    firebaseAnalytics = FirebaseAnalytics.instance;
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (_) {
    // Development works without credentials; production setup is documented.
  }
  final analytics = AnalyticsService(analytics: firebaseAnalytics);
  final audio = AudioService();
  await audio.initialize();
  final purchase = StorePurchaseService(storage);
  await purchase.initialize();
  final settings = SettingsService(storage);
  final notifications = NotificationService(FlutterNotificationGateway());
  try {
    await notifications.initialize();
    if (settings.value.notifications) {
      await notifications.setEnabled(
        true,
        settings.value.locale.languageCode,
        requestPermission: false,
      );
    }
  } catch (_) {
    // Notifications stay optional if platform scheduling is unavailable.
  }
  const allowReleaseTestAds = bool.fromEnvironment('ALLOW_TEST_ADS');
  final ads = AdService(
    analytics: analytics,
    consent: kReleaseMode && !allowReleaseTestAds
        ? UmpConsentService()
        : DevelopmentConsentService(),
    storage: storage,
    purchase: purchase,
  );
  unawaited(ads.initializeAfterConsent());
  runApp(TashRushApp(
    storage: storage,
    settings: settings,
    analytics: analytics,
    ads: ads,
    audio: audio,
    boosters: BoosterService(storage),
    haptics: HapticService(),
    daily: DailyChallengeService(storage),
    achievements: AchievementService(
      storage,
      analytics,
      onUnlocked: () => audio.play('achievement'),
    ),
    leaderboard: LocalLeaderboardService(storage),
    notifications: notifications,
    purchase: purchase,
    progression: ProgressionService(storage),
  ));
}
