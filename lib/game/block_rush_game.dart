import 'package:flame/game.dart';

import '../models/game_models.dart';
import 'board/board.dart';
import 'board/board_component.dart';
import 'mechanics/game_session.dart';
import 'pieces/piece.dart';

class BlockRushGame extends FlameGame {
  BlockRushGame(this.session);
  GameSession session;
  late final BoardComponent boardComponent;

  @override
  Future<void> onLoad() async {
    boardComponent = BoardComponent(board: session.board);
    add(boardComponent);
    final side = size.x < size.y ? size.x : size.y;
    boardComponent
      ..size = Vector2.all(side)
      ..position = Vector2((size.x - side) / 2, 0);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final side = size.x < size.y ? size.x : size.y;
    if (isLoaded) {
      boardComponent
        ..size = Vector2.all(side)
        ..position = Vector2((size.x - side) / 2, 0);
    }
  }

  void refresh(GameSession value) {
    session = value;
    if (isLoaded) boardComponent.board = value.board;
  }

  void preview(Piece? piece, GridPoint? origin) {
    if (!isLoaded) return;
    boardComponent
      ..previewPiece = piece
      ..previewOrigin = origin;
  }

  void playClearEffect(ClearResult clear) {
    if (isLoaded) boardComponent.playClearEffect(clear);
  }
}
