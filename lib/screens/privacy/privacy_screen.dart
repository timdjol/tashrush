import 'package:flutter/material.dart';

import '../../localization/app_localizations.dart';
import '../../utils/game_constants.dart';
import '../../widgets/kyrgyz_pattern.dart';
import '../../widgets/rush_card.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sections = [
      (
        Icons.phone_android_rounded,
        l10n.privacyLocalTitle,
        l10n.privacyLocalBody
      ),
      (
        Icons.analytics_outlined,
        l10n.privacyAnalyticsTitle,
        l10n.privacyAnalyticsBody
      ),
      (Icons.ads_click_rounded, l10n.privacyAdsTitle, l10n.privacyAdsBody),
      (Icons.tune_rounded, l10n.privacyControlTitle, l10n.privacyControlBody),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPolicy)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Center(child: TundukEmblem(size: 72)),
          const SizedBox(height: 8),
          const EthnoDivider(),
          const SizedBox(height: 18),
          for (final section in sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RushCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(section.$1, color: RushPalette.coral),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(section.$2,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(section.$3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Text(l10n.privacyDraftNotice,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
