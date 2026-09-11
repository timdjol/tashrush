import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tash_rush/game/board/board.dart';
import 'package:tash_rush/game/pieces/piece.dart';
import 'package:tash_rush/game/pieces/piece_generator.dart';
import 'package:tash_rush/models/game_models.dart';
import 'package:tash_rush/utils/game_constants.dart';

void main() {
  test('standard tray has a playable three-piece sequence', () {
    final board = Board();
    for (var row = 0; row < GameConstants.boardSize; row++) {
      for (var column = 0; column < GameConstants.boardSize; column++) {
        if (row != column) {
          board.cells[row][column] = const CellState(type: CellType.normal);
        }
      }
    }
    final before = board.toJson().toString();

    final pieces = PieceGenerator(random: Random(73)).generate(board);

    expect(pieces, hasLength(3));
    expect(_canPlayAll(board, pieces), isTrue);
    expect(board.toJson().toString(), before);
  });
}

bool _canPlayAll(Board board, List<Piece> remaining) {
  if (remaining.isEmpty) return true;
  for (var index = 0; index < remaining.length; index++) {
    final piece = remaining[index];
    for (var row = 0; row < GameConstants.boardSize; row++) {
      for (var column = 0; column < GameConstants.boardSize; column++) {
        if (!board.canPlace(piece, row, column)) continue;
        final simulated = board.copy();
        simulated.place(piece, row, column);
        simulated.clearCompletedLines();
        final next = List<Piece>.of(remaining)..removeAt(index);
        if (_canPlayAll(simulated, next)) return true;
      }
    }
  }
  return false;
}
