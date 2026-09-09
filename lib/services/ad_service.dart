import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'analytics_service.dart';
import 'purchase_service.dart';
import 'storage_service.dart';

abstract interface class ConsentService {
  Future<bool> mayRequestAds();
}

class DevelopmentConsentService implements ConsentService {
  @override
  Future<bool> mayRequestAds() async => !kReleaseMode;
}

class AdService {
  AdService({
    required this.analytics,
    required this.consent,
    required this.storage,
    required this.purchase,
  });
  final AnalyticsService analytics;
  final ConsentService consent;
  final StorageService storage;
  final PurchaseService purchase;
  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  bool _initialized = false;

  String get _rewardedId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';
  String get _interstitialId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  Future<void> initializeAfterConsent() async {
    if (_initialized || kIsWeb || !await consent.mayRequestAds()) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    _loadRewarded();
    _loadInterstitial();
  }

  void _loadRewarded() {
    unawaited(RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    ));
  }

  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    await analytics.event('rewarded_ad_opened');
    await storage.setInt(
        'rewardedAdsOpened', storage.getInt('rewardedAdsOpened') + 1);
    var earned = false;
    final completion = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (value) {
        value.dispose();
        if (!completion.isCompleted) completion.complete();
      },
      onAdFailedToShowFullScreenContent: (value, _) {
        value.dispose();
        if (!completion.isCompleted) completion.complete();
      },
    );
    try {
      await ad.show(onUserEarnedReward: (_, __) => earned = true);
    } catch (_) {
      ad.dispose();
      _rewarded = null;
      _loadRewarded();
      return false;
    }
    _rewarded = null;
    await completion.future;
    if (earned) {
      await analytics.event('rewarded_ad_completed');
      await storage.setInt(
        'rewardedAdsCompleted',
        storage.getInt('rewardedAdsCompleted') + 1,
      );
    }
    _loadRewarded();
    return earned;
  }

  Future<void> showInterstitial() async {
    if (purchase.adsRemoved || storage.getBool('adsRemoved')) return;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (value) {
        value.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (value, _) {
        value.dispose();
        _loadInterstitial();
      },
    );
    try {
      await ad.show();
    } catch (_) {
      ad.dispose();
      _interstitial = null;
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    await analytics.event('interstitial_shown');
    await storage.setInt(
      'interstitialAdsShown',
      storage.getInt('interstitialAdsShown') + 1,
    );
  }

  void _loadInterstitial() {
    unawaited(InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    ));
  }

  void dispose() {
    _rewarded?.dispose();
    _interstitial?.dispose();
  }
}
