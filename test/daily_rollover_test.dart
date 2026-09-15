import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tash_rush/services/daily_challenge_service.dart';
import 'package:tash_rush/services/storage_service.dart';

void main() {
  test('daily challenge changes with the calendar date', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final daily = DailyChallengeService(storage);
    final firstDate = DateTime(2026, 9, 15);
    final nextDate = DateTime(2026, 9, 16);

    final first = daily.current(firstDate);
    await daily.save(first.copyWith(progress: 1));
    final next = daily.current(nextDate);

    expect(first.dateKey, '2026-09-15');
    expect(next.dateKey, '2026-09-16');
    expect(next.progress, 0);
    expect(daily.current(nextDate).type, next.type);
    expect(daily.current(nextDate).target, next.target);
  });
}
