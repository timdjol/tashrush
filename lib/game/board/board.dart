import '../../models/game_models.dart';
import '../../utils/game_constants.dart';
import '../pieces/piece.dart';

class ClearResult {
  const ClearResult({
    this.lines = 0,
    this.goldDestroyed = 0,
    this.bombsTriggered = 0,
    this.cellsDestroyed = 0,
    this.specialCellsDestroyed = 0,
    this.affectedCells = const [],
    this.bombCenters = const [],
  });
  final int lines;
  final int goldDestroyed;
  final int bombsTriggered;
  final int cellsDestroyed;
  final int specialCellsDestroyed;
  final List<GridPoint> affectedCells;
  final List<GridPoint> bombCenters;
}

class Board {
  Board({List<List<CellState>>? cells})
      : cells = cells ??
            List.generate(
              GameConstants.boardSize,
              (_) => List.filled(GameConstants.boardSize, const CellState()),
            );

  final List<List<CellState>> cells;

  Board copy() => Board(
        cells: cells.map((row) => List<CellState>.of(row)).toList(),
      );

  Map<String, Object> toJson() => {
        'cells': cells
            .map((row) => row.map((cell) => cell.toJson()).toList())
            .toList(),
      };

  factory Board.fromJson(Map<String, Object?> json) {
    final rows = json['cells'] as List<Object?>?;
    if (rows == null || rows.length != GameConstants.boardSize) {
      throw const FormatException('Invalid saved board');
    }
    final cells = rows.map((row) {
      final values = row as List<Object?>;
      if (values.length != GameConstants.boardSize) {
        throw const FormatException('Invalid saved board row');
      }
      return values
          .map((cell) =>
              CellState.fromJson(Map<String, Object?>.from(cell! as Map)))
          .toList();
    }).toList();
    return Board(cells: cells);
  }

  bool canPlace(Piece piece, int row, int column) {
    for (final point in piece.cells) {
      final targetRow = row + point.row;
      final targetColumn = column + point.column;
      if (!_inBounds(targetRow, targetColumn) ||
          !cells[targetRow][targetColumn].isEmpty) {
        return false;
      }
    }
    return true;
  }

  bool canPlaceAnywhere(Piece piece) {
    for (var row = 0; row < GameConstants.boardSize; row++) {
      for (var column = 0; column < GameConstants.boardSize; column++) {
        if (canPlace(piece, row, column)) return true;
      }
    }
    return false;
  }

  void place(Piece piece, int row, int column,
      {CellType type = CellType.normal}) {
    if (!canPlace(piece, row, column)) {
      throw StateError('Piece cannot be placed at $row,$column');
    }
    for (final point in piece.cells) {
      final hits = type == CellType.frozen ? 2 : 0;
      cells[row + point.row][column + point.column] =
          CellState(type: type, hitsRemaining: hits);
    }
  }

  ClearResult clearCompletedLines() {
    final fullRows = <int>{};
    final fullColumns = <int>{};
    for (var index = 0; index < GameConstants.boardSize; index++) {
      if (cells[index].every((cell) => !cell.isEmpty)) fullRows.add(index);
      if (cells.every((row) => !row[index].isEmpty)) fullColumns.add(index);
    }
    if (fullRows.isEmpty && fullColumns.isEmpty) return const ClearResult();

    final targets = <GridPoint>{};
    for (final row in fullRows) {
      for (var column = 0; column < GameConstants.boardSize; column++) {
        targets.add(GridPoint(row, column));
      }
    }
    for (final column in fullColumns) {
      for (var row = 0; row < GameConstants.boardSize; row++) {
        targets.add(GridPoint(row, column));
      }
    }

    final bombCenters = targets
        .where((point) => cells[point.row][point.column].type == CellType.bomb)
        .toList();
    for (final center in bombCenters) {
      for (var dr = -1; dr <= 1; dr++) {
        for (var dc = -1; dc <= 1; dc++) {
          if (_inBounds(center.row + dr, center.column + dc)) {
            targets.add(GridPoint(center.row + dr, center.column + dc));
          }
        }
      }
    }

    var gold = 0;
    var destroyed = 0;
    var specialDestroyed = 0;
    for (final target in targets) {
      final cell = cells[target.row][target.column];
      if (cell.isEmpty) continue;
      if (cell.type == CellType.gold) gold++;
      final after = cell.hit();
      cells[target.row][target.column] = after;
      if (after.isEmpty) destroyed++;
      if (after.isEmpty && cell.type != CellType.normal) specialDestroyed++;
    }
    return ClearResult(
      lines: fullRows.length + fullColumns.length,
      goldDestroyed: gold,
      bombsTriggered: bombCenters.length,
      cellsDestroyed: destroyed,
      specialCellsDestroyed: specialDestroyed,
      affectedCells: List.unmodifiable(targets),
      bombCenters: List.unmodifiable(bombCenters),
    );
  }

  void clearCells(Iterable<GridPoint> points) {
    for (final point in points) {
      if (_inBounds(point.row, point.column)) {
        cells[point.row][point.column] = const CellState();
      }
    }
  }

  bool _inBounds(int row, int column) =>
      row >= 0 &&
      column >= 0 &&
      row < GameConstants.boardSize &&
      column < GameConstants.boardSize;
}
