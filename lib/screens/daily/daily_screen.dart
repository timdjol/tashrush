import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../app/routes.dart';
import '../../localization/app_localizations.dart';
import '../../models/game_models.dart';
import '../../utils/game_constants.dart';
import '../../widgets/kyrgyz_pattern.dart';
import '../../widgets/rush_card.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  @override
  Widget build(BuildContext context) {
    final challenge = AppServices.of(context).daily.current();
    final l10n = AppLocalizations.of(context)!;
    final label = switch (challenge.type) {
      DailyGoalType.score => '${l10n.score}: ${challenge.target}',
      DailyGoalType.lines => '${l10n.lines}: ${challenge.target}',
      DailyGoalType.combo => '${l10n.combo}: ×${challenge.target}',
      DailyGoalType.specialCells =>
        '${l10n.specialBlocks}: ${challenge.target}',
    };
    final progress =
        (challenge.progress / challenge.target).clamp(0.0, 1.0).toDouble();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.dailyChallenge)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 36),
          const Center(child: TundukEmblem(size: 82)),
          const SizedBox(height: 12),
          const EthnoDivider(),
          const SizedBox(height: 24),
          RushCard(
              child: Column(children: [
            Text(challenge.dateKey,
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                color: RushPalette.coral,
                backgroundColor: RushPalette.sand,
                borderRadius: BorderRadius.circular(12)),
            const SizedBox(height: 8),
            Text('${challenge.progress} / ${challenge.target}'),
            if (challenge.completed)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(l10n.completed,
                      style: const TextStyle(
                          color: RushPalette.mint,
                          fontWeight: FontWeight.w800))),
          ])),
          const Spacer(),
          FilledButton.icon(
            onPressed: challenge.completed
                ? null
                : () async {
                    await Navigator.pushNamed(
                      context,
                      AppRoutes.game,
                      arguments: true,
                    );
                    if (mounted) setState(() {});
                  },
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(l10n.play),
          ),
        ]),
      ),
    );
  }
}
