import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tash_rush/models/game_models.dart';
import 'package:tash_rush/services/daily_challenge_service.dart';
import 'package:tash_rush/services/storage_service.dart';

void main() {
  test('daily reward can only be claimed once', () async {
    SharedPreferences.setMockInitialValues({'dailyStreak': 3});
    final storage = await StorageService.create();
    final service = DailyChallengeService(storage);
    const challenge = DailyChallenge(
      dateKey: '2026-09-11',
      type: DailyGoalType.lines,
      target: 12,
      progress: 12,
      completed: true,
    );

    expect(await service.claimReward(challenge), 130);
    expect(storage.getInt('coins'), 130);
    expect(await service.claimReward(challenge), 0);
    expect(storage.getInt('coins'), 130);
  });

  test('completed daily dates are unique', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final service = DailyChallengeService(storage);

    await service.markCompleted('2026-09-11');
    await service.markCompleted('2026-09-11');

    expect(service.completedDates, {'2026-09-11'});
  });
}
