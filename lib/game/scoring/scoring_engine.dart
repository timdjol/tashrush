import '../../models/game_models.dart';
import '../board/board.dart';
import '../pieces/piece.dart';
import '../../utils/game_constants.dart';

class ScoringEngine {
  const ScoringEngine();

  GameStats scoreMove(GameStats current, Piece piece, ClearResult clear) {
    if (clear.lines == 0) {
      return current.copyWith(
          score: current.score + piece.cells.length, combo: 0);
    }
    final combo = current.combo + 1;
    final lineBase = clear.lines * 100;
    final multiLineBonus = clear.lines > 1 ? clear.lines * clear.lines * 50 : 0;
    final comboMultiplier = 1 + (combo - 1) * 0.25;
    final gained = piece.cells.length +
        ((lineBase + multiLineBonus) * comboMultiplier).round() +
        clear.goldDestroyed * GameConstants.goldBonus;
    return current.copyWith(
      score: current.score + gained,
      lines: current.lines + clear.lines,
      combo: combo,
      highestCombo: combo > current.highestCombo ? combo : current.highestCombo,
      goldDestroyed: current.goldDestroyed + clear.goldDestroyed,
      specialCellsDestroyed:
          current.specialCellsDestroyed + clear.specialCellsDestroyed,
    );
  }
}
