import 'package:flutter_test/flutter_test.dart';
import 'package:tash_rush/game/board/board.dart';
import 'package:tash_rush/game/mechanics/game_session.dart';
import 'package:tash_rush/game/pieces/piece_catalog.dart';
import 'package:tash_rush/game/pieces/piece_generator.dart';
import 'package:tash_rush/models/game_models.dart';

void main() {
  test('game session round-trips board, pieces, stats, and continue state', () {
    final board = Board();
    board.cells[1][2] = const CellState(type: CellType.gold);
    board.cells[3][4] =
        const CellState(type: CellType.frozen, hitsRemaining: 1);
    final session = GameSession(
      board: board,
      initialPieces: [PieceCatalog.byId('line3h'), PieceCatalog.byId('l3')],
      initialStats: const GameStats(
        score: 740,
        lines: 6,
        combo: 2,
        highestCombo: 4,
        goldDestroyed: 1,
        specialCellsDestroyed: 3,
      ),
      continueUsed: true,
      elapsed: const Duration(seconds: 45),
    );

    final restored = GameSession.fromJson(session.toJson());

    expect(restored.board.cells[1][2].type, CellType.gold);
    expect(restored.board.cells[3][4].hitsRemaining, 1);
    expect(restored.pieces.map((piece) => piece.id), ['line3h', 'l3']);
    expect(restored.stats.score, 740);
    expect(restored.stats.highestCombo, 4);
    expect(restored.continueUsed, isTrue);
    expect(restored.duration.inSeconds, greaterThanOrEqualTo(45));
  });

  test('generator returns only pieces that fit when a move exists', () {
    final board = Board();
    for (var row = 0; row < 8; row++) {
      for (var column = 0; column < 8; column++) {
        if (row != 7 || column != 7) {
          board.cells[row][column] = const CellState(type: CellType.normal);
        }
      }
    }

    final pieces = PieceGenerator().generate(board, count: 20);

    expect(pieces, isNotEmpty);
    expect(pieces.every(board.canPlaceAnywhere), isTrue);
  });
}
