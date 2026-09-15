import 'dart:convert';

import 'storage_service.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.score,
    this.playedAt,
    this.lines = 0,
    this.durationSeconds = 0,
  });

  final int score;
  final DateTime? playedAt;
  final int lines;
  final int durationSeconds;

  Map<String, Object> toJson() => {
        'score': score,
        'playedAt': playedAt?.toIso8601String() ?? '',
        'lines': lines,
        'durationSeconds': durationSeconds,
      };

  factory LeaderboardEntry.fromJson(Map<String, Object?> json) {
    final playedAt = json['playedAt'] as String?;
    return LeaderboardEntry(
      score: (json['score'] as num?)?.toInt() ?? 0,
      playedAt: playedAt == null || playedAt.isEmpty
          ? null
          : DateTime.tryParse(playedAt),
      lines: (json['lines'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}

abstract interface class LeaderboardService {
  Future<List<LeaderboardEntry>> topScores();
  Future<void> submit(
    int score, {
    int lines = 0,
    int durationSeconds = 0,
    DateTime? playedAt,
  });
}

class LocalLeaderboardService implements LeaderboardService {
  LocalLeaderboardService(this.storage);
  final StorageService storage;
  static const _historyKey = 'scoreHistory';
  static const _historyLimit = 50;

  List<LeaderboardEntry> get history {
    final entries = <LeaderboardEntry>[];
    for (final encoded in storage.getStringList(_historyKey)) {
      try {
        entries.add(LeaderboardEntry.fromJson(
          Map<String, Object?>.from(jsonDecode(encoded) as Map),
        ));
      } catch (_) {
        // Ignore a damaged legacy record without hiding valid results.
      }
    }
    return entries;
  }

  @override
  Future<void> submit(
    int score, {
    int lines = 0,
    int durationSeconds = 0,
    DateTime? playedAt,
  }) async {
    final previousBest = storage.getInt('bestScore');
    if (score > previousBest) await storage.setInt('bestScore', score);
    final entries = history
      ..add(LeaderboardEntry(
        score: score,
        lines: lines,
        durationSeconds: durationSeconds,
        playedAt: playedAt ?? DateTime.now(),
      ));
    entries.sort((a, b) => b.score.compareTo(a.score));
    await storage.setStringList(
      _historyKey,
      entries
          .take(_historyLimit)
          .map((entry) => jsonEncode(entry.toJson()))
          .toList(),
    );
  }

  @override
  Future<List<LeaderboardEntry>> topScores() async {
    final entries = history..sort((a, b) => b.score.compareTo(a.score));
    if (entries.isEmpty) {
      final legacyBest = storage.getInt('bestScore');
      if (legacyBest > 0) entries.add(LeaderboardEntry(score: legacyBest));
    }
    return entries;
  }
}
