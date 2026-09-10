import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../localization/app_localizations.dart';
import '../../services/achievement_service.dart';
import '../../utils/game_constants.dart';
import '../../widgets/rush_card.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final service = AppServices.of(context).achievements;
    final unlocked = service.unlocked;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.achievements)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: AchievementService.definitions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = AchievementService.definitions[index];
          final done = unlocked.contains(item.id);
          final progress = service.progressFor(item).clamp(0, item.target);
          final l10n = AppLocalizations.of(context)!;
          final title = switch (item.id) {
            'beginner' => l10n.achievementBeginner,
            'master' => l10n.achievementMaster,
            'combo_king' => l10n.achievementComboKing,
            'line_crusher' => l10n.achievementLineCrusher,
            _ => l10n.achievementVeteran,
          };
          final description = switch (item.metric) {
            'score' => l10n.scorePoints,
            'combo' => l10n.reachCombo,
            'lines' => l10n.clearLines,
            _ => l10n.playGames,
          };
          return RushCard(
              child: Row(children: [
            CircleAvatar(
                backgroundColor:
                    done ? RushPalette.sand : const Color(0xFFE8DED0),
                child: Icon(
                    done
                        ? Icons.emoji_events_rounded
                        : Icons.lock_outline_rounded,
                    color: done ? RushPalette.gold : const Color(0xFF8C7B72))),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                  Text('$description · $progress / ${item.target}'),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(
                    value: progress / item.target,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ])),
            if (done)
              const Icon(Icons.check_circle_rounded, color: RushPalette.mint),
          ]));
        },
      ),
    );
  }
}
