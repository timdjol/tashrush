import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'storage_service.dart';

enum PurchaseState { loading, ready, pending, purchased, unavailable, error }

abstract class PurchaseService extends ChangeNotifier {
  bool get adsRemoved;
  PurchaseState get state;
  String? get price;
  String? get errorMessage;
  Future<void> initialize();
  Future<void> purchaseRemoveAds();
  Future<void> restorePurchases();
}

abstract interface class PurchaseVerifier {
  Future<bool> verify(PurchaseDetails purchase, String expectedProductId);
}

class LocalReceiptVerifier implements PurchaseVerifier {
  const LocalReceiptVerifier();

  @override
  Future<bool> verify(
    PurchaseDetails purchase,
    String expectedProductId,
  ) async =>
      purchase.productID == expectedProductId &&
      purchase.verificationData.serverVerificationData.isNotEmpty;
}

class StorePurchaseService extends PurchaseService {
  StorePurchaseService(
    this._storage, {
    InAppPurchase? store,
    PurchaseVerifier verifier = const LocalReceiptVerifier(),
    String productId = const String.fromEnvironment(
      'REMOVE_ADS_PRODUCT_ID',
      defaultValue: 'tash_rush_remove_ads',
    ),
  })  : _store = store ?? InAppPurchase.instance,
        _verifier = verifier,
        _productId = productId {
    _subscription = _store.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error, StackTrace stack) => _setError(error.toString()),
    );
  }

  final StorageService _storage;
  final InAppPurchase _store;
  final PurchaseVerifier _verifier;
  final String _productId;
  late final StreamSubscription<List<PurchaseDetails>> _subscription;
  ProductDetails? _product;
  PurchaseState _state = PurchaseState.loading;
  String? _errorMessage;

  @override
  bool get adsRemoved => _storage.getBool('adsRemoved');
  @override
  PurchaseState get state => adsRemoved ? PurchaseState.purchased : _state;
  @override
  String? get price => _product?.price;
  @override
  String? get errorMessage => _errorMessage;

  @override
  Future<void> initialize() async {
    try {
      if (!await _store.isAvailable()) {
        _state = PurchaseState.unavailable;
        notifyListeners();
        return;
      }
      final response = await _store.queryProductDetails({_productId});
      if (response.error != null) {
        _setError(response.error!.message);
        return;
      }
      if (response.productDetails.isEmpty) {
        _state = PurchaseState.unavailable;
        _errorMessage = 'Product $_productId is not configured in the store.';
      } else {
        _product = response.productDetails.first;
        _state = adsRemoved ? PurchaseState.purchased : PurchaseState.ready;
        _errorMessage = null;
      }
      notifyListeners();
    } catch (error) {
      _setError(error.toString());
    }
  }

  @override
  Future<void> purchaseRemoveAds() async {
    final product = _product;
    if (adsRemoved || product == null || _state == PurchaseState.pending) {
      return;
    }
    _state = PurchaseState.pending;
    _errorMessage = null;
    notifyListeners();
    try {
      final started = await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) _setError('The store did not start the purchase.');
    } catch (error) {
      _setError(error.toString());
    }
  }

  @override
  Future<void> restorePurchases() async {
    if (_state == PurchaseState.pending) return;
    _state = PurchaseState.pending;
    _errorMessage = null;
    notifyListeners();
    try {
      await _store.restorePurchases();
      if (!adsRemoved && _state == PurchaseState.pending) {
        _state = PurchaseState.ready;
        notifyListeners();
      }
    } catch (error) {
      _setError(error.toString());
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    var matched = false;
    for (final purchase in purchases) {
      if (purchase.productID != _productId) continue;
      matched = true;
      if (purchase.status == PurchaseStatus.pending) {
        _state = PurchaseState.pending;
        notifyListeners();
        continue;
      }
      if (purchase.status == PurchaseStatus.error) {
        _setError(purchase.error?.message ?? 'Purchase failed.');
        continue;
      }
      if (purchase.status == PurchaseStatus.canceled) {
        _state = PurchaseState.ready;
        notifyListeners();
        continue;
      }
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final verified = await _verifier.verify(purchase, _productId);
        if (!verified) {
          _setError('The purchase receipt could not be verified.');
          continue;
        }
        await _storage.setBool('adsRemoved', true);
        _state = PurchaseState.purchased;
        _errorMessage = null;
        notifyListeners();
        if (purchase.pendingCompletePurchase) {
          await _store.completePurchase(purchase);
        }
      }
    }
    if (!matched && _state == PurchaseState.pending) {
      _state = adsRemoved ? PurchaseState.purchased : PurchaseState.ready;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _state = PurchaseState.error;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

class PlaceholderPurchaseService extends PurchaseService {
  PlaceholderPurchaseService({this.removed = false});
  final bool removed;

  @override
  bool get adsRemoved => removed;
  @override
  PurchaseState get state =>
      removed ? PurchaseState.purchased : PurchaseState.unavailable;
  @override
  String? get price => null;
  @override
  String? get errorMessage => null;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> purchaseRemoveAds() async {}
  @override
  Future<void> restorePurchases() async {}
}
