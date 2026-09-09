import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/routes.dart';
import '../../localization/app_localizations.dart';
import '../../widgets/menu_button.dart';
import '../../widgets/kyrgyz_pattern.dart';
import '../../widgets/rush_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final storage = AppServices.of(context).storage;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 12),
            Center(
              child: Image.asset(
                'assets/branding/tash_rush_logo.png',
                height: 190,
                filterQuality: FilterQuality.high,
                semanticLabel: l10n.appTitle,
              ),
            ),
            const SizedBox(height: 12),
            const EthnoDivider(),
            const SizedBox(height: 24),
            RushCard(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                  _Metric(
                      label: l10n.best,
                      value: '${storage.getInt('bestScore')}'),
                  _Metric(
                      label: l10n.dailyStreak,
                      value: '${storage.getInt('dailyStreak')}'),
                ])),
            const SizedBox(height: 24),
            FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.game),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.play)),
            const SizedBox(height: 12),
            MenuButton(
                icon: Icons.today_rounded,
                label: l10n.dailyChallenge,
                onTap: () => Navigator.pushNamed(context, AppRoutes.daily)),
            MenuButton(
                icon: Icons.emoji_events_rounded,
                label: l10n.achievements,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.achievements)),
            MenuButton(
                icon: Icons.leaderboard_rounded,
                label: l10n.leaderboard,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.leaderboard)),
            MenuButton(
                icon: Icons.settings_rounded,
                label: l10n.settings,
                onTap: () => Navigator.pushNamed(context, AppRoutes.settings)),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.removeAds),
              child: Text(l10n.removeAds),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        Text(label)
      ]);
}
