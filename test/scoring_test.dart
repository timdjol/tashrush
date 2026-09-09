import 'package:tash_rush/game/board/board.dart';
import 'package:tash_rush/game/pieces/piece.dart';
import 'package:tash_rush/game/scoring/scoring_engine.dart';
import 'package:tash_rush/models/game_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = ScoringEngine();
  const piece = Piece(
      id: 'three', cells: [GridPoint(0, 0), GridPoint(0, 1), GridPoint(0, 2)]);

  test('placement awards one point per block', () {
    final stats =
        engine.scoreMove(const GameStats(), piece, const ClearResult());
    expect(stats.score, 3);
    expect(stats.combo, 0);
  });

  test('line clears build combo and increase reward', () {
    final first =
        engine.scoreMove(const GameStats(), piece, const ClearResult(lines: 1));
    final second = engine.scoreMove(first, piece, const ClearResult(lines: 1));
    expect(first.combo, 1);
    expect(second.combo, 2);
    expect(second.score - first.score, greaterThan(first.score));
  });

  test('move without clear resets combo', () {
    const active = GameStats(combo: 4, highestCombo: 4);
    final result = engine.scoreMove(active, piece, const ClearResult());
    expect(result.combo, 0);
    expect(result.highestCombo, 4);
  });

  test('multi-line and gold bonuses are applied', () {
    final result = engine.scoreMove(const GameStats(), piece,
        const ClearResult(lines: 3, goldDestroyed: 1));
    expect(result.score, greaterThan(700));
  });
}
