import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tash_rush/services/ad_service.dart';
import 'package:tash_rush/services/analytics_service.dart';
import 'package:tash_rush/services/purchase_service.dart';
import 'package:tash_rush/services/storage_service.dart';

import 'helpers/test_app.dart';

void main() {
  test('ads remain unavailable when consent does not allow requests', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final ads = AdService(
      analytics: AnalyticsService(),
      consent: const TestConsentService(),
      storage: storage,
      purchase: PlaceholderPurchaseService(),
    );

    await ads.initializeAfterConsent();

    expect(ads.rewardedState.value, RewardedAdState.unavailable);
    expect(await ads.showRewarded(), isFalse);
    expect(storage.getInt('rewardedAdsOpened'), 0);
    ads.dispose();
  });
}
