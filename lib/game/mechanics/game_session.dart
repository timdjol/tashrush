import 'dart:math';

import '../../models/game_models.dart';
import '../../utils/game_constants.dart';
import '../board/board.dart';
import '../pieces/piece.dart';
import '../pieces/piece_generator.dart';
import '../scoring/scoring_engine.dart';
import 'special_cell_engine.dart';

class MoveResult {
  const MoveResult({required this.success, this.clear = const ClearResult()});
  final bool success;
  final ClearResult clear;
}

class GameSession {
  GameSession({Board? board, PieceGenerator? generator})
      : board = board ?? Board(),
        _generator = generator ?? PieceGenerator() {
    pieces = _generator.generate(this.board);
  }

  final Board board;
  final PieceGenerator _generator;
  final ScoringEngine _scoring = const ScoringEngine();
  final SpecialCellEngine _specialCells = SpecialCellEngine();
  late List<Piece> pieces;
  GameStats stats = const GameStats();
  bool continueUsed = false;
  final startedAt = DateTime.now();
  DateTime? _pausedAt;
  Duration _pausedDuration = Duration.zero;

  bool get isGameOver =>
      pieces.isNotEmpty &&
      pieces.every((piece) => !board.canPlaceAnywhere(piece));

  Duration get duration {
    final end = _pausedAt ?? DateTime.now();
    return end.difference(startedAt) - _pausedDuration;
  }

  void pause() {
    _pausedAt ??= DateTime.now();
  }

  void resume() {
    final pausedAt = _pausedAt;
    if (pausedAt == null) return;
    _pausedDuration += DateTime.now().difference(pausedAt);
    _pausedAt = null;
  }

  MoveResult placePiece(int pieceIndex, int row, int column) {
    if (pieceIndex < 0 || pieceIndex >= pieces.length) {
      return const MoveResult(success: false);
    }
    final piece = pieces[pieceIndex];
    if (!board.canPlace(piece, row, column)) {
      return const MoveResult(success: false);
    }
    board.place(piece, row, column);
    _specialCells.decoratePlacedPiece(board, piece, row, column);
    final clear = board.clearCompletedLines();
    stats = _scoring.scoreMove(stats, piece, clear);
    pieces.removeAt(pieceIndex);
    if (clear.lines > 0 || pieces.isEmpty) pieces = _generator.generate(board);
    return MoveResult(success: true, clear: clear);
  }

  bool continueAfterReward({Random? random}) {
    if (continueUsed) return false;
    final occupied = <GridPoint>[];
    for (var row = 0; row < GameConstants.boardSize; row++) {
      for (var column = 0; column < GameConstants.boardSize; column++) {
        if (!board.cells[row][column].isEmpty) {
          occupied.add(GridPoint(row, column));
        }
      }
    }
    occupied.shuffle(random ?? Random());
    board.clearCells(occupied.take(GameConstants.continueCellsToClear));
    continueUsed = true;
    pieces = _generator.generate(board);
    return true;
  }
}
