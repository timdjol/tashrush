import 'package:flutter_test/flutter_test.dart';
import 'package:tash_rush/game/pieces/piece.dart';
import 'package:tash_rush/models/game_models.dart';
import 'package:tash_rush/screens/game/drag_placement_mapper.dart';

void main() {
  test('maps the visual piece center to its board origin', () {
    const piece = Piece(
      id: 'test',
      cells: [
        GridPoint(0, 0),
        GridPoint(0, 1),
        GridPoint(0, 2),
        GridPoint(1, 0),
      ],
    );

    final origin = DragPlacementMapper.originForCenter(
      localCenter: const Offset(180, 120),
      boardSide: 320,
      piece: piece,
    );

    expect(origin, const GridPoint(2, 3));
  });

  test('snaps to the nearest board origin during a slightly uneven drag', () {
    const piece = Piece(id: 'single', cells: [GridPoint(0, 0)]);

    final origin = DragPlacementMapper.originForCenter(
      localCenter: const Offset(101, 139),
      boardSide: 320,
      piece: piece,
    );

    expect(origin, const GridPoint(3, 2));
  });
}
