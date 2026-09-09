import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../localization/app_localizations.dart';
import '../../utils/game_constants.dart';
import '../../widgets/rush_card.dart';

class RemoveAdsScreen extends StatelessWidget {
  const RemoveAdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final purchase = AppServices.of(context).purchase;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.removeAds)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            RushCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.shield_rounded,
                    size: 76,
                    color: RushPalette.violet,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.removeAds,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(l10n.comingSoon),
                ],
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () async {
                await purchase.purchaseRemoveAds();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.comingSoon)),
                );
              },
              child: Text(l10n.removeAds),
            ),
          ],
        ),
      ),
    );
  }
}
