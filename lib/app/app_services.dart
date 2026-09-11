import 'package:flutter/widgets.dart';

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

class AppServices extends InheritedWidget {
  const AppServices({
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
    required super.child,
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

  static AppServices of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppServices>()!;
  @override
  bool updateShouldNotify(AppServices oldWidget) =>
      settings != oldWidget.settings || progression != oldWidget.progression;
}
