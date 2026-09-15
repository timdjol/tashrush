import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tash_rush/screens/game/game_screen.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('dragging a tray piece onto the board persists a move',
      (tester) async {
    final services = await TestAppServices.create(
      preferences: {'tutorialSeen': true},
    );
    await tester.pumpWidget(services.wrap(const GameScreen()));
    await tester.pump(const Duration(seconds: 1));

    final piece = find.byType(Draggable<int>).first;
    final board = find.byType(DragTarget<int>);
    expect(piece, findsOneWidget);
    expect(board, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(piece));
    await gesture.moveTo(tester.getCenter(board) + const Offset(0, 64));
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
