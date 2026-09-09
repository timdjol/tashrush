import '../../models/game_models.dart';

class Piece {
  const Piece({required this.id, required this.cells});
  final String id;
  final List<GridPoint> cells;

  int get width =>
      cells.map((e) => e.column).reduce((a, b) => a > b ? a : b) + 1;
  int get height => cells.map((e) => e.row).reduce((a, b) => a > b ? a : b) + 1;
}
