import 'dart:async';
import 'dart:math';

import '../models/game_models.dart';
import 'storage_service.dart';

class DailyChallengeService {
  DailyChallengeService(this._storage);
  final StorageService _storage;

  String dateKey([DateTime? value]) {
    final date = value ?? DateTime.now();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DailyChallenge current([DateTime? date]) {
    final key = dateKey(date);
    final saved = _storage.getJson('daily_challenge');
    if (saved != null && saved['date'] == key) {
      return DailyChallenge(
        dateKey: key,
        type: DailyGoalType.values.byName(saved['type']! as String),
        target: (saved['target']! as num).toInt(),
        progress: (saved['progress']! as num).toInt(),
        completed: saved['completed']! as bool,
      );
    }
    final seed = int.parse(key.replaceAll('-', ''));
    final random = Random(seed);
    final type =
        DailyGoalType.values[random.nextInt(DailyGoalType.values.length)];
    final difficulty = random.nextInt(3);
    final target = switch (type) {
      DailyGoalType.score => [3000, 5000, 8000][difficulty],
      DailyGoalType.lines => [12, 20, 30][difficulty],
      DailyGoalType.combo => [3, 5, 7][difficulty],
      DailyGoalType.specialCells => [5, 10, 15][difficulty],
    };
    final challenge = DailyChallenge(dateKey: key, type: type, target: target);
    unawaited(save(challenge));
    return challenge;
  }

  Future<void> save(DailyChallenge challenge) =>
      _storage.setJson('daily_challenge', {
        'date': challenge.dateKey,
        'type': challenge.type.name,
        'target': challenge.target,
        'progress': challenge.progress,
        'completed': challenge.completed,
      });

  Set<String> get completedDates =>
      _storage.getStringList('dailyCompletedDates').toSet();

  Future<void> markCompleted(String date) async {
    final dates = {...completedDates, date}.toList();
    dates.sort();
    final recent = dates.length > 60 ? dates.sublist(dates.length - 60) : dates;
    await _storage.setStringList(
      'dailyCompletedDates',
      recent,
    );
  }

  bool rewardClaimed(DailyChallenge challenge) =>
      _storage.getBool('dailyReward_${challenge.dateKey}');

  int rewardFor(DailyChallenge challenge) =>
      100 + (_storage.getInt('dailyStreak').clamp(0, 10) * 10);

  Future<int> claimReward(DailyChallenge challenge) async {
    if (!challenge.completed || rewardClaimed(challenge)) return 0;
    final reward = rewardFor(challenge);
    await Future.wait([
      _storage.setBool('dailyReward_${challenge.dateKey}', true),
      _storage.setInt('coins', _storage.getInt('coins') + reward),
    ]);
    return reward;
  }
}
