import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../localization/app_localizations.dart';
import '../../services/leaderboard_service.dart';
import '../../utils/game_constants.dart';
import '../../widgets/rush_card.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.leaderboard)),
        body: FutureBuilder<List<LeaderboardEntry>>(
          future: AppServices.of(context).leaderboard.topScores(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final entries = snapshot.data!;
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => RushCard(
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
                    entries[index].name == 'You'
                        ? AppLocalizations.of(context)!.you
                        : entries[index].name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: Text('${entries[index].score}',
                      style: const TextStyle(
                          color: RushPalette.coral,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                ),
              ),
            );
          },
        ),
      );
}
