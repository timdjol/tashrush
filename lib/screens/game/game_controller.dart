import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../game/board/board.dart';
import '../../game/mechanics/game_session.dart';
import '../../models/game_models.dart';
import '../../services/achievement_service.dart';
import '../../services/analytics_service.dart';
import '../../services/daily_challenge_service.dart';
import '../../services/leaderboard_service.dart';
import '../../services/storage_service.dart';

class GameController extends ChangeNotifier {
  GameController({
    required this.storage,
    required this.analytics,
    required this.achievements,
    required this.leaderboard,
    required this.dailyService,
    this.dailyMode = false,
  }) : session = GameSession();
  final StorageService storage;
  final AnalyticsService analytics;
  final AchievementService achievements;
  final LeaderboardService leaderboard;
  final DailyChallengeService dailyService;
  final bool dailyMode;
  GameSession session;
  bool paused = false;
  bool _finishedRecorded = false;
  final Set<int> _reportedScoreMilestones = {};
  ClearResult lastClear = const ClearResult();
  int _dailyStartingProgress = 0;

  int get bestScore => storage.getInt('bestScore');

  Future<void> start() async {
    if (dailyMode) _dailyStartingProgress = dailyService.current().progress;
    await analytics.event(dailyMode ? 'daily_started' : 'game_started');
  }

  Future<bool> place(int pieceIndex, int row, int column) async {
    final result = session.placePiece(pieceIndex, row, column);
    if (!result.success) return false;
    lastClear = result.clear;
    for (final milestone in const [1000, 5000, 10000, 25000]) {
      if (session.stats.score >= milestone &&
          _reportedScoreMilestones.add(milestone)) {
        await analytics.event('score_reached', {'score': milestone});
      }
    }
    notifyListeners();
    if (dailyMode) await _updateDaily();
    return true;
  }

  void pause() {
    if (paused) return;
    paused = true;
    session.pause();
    notifyListeners();
  }

  void resume() {
    if (!paused) return;
    paused = false;
    session.resume();
    notifyListeners();
  }

  void restart() {
    session = GameSession();
    paused = false;
    _finishedRecorded = false;
    _reportedScoreMilestones.clear();
    lastClear = const ClearResult();
    if (dailyMode) _dailyStartingProgress = dailyService.current().progress;
    unawaited(analytics.event(dailyMode ? 'daily_started' : 'game_started'));
    notifyListeners();
  }

  Future<void> finish() async {
    if (_finishedRecorded) return;
    _finishedRecorded = true;
    final stats = session.stats;
    final games = storage.getInt('totalGames') + 1;
    await storage.setInt('totalGames', games);
    await storage.setInt(
        'totalLines', storage.getInt('totalLines') + stats.lines);
    await storage.setInt(
        'highestCombo',
        stats.highestCombo > storage.getInt('highestCombo')
            ? stats.highestCombo
            : storage.getInt('highestCombo'));
    await leaderboard.submit(stats.score);
    await achievements.evaluate(stats);
    await analytics.gameFinished(
        score: stats.score,
        durationSeconds: session.duration.inSeconds,
        lines: stats.lines,
        highestCombo: stats.highestCombo);
  }

  Future<void> _updateDaily() async {
    final challenge = dailyService.current();
    final stats = session.stats;
    final sessionProgress = switch (challenge.type) {
      DailyGoalType.score => stats.score,
      DailyGoalType.lines => stats.lines,
      DailyGoalType.combo => stats.highestCombo,
      DailyGoalType.specialCells => stats.specialCellsDestroyed,
    };
    final progress = challenge.type == DailyGoalType.combo
        ? (sessionProgress > _dailyStartingProgress
            ? sessionProgress
            : _dailyStartingProgress)
        : _dailyStartingProgress + sessionProgress;
    final completed = progress >= challenge.target;
    await dailyService
        .save(challenge.copyWith(progress: progress, completed: completed));
    if (completed && !challenge.completed) {
      final today = dailyService.dateKey();
      final yesterday = dailyService
          .dateKey(DateTime.now().subtract(const Duration(days: 1)));
      final lastCompleted = storage.getString('lastDailyCompleted');
      final streak =
          lastCompleted == yesterday ? storage.getInt('dailyStreak') + 1 : 1;
      if (lastCompleted != today) {
        await storage.setInt('dailyStreak', streak);
        await storage.setString('lastDailyCompleted', today);
      }
      await analytics.event('daily_completed');
    }
  }
}
