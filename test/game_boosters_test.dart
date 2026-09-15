import 'package:flutter_test/flutter_test.dart';
import 'package:tash_rush/game/board/board.dart';
import 'package:tash_rush/game/mechanics/game_session.dart';
import 'package:tash_rush/game/pieces/piece_catalog.dart';
import 'package:tash_rush/models/game_models.dart';

void main() {
  test('single-cell booster replaces the first tray piece', () {
    final session = GameSession(initialPieces: [
      PieceCatalog.byId('square2'),
      PieceCatalog.byId('line3h'),
    ]);

    expect(session.grantSingleCellPiece(), isTrue);
    expect(session.pieces.first.id, 'single');
    expect(session.pieces.last.id, 'line3h');
  });

  test('hammer clears only an occupied target cell', () {
    final board = Board();
    board.place(PieceCatalog.byId('single'), 2, 3);
    final session = GameSession(
      board: board,
      initialPieces: [PieceCatalog.byId('single')],
    );

    expect(session.hammerCell(0, 0), isFalse);
    expect(session.hammerCell(2, 3), isTrue);
    expect(session.board.cells[2][3], const CellState());
  });
}
