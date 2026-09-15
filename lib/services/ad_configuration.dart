import 'dart:io';

import 'package:flutter/foundation.dart';

class AdConfiguration {
  const AdConfiguration();

  static const _allowTestAdsInRelease = bool.fromEnvironment('ALLOW_TEST_ADS');
  static const _androidRewarded =
      String.fromEnvironment('ADMOB_REWARDED_ANDROID');
  static const _iosRewarded = String.fromEnvironment('ADMOB_REWARDED_IOS');
  static const _androidInterstitial =
      String.fromEnvironment('ADMOB_INTERSTITIAL_ANDROID');
  static const _iosInterstitial =
      String.fromEnvironment('ADMOB_INTERSTITIAL_IOS');

  bool get usesTestAds => !kReleaseMode || _allowTestAdsInRelease;

  String? get rewardedId => _id(
        androidProduction: _androidRewarded,
        iosProduction: _iosRewarded,
        androidTest: 'ca-app-pub-3940256099942544/5224354917',
        iosTest: 'ca-app-pub-3940256099942544/1712485313',
      );

  String? get interstitialId => _id(
        androidProduction: _androidInterstitial,
        iosProduction: _iosInterstitial,
        androidTest: 'ca-app-pub-3940256099942544/1033173712',
        iosTest: 'ca-app-pub-3940256099942544/4411468910',
      );

  bool get isReady => rewardedId != null && interstitialId != null;

  String? _id({
    required String androidProduction,
    required String iosProduction,
    required String androidTest,
    required String iosTest,
  }) {
    if (usesTestAds) return Platform.isAndroid ? androidTest : iosTest;
    final production = Platform.isAndroid ? androidProduction : iosProduction;
    return production.trim().isEmpty ? null : production;
  }
}
