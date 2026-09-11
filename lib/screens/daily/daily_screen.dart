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
    final services = AppServices.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final daily = services.daily;
    final challenge = daily.current();
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
          _StreakCalendar(
            completedDates: daily.completedDates,
            today: DateTime.now(),
          ),
          const SizedBox(height: 16),
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
            if (challenge.completed && daily.rewardClaimed(challenge))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('✓ ${l10n.rewardClaimed}'),
              ),
          ])),
          const Spacer(),
          FilledButton.icon(
            onPressed: challenge.completed
                ? (daily.rewardClaimed(challenge)
                    ? null
                    : () async {
                        final reward = await daily.claimReward(challenge);
                        services.progression.refresh();
                        await services.audio.play('achievement');
                        await services.haptics.medium();
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(content: Text('+ $reward ${l10n.coins}')),
                        );
                        setState(() {});
                      })
                : () async {
                    await Navigator.pushNamed(
                      context,
                      AppRoutes.game,
                      arguments: true,
                    );
                    if (mounted) setState(() {});
                  },
            icon: Icon(challenge.completed
                ? Icons.card_giftcard_rounded
                : Icons.play_arrow_rounded),
            label: Text(challenge.completed
                ? '${l10n.claimReward} · ${daily.rewardFor(challenge)}'
                : l10n.play),
          ),
        ]),
      ),
    );
  }
}

class _StreakCalendar extends StatelessWidget {
  const _StreakCalendar({
    required this.completedDates,
    required this.today,
  });
  final Set<String> completedDates;
  final DateTime today;

  String _key(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
    );
    return RushCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final day in days)
            Column(children: [
              Text('${day.day}', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 5),
              CircleAvatar(
                radius: 15,
                backgroundColor: completedDates.contains(_key(day))
                    ? RushPalette.mint
                    : RushPalette.sand,
                child: Icon(
                  completedDates.contains(_key(day))
                      ? Icons.check_rounded
                      : Icons.circle_outlined,
                  size: 16,
                  color: completedDates.contains(_key(day))
                      ? Colors.white
                      : RushPalette.gold,
                ),
              ),
            ]),
        ],
      ),
    );
  }
}
