import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_services.dart';
import '../utils/game_constants.dart';

class MenuButton extends StatelessWidget {
  const MenuButton(
      {required this.icon,
      required this.label,
      required this.onTap,
      super.key});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FilledButton.tonalIcon(
          style: FilledButton.styleFrom(
            backgroundColor: RushPalette.surface,
            foregroundColor: RushPalette.ink,
            side: const BorderSide(color: RushPalette.coral, width: 1.2),
          ),
          onPressed: () {
            unawaited(AppServices.of(context).audio.play('button'));
            onTap();
          },
          icon: Icon(icon, color: RushPalette.coral),
          label: Text(label),
        ),
      );
}
