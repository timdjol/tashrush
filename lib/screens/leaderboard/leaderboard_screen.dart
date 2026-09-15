import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../localization/app_localizations.dart';
import '../../services/leaderboard_service.dart';
import '../../utils/game_constants.dart';
import '../../widgets/rush_card.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  String _duration(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.personalResults)),
      body: FutureBuilder<List<LeaderboardEntry>>(
        future: AppServices.of(context).leaderboard.topScores(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data!;
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.history_rounded,
                      size: 58, color: RushPalette.gold),
                  const SizedBox(height: 16),
                  Text(l10n.noResults, textAlign: TextAlign.center),
                ]),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final date =
                  entry.playedAt?.toLocal().toIso8601String().substring(0, 10);
              final details = <String>[
                if (date != null) date,
                '${l10n.lines}: ${entry.lines}',
                '${l10n.time}: ${_duration(entry.durationSeconds)}',
              ];
              return RushCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        index < 3 ? RushPalette.gold : RushPalette.sand,
                    foregroundColor: RushPalette.ink,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    '${l10n.gameResult} ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(details.join(' · ')),
                  trailing: Text(
                    '${entry.score}',
                    style: const TextStyle(
                      color: RushPalette.coral,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
