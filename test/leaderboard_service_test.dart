import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tash_rush/services/leaderboard_service.dart';
import 'package:tash_rush/services/storage_service.dart';

void main() {
  test('local leaderboard contains only submitted personal results', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final leaderboard = LocalLeaderboardService(storage);

    await leaderboard.submit(1200, lines: 4, durationSeconds: 70);
    await leaderboard.submit(800, lines: 2, durationSeconds: 45);
    final results = await leaderboard.topScores();

    expect(results.map((entry) => entry.score), [1200, 800]);
    expect(results.first.lines, 4);
    expect(results.first.durationSeconds, 70);
    expect(storage.getInt('bestScore'), 1200);
  });
}
