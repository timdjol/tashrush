import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../localization/app_localizations.dart';
import '../../services/purchase_service.dart';
import '../../utils/game_constants.dart';
import '../../widgets/rush_card.dart';

class RemoveAdsScreen extends StatelessWidget {
  const RemoveAdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final purchase = AppServices.of(context).purchase;
    return AnimatedBuilder(
      animation: purchase,
      builder: (context, _) {
        final state = purchase.state;
        final purchased = purchase.adsRemoved;
        final price = purchase.price ?? r'$2.99';
        return Scaffold(
          appBar: AppBar(title: Text(l10n.removeAdsShort)),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                RushCard(
                  child: Column(
                    children: [
                      Icon(
                        purchased
                            ? Icons.verified_user_rounded
                            : Icons.shield_rounded,
                        size: 76,
                        color:
                            purchased ? RushPalette.gold : RushPalette.violet,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        purchased
                            ? l10n.adsRemoved
                            : '${l10n.removeAdsShort} — $price',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        purchased
                            ? l10n.purchaseThankYou
                            : l10n.removeAdsBenefit,
                        textAlign: TextAlign.center,
                      ),
                      if (state == PurchaseState.pending) ...[
                        const SizedBox(height: 18),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(l10n.purchasePending),
                      ],
                      if (state == PurchaseState.error) ...[
                        const SizedBox(height: 16),
                        Text(
                          l10n.purchaseFailed,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: RushPalette.coral),
                        ),
                      ],
                      if (state == PurchaseState.unavailable && !purchased) ...[
                        const SizedBox(height: 16),
                        Text(l10n.purchaseUnavailable,
                            textAlign: TextAlign.center),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                if (!purchased)
                  FilledButton(
                    onPressed: state == PurchaseState.ready ||
                            state == PurchaseState.error
                        ? purchase.purchaseRemoveAds
                        : null,
                    child: Text('${l10n.buyNow} — $price'),
                  ),
                TextButton(
                  onPressed: state == PurchaseState.pending
                      ? null
                      : purchase.restorePurchases,
                  child: Text(l10n.restorePurchases),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
