import 'package:flutter/material.dart';

import '../../game/pieces/piece.dart';
import '../../utils/game_constants.dart';

class PiecePreview extends StatelessWidget {
  const PiecePreview({required this.piece, this.cellSize = 18, super.key});
  final Piece piece;
  final double cellSize;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: piece.width * cellSize,
        height: piece.height * cellSize,
        child: Stack(children: [
          for (final point in piece.cells)
            Positioned(
              left: point.column * cellSize,
              top: point.row * cellSize,
              child: Container(
                width: cellSize - 2,
                height: cellSize - 2,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE64737), RushPalette.felt],
                  ),
                  border: Border.all(
                    color: RushPalette.gold.withAlpha(210),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(cellSize * .25),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x4434211D),
                        blurRadius: 7,
                        offset: Offset(0, 4))
                  ],
                ),
                child: Icon(
                  Icons.diamond_outlined,
                  size: cellSize * .38,
                  color: RushPalette.gold.withAlpha(190),
                ),
              ),
            ),
        ]),
      );
}
