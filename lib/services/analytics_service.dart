import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics}) : _analytics = analytics;
  final FirebaseAnalytics? _analytics;

  Future<void> event(String name, [Map<String, Object>? parameters]) async {
    await _analytics?.logEvent(name: name, parameters: parameters);
  }

  Future<void> gameFinished(
          {required int score,
          required int durationSeconds,
          required int lines,
          required int highestCombo}) =>
      event('game_finished', {
        'score': score,
        'duration': durationSeconds,
        'lines': lines,
        'highest_combo': highestCombo
      });
}
