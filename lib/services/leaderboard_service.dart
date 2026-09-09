import 'storage_service.dart';

class LeaderboardEntry {
  const LeaderboardEntry(this.name, this.score);
  final String name;
  final int score;
}

abstract interface class LeaderboardService {
  Future<List<LeaderboardEntry>> topScores();
  Future<void> submit(int score);
}

class LocalLeaderboardService implements LeaderboardService {
  LocalLeaderboardService(this.storage);
  final StorageService storage;
  @override
  Future<void> submit(int score) => storage.setInt(
      'bestScore',
      score > storage.getInt('bestScore')
          ? score
          : storage.getInt('bestScore'));
  @override
  Future<List<LeaderboardEntry>> topScores() async => [
        LeaderboardEntry('You', storage.getInt('bestScore')),
        const LeaderboardEntry('Nova', 8400),
        const LeaderboardEntry('Pixel', 6200),
        const LeaderboardEntry('Orbit', 4100),
      ]..sort((a, b) => b.score.compareTo(a.score));
}
