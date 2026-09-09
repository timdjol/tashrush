abstract interface class PurchaseService {
  bool get adsRemoved;
  Future<void> purchaseRemoveAds();
  Future<void> restorePurchases();
}

class PlaceholderPurchaseService implements PurchaseService {
  @override
  bool get adsRemoved => false;
  @override
  Future<void> purchaseRemoveAds() async {}
  @override
  Future<void> restorePurchases() async {}
}
