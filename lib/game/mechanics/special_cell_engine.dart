import 'dart:math';

import '../../models/game_models.dart';
import '../board/board.dart';
import '../pieces/piece.dart';

class SpecialCellEngine {
  SpecialCellEngine({Random? random}) : _random = random ?? Random();
  final Random _random;

  void decoratePlacedPiece(Board board, Piece piece, int row, int column) {
    if (_random.nextDouble() > .18) return;
    final point = piece.cells[_random.nextInt(piece.cells.length)];
    final roll = _random.nextDouble();
    final type = roll < .45
        ? CellType.frozen
        : roll < .75
            ? CellType.gold
            : CellType.bomb;
    board.cells[row + point.row][column + point.column] = CellState(
      type: type,
      hitsRemaining: type == CellType.frozen ? 2 : 0,
    );
  }
}
