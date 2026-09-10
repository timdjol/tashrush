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
  List<GridPoint> _effectCells = const [];
  List<GridPoint> _bombCenters = const [];

  double get cellSize => size.x / GameConstants.boardSize;

  void playClearEffect(ClearResult clear) {
    if (clear.lines == 0 && clear.bombsTriggered == 0) return;
    _effectRemaining = clear.bombsTriggered > 0 ? .72 : .48;
    _effectCells = clear.affectedCells;
    _bombCenters = clear.bombCenters;
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
      final hasBombs = _bombCenters.isNotEmpty;
      final progress = (_effectRemaining / (hasBombs ? .72 : .48))
          .clamp(0.0, 1.0)
          .toDouble();
      final pulse = math.sin((1 - progress) * math.pi).abs();
      for (final point in _effectCells) {
        final inset = 5 + (1 - progress) * cell * .32;
        final rect = Rect.fromLTWH(
          point.column * cell + inset,
          point.row * cell + inset,
          cell - inset * 2,
          cell - inset * 2,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(8)),
          Paint()..color = RushPalette.gold.withAlpha((230 * progress).round()),
        );
      }
      final particlePaint = Paint()
        ..color = (hasBombs ? RushPalette.coral : RushPalette.gold)
            .withAlpha((220 * progress).round());
      final origins = _bombCenters.isEmpty
          ? [Offset(size.x / 2, size.y / 2)]
          : _bombCenters
              .map((point) => Offset(
                    (point.column + .5) * cell,
                    (point.row + .5) * cell,
                  ))
              .toList();
      for (final origin in origins) {
        canvas.drawCircle(
          origin,
          cell * 1.8 * pulse,
          Paint()
            ..color = RushPalette.gold.withAlpha((55 * progress).round())
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
        for (var index = 0; index < 12; index++) {
          final angle = index * math.pi / 6;
          final distance = cell * 2.2 * (1 - progress);
          final center = Offset(
            origin.dx + distance * math.cos(angle),
            origin.dy + distance * math.sin(angle),
          );
          canvas.drawCircle(center, 2 + 4 * progress, particlePaint);
        }
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
