import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tash_rush/services/booster_service.dart';
import 'package:tash_rush/services/storage_service.dart';

void main() {
  test('booster spending persists balance and never makes it negative',
      () async {
    SharedPreferences.setMockInitialValues({'coins': 100});
    final storage = await StorageService.create();
    final boosters = BoosterService(storage);

    expect(await boosters.spend(BoosterType.shuffle), isTrue);
    expect(boosters.coins, 20);
    expect(await boosters.spend(BoosterType.singleCell), isFalse);
    expect(boosters.coins, 20);
  });

  test('completed games award coins from lines and score', () async {
    SharedPreferences.setMockInitialValues({'coins': 10});
    final storage = await StorageService.create();
    final boosters = BoosterService(storage);

    expect(await boosters.awardForGame(score: 1250, lines: 4), 10);
    expect(boosters.coins, 20);
  });
}
