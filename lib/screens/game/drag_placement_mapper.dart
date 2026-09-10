import 'package:flutter/material.dart';

import '../../game/pieces/piece.dart';
import '../../models/game_models.dart';
import '../../utils/game_constants.dart';

abstract final class DragPlacementMapper {
  static GridPoint originForCenter({
    required Offset localCenter,
    required double boardSide,
    required Piece piece,
  }) {
    final cellSize = boardSide / GameConstants.boardSize;
    return GridPoint(
      (localCenter.dy / cellSize - piece.height / 2).round(),
      (localCenter.dx / cellSize - piece.width / 2).round(),
    );
  }
}
