import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'analytics_service.dart';
import 'ad_configuration.dart';
import 'purchase_service.dart';
import 'storage_service.dart';

abstract interface class ConsentService {
  Future<bool> mayRequestAds();
  Future<bool> privacyOptionsRequired();
  Future<void> showPrivacyOptions();
}

enum RewardedAdState { unavailable, loading, ready }

class DevelopmentConsentService implements ConsentService {
  static const _allowTestAdsInRelease = bool.fromEnvironment('ALLOW_TEST_ADS');

  @override
  Future<bool> mayRequestAds() async => !kReleaseMode || _allowTestAdsInRelease;

  @override
  Future<bool> privacyOptionsRequired() async => false;

  @override
  Future<void> showPrivacyOptions() async {}
}

class UmpConsentService implements ConsentService {
  @override
  Future<bool> mayRequestAds() async {
    try {
      final update = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        update.complete,
        (_) => update.complete(),
      );
      await update.future;
      final form = Completer<void>();
      await ConsentForm.loadAndShowConsentFormIfRequired(
          (_) => form.complete());
      await form.future;
      return await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> privacyOptionsRequired() async {
    try {
      return await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> showPrivacyOptions() async {
    final completion = Completer<void>();
    await ConsentForm.showPrivacyOptionsForm((_) => completion.complete());
    await completion.future;
  }
}

class AdService {
  AdService({
    required this.analytics,
    required this.consent,
    required this.storage,
    required this.purchase,
    this.configuration = const AdConfiguration(),
  });
  final AnalyticsService analytics;
  final ConsentService consent;
  final StorageService storage;
  final PurchaseService purchase;
  final AdConfiguration configuration;
  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  bool _initialized = false;
  final ValueNotifier<RewardedAdState> rewardedState =
      ValueNotifier(RewardedAdState.unavailable);

  Future<void> initializeAfterConsent() async {
    if (_initialized || kIsWeb) return;
    if (!configuration.isReady) {
      rewardedState.value = RewardedAdState.unavailable;
      return;
    }
    if (!await consent.mayRequestAds()) {
      rewardedState.value = RewardedAdState.unavailable;
      return;
    }
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadRewarded();
      _loadInterstitial();
    } catch (_) {
      rewardedState.value = RewardedAdState.unavailable;
    }
  }

  void _loadRewarded() {
    final adUnitId = configuration.rewardedId;
    if (!_initialized ||
        adUnitId == null ||
        rewardedState.value == RewardedAdState.loading ||
        _rewarded != null) {
      return;
    }
    rewardedState.value = RewardedAdState.loading;
    unawaited(RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          rewardedState.value = RewardedAdState.ready;
        },
        onAdFailedToLoad: (_) {
          _rewarded = null;
          rewardedState.value = RewardedAdState.unavailable;
        },
      ),
    ));
  }

  void retryRewarded() {
    if (_initialized) {
      _loadRewarded();
    } else {
      unawaited(initializeAfterConsent());
    }
  }

  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      retryRewarded();
      return false;
    }
    _rewarded = null;
    rewardedState.value = RewardedAdState.unavailable;
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
      _loadRewarded();
      return false;
    }
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
    final adUnitId = configuration.interstitialId;
    if (!_initialized || adUnitId == null || _interstitial != null) return;
    unawaited(InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    ));
  }

  Future<bool> privacyOptionsRequired() => consent.privacyOptionsRequired();

  Future<void> showPrivacyOptions() => consent.showPrivacyOptions();

  void dispose() {
    _rewarded?.dispose();
    _interstitial?.dispose();
    rewardedState.dispose();
  }
}
