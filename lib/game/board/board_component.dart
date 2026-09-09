import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/game_models.dart';
import '../../utils/game_constants.dart';
import '../pieces/piece.dart';
import 'board.dart';

class BoardComponent extends PositionComponent {
  BoardComponent({required this.board});
  Board board;
  Piece? previewPiece;
  GridPoint? previewOrigin;
  double _effectRemaining = 0;
  int _bombs = 0;

  double get cellSize => size.x / GameConstants.boardSize;

  void playClearEffect({required int lines, required int bombs}) {
    if (lines == 0 && bombs == 0) return;
    _effectRemaining = bombs > 0 ? .7 : .42;
    _bombs = bombs;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_effectRemaining > 0) _effectRemaining -= dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final cell = cellSize;
    final background = Paint()..color = RushPalette.board;
    final boardRect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, const Radius.circular(24)),
      background,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect.deflate(2), const Radius.circular(22)),
      Paint()
        ..color = RushPalette.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    for (var row = 0; row < GameConstants.boardSize; row++) {
      for (var column = 0; column < GameConstants.boardSize; column++) {
        final rect = Rect.fromLTWH(
          column * cell + 3,
          row * cell + 3,
          cell - 6,
          cell - 6,
        );
        _drawCell(canvas, rect, board.cells[row][column]);
      }
    }
    final piece = previewPiece;
    final origin = previewOrigin;
    if (piece != null && origin != null) {
      final valid = board.canPlace(piece, origin.row, origin.column);
      final paint = Paint()
        ..color = (valid ? RushPalette.mint : RushPalette.coral).withAlpha(120);
      for (final point in piece.cells) {
        final row = origin.row + point.row;
        final column = origin.column + point.column;
        if (row >= 0 && column >= 0 && row < 8 && column < 8) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  column * cell + 5, row * cell + 5, cell - 10, cell - 10),
              const Radius.circular(8),
            ),
            paint,
          );
        }
      }
    }
    if (_effectRemaining > 0) {
      final progress = (_effectRemaining / (_bombs > 0 ? .7 : .42))
          .clamp(0.0, 1.0)
          .toDouble();
      canvas.drawRRect(
        RRect.fromRectAndRadius(boardRect, const Radius.circular(24)),
        Paint()..color = Colors.white.withAlpha((70 * progress).round()),
      );
      final particlePaint = Paint()
        ..color = (_bombs > 0 ? RushPalette.coral : RushPalette.gold)
            .withAlpha((220 * progress).round());
      for (var index = 0; index < 12; index++) {
        final angle = index * .524;
        final distance = size.x * .34 * (1 - progress);
        final center = Offset(
          size.x / 2 + distance * math.cos(angle),
          size.y / 2 + distance * math.sin(angle),
        );
        canvas.drawCircle(center, 3 + 4 * progress, particlePaint);
      }
    }
  }

  void _drawCell(Canvas canvas, Rect rect, CellState cell) {
    final color = switch (cell.type) {
      CellType.empty => RushPalette.surface.withAlpha(52),
      CellType.normal => RushPalette.coral,
      CellType.frozen => RushPalette.ice,
      CellType.gold => RushPalette.gold,
      CellType.bomb => RushPalette.coral,
    };
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = color,
    );
    if (cell.type == CellType.normal) {
      final motif = Path()
        ..moveTo(rect.center.dx, rect.top + rect.height * .22)
        ..lineTo(rect.right - rect.width * .22, rect.center.dy)
        ..lineTo(rect.center.dx, rect.bottom - rect.height * .22)
        ..lineTo(rect.left + rect.width * .22, rect.center.dy)
        ..close();
      canvas.drawPath(
        motif,
        Paint()
          ..color = RushPalette.gold.withAlpha(165)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    } else if (cell.type == CellType.frozen) {
      final crackPaint = Paint()
        ..color = Colors.white70
        ..strokeWidth = 2;
      canvas.drawLine(rect.topLeft, rect.bottomRight, crackPaint);
    } else if (cell.type == CellType.bomb) {
      canvas.drawCircle(
          rect.center, rect.width * .2, Paint()..color = RushPalette.ink);
    } else if (cell.type == CellType.gold) {
      canvas.drawCircle(
          rect.center, rect.width * .14, Paint()..color = Colors.white70);
    }
  }
}
