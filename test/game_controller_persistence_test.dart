import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tash_rush/game/pieces/piece.dart';
import 'package:tash_rush/models/game_models.dart';
import 'package:tash_rush/screens/game/game_controller.dart';
import 'package:tash_rush/services/achievement_service.dart';
import 'package:tash_rush/services/analytics_service.dart';
import 'package:tash_rush/services/daily_challenge_service.dart';
import 'package:tash_rush/services/leaderboard_service.dart';
import 'package:tash_rush/services/storage_service.dart';

void main() {
  test('classic game resumes from the last persisted move', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final analytics = AnalyticsService();
    final daily = DailyChallengeService(storage);

    GameController createController() => GameController(
          storage: storage,
          analytics: analytics,
          achievements: AchievementService(storage, analytics),
          leaderboard: LocalLeaderboardService(storage),
          dailyService: daily,
        );

    final first = createController();
    first.session.pieces = [
      const Piece(id: 'single', cells: [GridPoint(0, 0)]),
    ];
    await first.start();
    expect(await first.place(0, 2, 3), isTrue);

    final restored = createController();

    expect(restored.session.board.cells[2][3].isEmpty, isFalse);
    expect(restored.session.stats.score, 1);
    expect(restored.session.pieces.length, 3);
  });
}
