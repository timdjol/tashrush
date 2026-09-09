import 'dart:math';

import '../board/board.dart';
import 'piece.dart';
import 'piece_catalog.dart';

class PieceGenerator {
  PieceGenerator({Random? random}) : _random = random ?? Random();
  final Random _random;

  List<Piece> generate(Board board, {int count = 3}) {
    final fitting = PieceCatalog.pieces.where(board.canPlaceAnywhere).toList();
    final pool = fitting.isEmpty ? PieceCatalog.pieces : fitting;
    final result = <Piece>[];
    for (var i = 0; i < count; i++) {
      final preferFitting = i == 0 || _random.nextDouble() < .72;
      final source = preferFitting && fitting.isNotEmpty ? fitting : pool;
      result.add(source[_random.nextInt(source.length)]);
    }
    return result;
  }
}
