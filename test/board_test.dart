import 'package:tash_rush/game/board/board.dart';
import 'package:tash_rush/game/pieces/piece.dart';
import 'package:tash_rush/models/game_models.dart';
import 'package:flutter_test/flutter_test.dart';

const single = Piece(id: 'single', cells: [GridPoint(0, 0)]);
const line2 = Piece(id: 'line2', cells: [GridPoint(0, 0), GridPoint(0, 1)]);

void main() {
  group('Board placement', () {
    test('accepts a fitting piece and rejects collision and overflow', () {
      final board = Board();
      expect(board.canPlace(line2, 0, 0), isTrue);
      board.place(line2, 0, 0);
      expect(board.canPlace(single, 0, 0), isFalse);
      expect(board.canPlace(line2, 0, 7), isFalse);
    });
  });

  group('Line clearing', () {
    test('clears a completed horizontal line', () {
      final board = Board();
      for (var column = 0; column < 8; column++) {
        board.place(single, 2, column);
      }
      final result = board.clearCompletedLines();
      expect(result.lines, 1);
      expect(result.affectedCells.length, 8);
      expect(board.cells[2].every((cell) => cell.isEmpty), isTrue);
    });

    test('clears a completed vertical line', () {
      final board = Board();
      for (var row = 0; row < 8; row++) {
        board.place(single, row, 5);
      }
      final result = board.clearCompletedLines();
      expect(result.lines, 1);
      expect(board.cells.every((row) => row[5].isEmpty), isTrue);
    });

    test('clears multiple crossing lines once per line', () {
      final board = Board();
      for (var index = 0; index < 8; index++) {
        board.place(single, 3, index);
        if (index != 3) board.place(single, index, 3);
      }
      final result = board.clearCompletedLines();
      expect(result.lines, 2);
      expect(result.cellsDestroyed, 15);
    });
  });

  group('Special cells', () {
    test('frozen cells need two line hits', () {
      final board = Board();
      for (var column = 0; column < 8; column++) {
        board.cells[0][column] = CellState(
            type: column == 0 ? CellType.frozen : CellType.normal,
            hitsRemaining: column == 0 ? 2 : 0);
      }
      board.clearCompletedLines();
      expect(board.cells[0][0].type, CellType.frozen);
      expect(board.cells[0][0].hitsRemaining, 1);
      for (var column = 1; column < 8; column++) {
        board.cells[0][column] = const CellState(type: CellType.normal);
      }
      board.clearCompletedLines();
      expect(board.cells[0][0].isEmpty, isTrue);
    });

    test('bomb clears a 3x3 area', () {
      final board = Board();
      for (var column = 0; column < 8; column++) {
        board.cells[4][column] = const CellState(type: CellType.normal);
      }
      board.cells[4][4] = const CellState(type: CellType.bomb);
      board.cells[3][3] = const CellState(type: CellType.gold);
      final result = board.clearCompletedLines();
      expect(result.bombsTriggered, 1);
      expect(result.bombCenters, contains(const GridPoint(4, 4)));
      expect(result.affectedCells, contains(const GridPoint(3, 3)));
      expect(board.cells[3][3].isEmpty, isTrue);
    });
  });
}
