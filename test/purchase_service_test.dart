import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:tash_rush/services/purchase_service.dart';

PurchaseDetails purchase(String productId, String receipt) => PurchaseDetails(
      productID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: receipt,
        serverVerificationData: receipt,
        source: 'test',
      ),
      transactionDate: '1',
      status: PurchaseStatus.purchased,
    );

void main() {
  const verifier = LocalReceiptVerifier();

  test('receipt verifier accepts only the configured product with a receipt',
      () async {
    expect(
      await verifier.verify(
          purchase('tash_rush_remove_ads', 'receipt'), 'tash_rush_remove_ads'),
      isTrue,
    );
    expect(
      await verifier.verify(
          purchase('another_product', 'receipt'), 'tash_rush_remove_ads'),
      isFalse,
    );
    expect(
      await verifier.verify(
          purchase('tash_rush_remove_ads', ''), 'tash_rush_remove_ads'),
      isFalse,
    );
  });
}
