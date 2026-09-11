import '../models/game_models.dart';
import 'analytics_service.dart';
import 'storage_service.dart';

class AchievementDefinition {
  const AchievementDefinition(this.id, this.target, this.metric);
  final String id;
  final int target;
  final String metric;
}

class AchievementService {
  AchievementService(this.storage, this.analytics, {this.onUnlocked});
  final StorageService storage;
  final AnalyticsService analytics;
  final Future<void> Function()? onUnlocked;
  static const definitions = [
    AchievementDefinition('beginner', 1000, 'score'),
    AchievementDefinition('master', 10000, 'score'),
    AchievementDefinition('combo_king', 10, 'combo'),
    AchievementDefinition('line_crusher', 1000, 'lines'),
    AchievementDefinition('veteran', 100, 'games'),
  ];
  Set<String> get unlocked => storage.getStringList('achievements').toSet();

  int progressFor(AchievementDefinition definition) =>
      switch (definition.metric) {
        'score' => storage.getInt('bestScore'),
        'combo' => storage.getInt('highestCombo'),
        'lines' => storage.getInt('totalLines'),
        'games' => storage.getInt('totalGames'),
        _ => 0,
      };

  Future<List<String>> evaluate(GameStats stats) async {
    final values = {
      'score': stats.score,
      'combo': stats.highestCombo,
      'lines': storage.getInt('totalLines'),
      'games': storage.getInt('totalGames')
    };
    final result = unlocked;
    final newlyUnlocked = <String>[];
    for (final definition in definitions) {
      if ((values[definition.metric] ?? 0) >= definition.target &&
          result.add(definition.id)) {
        newlyUnlocked.add(definition.id);
        await analytics
            .event('achievement_unlocked', {'achievement_id': definition.id});
        await onUnlocked?.call();
      }
    }
    await storage.setStringList('achievements', result.toList());
    return newlyUnlocked;
  }
}
