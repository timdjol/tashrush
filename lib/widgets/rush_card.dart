import 'package:flutter/material.dart';

import '../utils/game_constants.dart';

class RushCard extends StatelessWidget {
  const RushCard(
      {required this.child,
      this.padding = const EdgeInsets.all(20),
      super.key});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [RushPalette.surface, Color(0xFFFFF5DC)],
          ),
          border: Border.all(color: RushPalette.gold, width: 1.4),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2434211D),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: child,
      );
}
