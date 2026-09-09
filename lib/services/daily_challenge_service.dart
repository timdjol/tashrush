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
    final random = Random(key.hashCode);
    final type =
        DailyGoalType.values[random.nextInt(DailyGoalType.values.length)];
    final target = switch (type) {
      DailyGoalType.score => 5000,
      DailyGoalType.lines => 20,
      DailyGoalType.combo => 5,
      DailyGoalType.specialCells => 10,
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
}
