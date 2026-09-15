import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tash_rush/screens/leaderboard/leaderboard_screen.dart';
import 'package:tash_rush/screens/privacy/privacy_screen.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('personal results screen shows real saved games', (tester) async {
    final services = await TestAppServices.create();
    await services.leaderboard.submit(2450, lines: 9, durationSeconds: 125);

    await tester.pumpWidget(services.wrap(const LeaderboardScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Personal results'), findsOneWidget);
    expect(find.text('2450'), findsOneWidget);
    expect(find.textContaining('Lines: 9'), findsOneWidget);
    expect(find.textContaining('Nova'), findsNothing);
    services.ads.dispose();
  });

  testWidgets('privacy screen explains local data and advertising',
      (tester) async {
    final services = await TestAppServices.create();

    await tester.pumpWidget(services.wrap(const PrivacyScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Local game data'), findsOneWidget);
    expect(find.text('Advertising'), findsOneWidget);
    expect(find.byIcon(Icons.privacy_tip_outlined), findsNothing);
    services.ads.dispose();
  });
}
