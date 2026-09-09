import 'package:flutter/material.dart';

abstract final class GameConstants {
  static const boardSize = 8;
  static const goldBonus = 250;
  static const continueCellsToClear = 8;
  static const interstitialEveryGames = 3;
}

abstract final class RushPalette {
  static const ink = Color(0xFF34211D);
  static const canvas = Color(0xFFFFFAED);
  static const sand = Color(0xFFF3E5C5);
  static const surface = Color(0xFFFFFDF6);
  static const coral = Color(0xFFD7352A);
  static const violet = Color(0xFFD7352A);
  static const mint = Color(0xFF168C83);
  static const gold = Color(0xFFE0A11A);
  static const ice = Color(0xFF68BBD0);
  static const board = Color(0xFF3E2925);
  static const felt = Color(0xFF8F201C);
}
