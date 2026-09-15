import 'package:flutter/foundation.dart';

import 'storage_service.dart';

enum BoosterType { singleCell, shuffle, hammer }

abstract final class BoosterPrices {
  static const values = <BoosterType, int>{
    BoosterType.singleCell: 60,
    BoosterType.shuffle: 80,
    BoosterType.hammer: 120,
  };
}

class BoosterService extends ChangeNotifier {
  BoosterService(this._storage);

  final StorageService _storage;

  int get coins => _storage.getInt('coins');

  int price(BoosterType type) => BoosterPrices.values[type]!;

  bool canAfford(BoosterType type) => coins >= price(type);

  Future<bool> spend(BoosterType type) async {
    final current = coins;
    final cost = price(type);
    if (current < cost) return false;
    await _storage.setInt('coins', current - cost);
    notifyListeners();
    return true;
  }

  int rewardForGame({required int score, required int lines}) =>
      lines * 2 + score ~/ 500;

  Future<int> awardForGame({required int score, required int lines}) async {
    final reward = rewardForGame(score: score, lines: lines);
    if (reward <= 0) return 0;
    await _storage.setInt('coins', coins + reward);
    notifyListeners();
    return reward;
  }
}
