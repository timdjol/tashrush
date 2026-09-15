import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../game/board/board.dart';
import '../../game/mechanics/game_session.dart';
import '../../game/pieces/piece.dart';
import '../../models/game_models.dart';
import '../../services/achievement_service.dart';
import '../../services/analytics_service.dart';
import '../../services/daily_challenge_service.dart';
import '../../services/leaderboard_service.dart';
import '../../services/storage_service.dart';
import '../../utils/game_constants.dart';

class PlacementHint {
  const PlacementHint({required this.piece, required this.origin});
  final Piece piece;
  final GridPoint origin;
}

class GameController extends ChangeNotifier {
  GameController({
    required this.storage,
    required this.analytics,
    required this.achievements,
    required this.leaderboard,
    required this.dailyService,
    this.dailyMode = false,
  }) : session = _restoreSession(storage, dailyService, dailyMode);
  final StorageService storage;
  final AnalyticsService analytics;
  final AchievementService achievements;
  final LeaderboardService leaderboard;
  final DailyChallengeService dailyService;
  final bool dailyMode;
  GameSession session;
  bool paused = false;
  bool _finishedRecorded = false;
  List<String> _newlyUnlocked = const [];
  final Set<int> _reportedScoreMilestones = {};
  ClearResult lastClear = const ClearResult();
  int _dailyStartingProgress = 0;

  int get bestScore => storage.getInt('bestScore');

  PlacementHint? findPlacementHint() {
    for (final piece in session.pieces) {
      for (var row = 0; row < GameConstants.boardSize; row++) {
        for (var column = 0; column < GameConstants.boardSize; column++) {
          if (session.board.canPlace(piece, row, column)) {
            return PlacementHint(
              piece: piece,
              origin: GridPoint(row, column),
            );
          }
        }
      }
    }
    return null;
  }

  static String _sessionKey(bool dailyMode) =>
      dailyMode ? 'active_daily_game' : 'active_classic_game';

  static GameSession _restoreSession(
    StorageService storage,
    DailyChallengeService dailyService,
    bool dailyMode,
  ) {
    try {
      final snapshot = storage.getJson(_sessionKey(dailyMode));
      if (snapshot == null) return GameSession();
      if (dailyMode && snapshot['date'] != dailyService.dateKey()) {
        unawaited(storage.remove(_sessionKey(dailyMode)));
        return GameSession();
      }
      return GameSession.fromJson(
        Map<String, Object?>.from(snapshot['session']! as Map),
      );
    } catch (_) {
      unawaited(storage.remove(_sessionKey(dailyMode)));
      return GameSession();
    }
  }

  Future<void> persist() => storage.setJson(_sessionKey(dailyMode), {
        'date': dailyMode ? dailyService.dateKey() : '',
        'session': session.toJson(),
      });

  Future<void> start() async {
    if (dailyMode) {
      final challenge = dailyService.current();
      final savedProgress = challenge.progress;
      final sessionProgress = _sessionProgress(challenge);
      _dailyStartingProgress = challenge.type == DailyGoalType.combo
          ? savedProgress
          : (savedProgress - sessionProgress).clamp(0, savedProgress);
    }
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
    if (dailyMode) await _updateDaily();
    await persist();
    notifyListeners();
    return true;
  }

  void pause() {
    if (paused) return;
    paused = true;
    session.pause();
    unawaited(persist());
    notifyListeners();
  }

  void resume() {
    if (!paused) return;
    paused = false;
    session.resume();
    unawaited(persist());
    notifyListeners();
  }

  void restart() {
    session = GameSession();
    paused = false;
    _finishedRecorded = false;
    _newlyUnlocked = const [];
    _reportedScoreMilestones.clear();
    lastClear = const ClearResult();
    if (dailyMode) _dailyStartingProgress = dailyService.current().progress;
    unawaited(persist());
    unawaited(analytics.event(dailyMode ? 'daily_started' : 'game_started'));
    notifyListeners();
  }

  Future<List<String>> finish() async {
    if (_finishedRecorded) return _newlyUnlocked;
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
    await leaderboard.submit(
      stats.score,
      lines: stats.lines,
      durationSeconds: session.duration.inSeconds,
    );
    _newlyUnlocked = await achievements.evaluate(stats);
    await storage.remove(_sessionKey(dailyMode));
    await analytics.gameFinished(
        score: stats.score,
        durationSeconds: session.duration.inSeconds,
        lines: stats.lines,
        highestCombo: stats.highestCombo);
    return _newlyUnlocked;
  }

  Future<bool> continueAfterReward() async {
    final continued = session.continueAfterReward();
    if (!continued) return false;
    await persist();
    notifyListeners();
    return true;
  }

  Future<void> _updateDaily() async {
    final challenge = dailyService.current();
    final sessionProgress = _sessionProgress(challenge);
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
        await dailyService.markCompleted(today);
      }
      await analytics.event('daily_completed');
    }
  }

  int _sessionProgress(DailyChallenge challenge) => switch (challenge.type) {
        DailyGoalType.score => session.stats.score,
        DailyGoalType.lines => session.stats.lines,
        DailyGoalType.combo => session.stats.highestCombo,
        DailyGoalType.specialCells => session.stats.specialCellsDestroyed,
      };
}
