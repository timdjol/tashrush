import 'dart:math';

import '../../utils/game_constants.dart';
import '../board/board.dart';
import 'piece.dart';
import 'piece_catalog.dart';

class PieceGenerator {
  PieceGenerator({Random? random}) : _random = random ?? Random();
  final Random _random;

  List<Piece> generate(Board board, {int count = 3}) {
    final fitting = PieceCatalog.pieces.where(board.canPlaceAnywhere).toList();
    final pool = fitting.isEmpty ? PieceCatalog.pieces : fitting;
    if (fitting.isEmpty || count != 3) {
      return List.generate(count, (_) => pool[_random.nextInt(pool.length)]);
    }

    for (var attempt = 0; attempt < 24; attempt++) {
      final candidate = List.generate(
        count,
        (_) => _pickWeighted(fitting, board),
      );
      if (_hasPlayableSequence(
        board,
        candidate,
        _SearchBudget(3500),
      )) {
        return candidate;
      }
    }

    final single = PieceCatalog.byId('single');
    final simplestTray = List<Piece>.filled(count, single);
    if (_hasPlayableSequence(
      board,
      simplestTray,
      _SearchBudget(5000),
    )) {
      return simplestTray;
    }

    final rescuePool = fitting.toList()
      ..sort((left, right) => left.cells.length.compareTo(right.cells.length));
    final limited = rescuePool.take(min(7, rescuePool.length)).toList();
    for (var attempt = 0; attempt < 48; attempt++) {
      final candidate = List.generate(
        count,
        (_) => limited[_random.nextInt(limited.length)],
      );
      if (_hasPlayableSequence(
        board,
        candidate,
        _SearchBudget(5000),
      )) {
        return candidate;
      }
    }

    return List.generate(
        count, (_) => fitting[_random.nextInt(fitting.length)]);
  }

  Piece _pickWeighted(List<Piece> pieces, Board board) {
    final emptyCells =
        board.cells.expand((row) => row).where((cell) => cell.isEmpty).length;
    final preferredSize = emptyCells > 42
        ? 5
        : emptyCells > 24
            ? 4
            : 2;
    final weights = pieces
        .map((piece) =>
            max(1, 8 - (piece.cells.length - preferredSize).abs() * 2))
        .toList();
    final total = weights.fold<int>(0, (sum, weight) => sum + weight);
    var roll = _random.nextInt(total);
    for (var index = 0; index < pieces.length; index++) {
      roll -= weights[index];
      if (roll < 0) return pieces[index];
    }
    return pieces.last;
  }

  bool _hasPlayableSequence(
    Board board,
    List<Piece> remaining,
    _SearchBudget budget,
  ) {
    if (remaining.isEmpty) return true;

    final options = <_PlacementOptions>[];
    for (var index = 0; index < remaining.length; index++) {
      final piece = remaining[index];
      final placements = <_Placement>[];
      for (var row = 0; row < GameConstants.boardSize; row++) {
        for (var column = 0; column < GameConstants.boardSize; column++) {
          if (board.canPlace(piece, row, column)) {
            placements.add(_Placement(row, column));
          }
        }
      }
      if (placements.isNotEmpty) {
        options.add(_PlacementOptions(index, piece, placements));
      }
    }
    if (options.isEmpty) return false;
    options.sort(
      (left, right) =>
          left.placements.length.compareTo(right.placements.length),
    );

    for (final option in options) {
      for (final placement in option.placements) {
        if (!budget.consume()) return false;
        final simulated = board.copy();
        simulated.place(option.piece, placement.row, placement.column);
        simulated.clearCompletedLines();
        final next = List<Piece>.of(remaining)..removeAt(option.index);
        if (_hasPlayableSequence(simulated, next, budget)) return true;
      }
    }
    return false;
  }
}

class _SearchBudget {
  _SearchBudget(this.remaining);
  int remaining;

  bool consume() {
    if (remaining <= 0) return false;
    remaining--;
    return true;
  }
}

class _Placement {
  const _Placement(this.row, this.column);
  final int row;
  final int column;
}

class _PlacementOptions {
  const _PlacementOptions(this.index, this.piece, this.placements);
  final int index;
  final Piece piece;
  final List<_Placement> placements;
}
