import 'package:flutter/material.dart';

import 'storage_service.dart';

enum JourneyTheme { alaToo, issykKul, osh }

class JourneyThemeDefinition {
  const JourneyThemeDefinition({
    required this.theme,
    required this.requiredLines,
    required this.canvas,
    required this.sand,
    required this.accent,
  });

  final JourneyTheme theme;
  final int requiredLines;
  final Color canvas;
  final Color sand;
  final Color accent;
}

class ProgressionService extends ChangeNotifier {
  ProgressionService(this._storage);
  final StorageService _storage;

  static const themes = [
    JourneyThemeDefinition(
      theme: JourneyTheme.alaToo,
      requiredLines: 0,
      canvas: Color(0xFFFFFAED),
      sand: Color(0xFFF3E5C5),
      accent: Color(0xFFD7352A),
    ),
    JourneyThemeDefinition(
      theme: JourneyTheme.issykKul,
      requiredLines: 100,
      canvas: Color(0xFFF1FBFF),
      sand: Color(0xFFCFEAF0),
      accent: Color(0xFF147F9A),
    ),
    JourneyThemeDefinition(
      theme: JourneyTheme.osh,
      requiredLines: 300,
      canvas: Color(0xFFFFF4E8),
      sand: Color(0xFFF1D2A7),
      accent: Color(0xFFB94924),
    ),
  ];

  JourneyThemeDefinition get selected {
    final id = _storage.getString('journeyTheme');
    return themes.firstWhere(
      (item) => item.theme.name == id && isUnlocked(item),
      orElse: () => themes.first,
    );
  }

  int get totalLines => _storage.getInt('totalLines');
  int get coins => _storage.getInt('coins');

  bool isUnlocked(JourneyThemeDefinition item) =>
      totalLines >= item.requiredLines;

  Future<bool> select(JourneyThemeDefinition item) async {
    if (!isUnlocked(item)) return false;
    await _storage.setString('journeyTheme', item.theme.name);
    notifyListeners();
    return true;
  }

  void refresh() => notifyListeners();
}
