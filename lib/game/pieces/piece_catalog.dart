import '../../models/game_models.dart';
import 'piece.dart';

abstract final class PieceCatalog {
  static const pieces = <Piece>[
    Piece(id: 'single', cells: [GridPoint(0, 0)]),
    Piece(id: 'line2h', cells: [GridPoint(0, 0), GridPoint(0, 1)]),
    Piece(id: 'line2v', cells: [GridPoint(0, 0), GridPoint(1, 0)]),
    Piece(
        id: 'line3h',
        cells: [GridPoint(0, 0), GridPoint(0, 1), GridPoint(0, 2)]),
    Piece(
        id: 'line3v',
        cells: [GridPoint(0, 0), GridPoint(1, 0), GridPoint(2, 0)]),
    Piece(id: 'line4h', cells: [
      GridPoint(0, 0),
      GridPoint(0, 1),
      GridPoint(0, 2),
      GridPoint(0, 3)
    ]),
    Piece(id: 'line4v', cells: [
      GridPoint(0, 0),
      GridPoint(1, 0),
      GridPoint(2, 0),
      GridPoint(3, 0)
    ]),
    Piece(id: 'line5h', cells: [
      GridPoint(0, 0),
      GridPoint(0, 1),
      GridPoint(0, 2),
      GridPoint(0, 3),
      GridPoint(0, 4)
    ]),
    Piece(id: 'line5v', cells: [
      GridPoint(0, 0),
      GridPoint(1, 0),
      GridPoint(2, 0),
      GridPoint(3, 0),
      GridPoint(4, 0)
    ]),
    Piece(id: 'square2', cells: [
      GridPoint(0, 0),
      GridPoint(0, 1),
      GridPoint(1, 0),
      GridPoint(1, 1)
    ]),
    Piece(id: 'square3', cells: [
      GridPoint(0, 0),
      GridPoint(0, 1),
      GridPoint(0, 2),
      GridPoint(1, 0),
      GridPoint(1, 1),
      GridPoint(1, 2),
      GridPoint(2, 0),
      GridPoint(2, 1),
      GridPoint(2, 2)
    ]),
    Piece(id: 'l3', cells: [GridPoint(0, 0), GridPoint(1, 0), GridPoint(1, 1)]),
    Piece(
        id: 'l3_tr',
        cells: [GridPoint(0, 0), GridPoint(0, 1), GridPoint(1, 0)]),
    Piece(
        id: 'l3_bl',
        cells: [GridPoint(0, 1), GridPoint(1, 0), GridPoint(1, 1)]),
    Piece(
        id: 'l3_br',
        cells: [GridPoint(0, 0), GridPoint(0, 1), GridPoint(1, 1)]),
    Piece(id: 'l5', cells: [
      GridPoint(0, 0),
      GridPoint(1, 0),
      GridPoint(2, 0),
      GridPoint(2, 1),
      GridPoint(2, 2)
    ]),
    Piece(id: 'l5_tr', cells: [
      GridPoint(0, 0),
      GridPoint(0, 1),
      GridPoint(0, 2),
      GridPoint(1, 0),
      GridPoint(2, 0)
    ]),
    Piece(id: 'l5_bl', cells: [
      GridPoint(0, 2),
      GridPoint(1, 2),
      GridPoint(2, 0),
      GridPoint(2, 1),
      GridPoint(2, 2)
    ]),
    Piece(id: 'l5_br', cells: [
      GridPoint(0, 0),
      GridPoint(0, 1),
      GridPoint(0, 2),
      GridPoint(1, 2),
      GridPoint(2, 2)
    ]),
    Piece(id: 't4', cells: [
      GridPoint(0, 0),
      GridPoint(0, 1),
      GridPoint(0, 2),
      GridPoint(1, 1)
    ]),
    Piece(id: 't4_up', cells: [
      GridPoint(0, 1),
      GridPoint(1, 0),
      GridPoint(1, 1),
      GridPoint(1, 2)
    ]),
    Piece(id: 't4_left', cells: [
      GridPoint(0, 0),
      GridPoint(1, 0),
      GridPoint(1, 1),
      GridPoint(2, 0)
    ]),
    Piece(id: 't4_right', cells: [
      GridPoint(0, 1),
      GridPoint(1, 0),
      GridPoint(1, 1),
      GridPoint(2, 1)
    ]),
    Piece(id: 'corner4', cells: [
      GridPoint(0, 0),
      GridPoint(1, 0),
      GridPoint(2, 0),
      GridPoint(2, 1)
    ]),
    Piece(id: 'diagonal2', cells: [GridPoint(0, 0), GridPoint(1, 1)]),
    Piece(id: 'diagonal2_back', cells: [GridPoint(0, 1), GridPoint(1, 0)]),
    Piece(
        id: 'diagonal3',
        cells: [GridPoint(0, 0), GridPoint(1, 1), GridPoint(2, 2)]),
    Piece(
        id: 'diagonal3_back',
        cells: [GridPoint(0, 2), GridPoint(1, 1), GridPoint(2, 0)]),
    Piece(id: 'zigzag4', cells: [
      GridPoint(0, 1),
      GridPoint(0, 2),
      GridPoint(1, 0),
      GridPoint(1, 1)
    ]),
  ];

  static Piece byId(String id) => pieces.firstWhere(
        (piece) => piece.id == id,
        orElse: () => throw FormatException('Unknown piece: $id'),
      );
}
