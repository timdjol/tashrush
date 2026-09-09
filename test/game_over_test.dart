import 'package:tash_rush/game/board/board.dart';
import 'package:tash_rush/game/mechanics/game_session.dart';
import 'package:tash_rush/game/pieces/piece.dart';
import 'package:tash_rush/models/game_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('game over is detected when no available piece can fit', () {
    final board = Board();
    for (var row = 0; row < 8; row++) {
      for (var column = 0; column < 8; column++) {
        if ((row + column).isEven) {
          board.cells[row][column] = const CellState(type: CellType.normal);
        }
      }
    }
    final session = GameSession(board: board);
    const square = Piece(id: 'square', cells: [
      GridPoint(0, 0),
      GridPoint(0, 1),
      GridPoint(1, 0),
      GridPoint(1, 1)
    ]);
    session.pieces = [square, square, square];
    expect(session.isGameOver, isTrue);
  });

  test('game continues if at least one piece fits', () {
    final session = GameSession();
    session.pieces = const [
      Piece(id: 'one', cells: [GridPoint(0, 0)])
    ];
    expect(session.isGameOver, isFalse);
  });
}
