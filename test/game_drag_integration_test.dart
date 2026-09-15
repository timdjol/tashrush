import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tash_rush/game/mechanics/game_session.dart';
import 'package:tash_rush/game/pieces/piece_catalog.dart';
import 'package:tash_rush/screens/game/game_screen.dart';
import 'package:tash_rush/screens/game/piece_preview.dart';
import 'package:tash_rush/utils/game_constants.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('dragging a tray piece onto the board persists a move',
      (tester) async {
    final initialSession = GameSession(
      initialPieces: [PieceCatalog.byId('single')],
    );
    final services = await TestAppServices.create(
      preferences: {
        'tutorialSeen': true,
        'active_classic_game': jsonEncode({
          'date': '',
          'session': initialSession.toJson(),
        }),
      },
    );
    await tester.pumpWidget(services.wrap(const GameScreen()));
    await tester.pump(const Duration(seconds: 1));

    final piece = find.byType(Draggable<int>).first;
    final board = find.byType(DragTarget<int>);
    expect(piece, findsOneWidget);
    expect(board, findsOneWidget);

    final pieceModel = tester
        .widget<PiecePreview>(
          find.descendant(of: piece, matching: find.byType(PiecePreview)).first,
        )
        .piece;
    final boardRect = tester.getRect(board);
    final cellSize = boardRect.width / GameConstants.boardSize;
    final validOriginPointer = boardRect.topLeft +
        Offset(
          pieceModel.width * cellSize / 2,
          pieceModel.height * cellSize / 2 + 64,
        );
    final gesture = await tester.startGesture(tester.getCenter(piece));
    await gesture.moveTo(validOriginPointer);
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));

    final snapshot = services.storage.getJson('active_classic_game');
    final session = Map<String, Object?>.from(snapshot!['session']! as Map);
    final stats = Map<String, Object?>.from(session['stats']! as Map);
    expect((stats['score'] as num).toInt(), greaterThan(0));
    services.ads.dispose();
  });
}
