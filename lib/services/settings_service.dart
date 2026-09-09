import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import 'storage_service.dart';

class SettingsService extends ChangeNotifier {
  SettingsService(this._storage) {
    value = AppSettings(
      sound: _storage.getBool('sound', true),
      music: _storage.getBool('music', true),
      vibration: _storage.getBool('vibration', true),
      notifications: _storage.getBool('notifications', true),
      locale: Locale(_storage.getString('locale') ?? 'en'),
    );
  }
  final StorageService _storage;
  late AppSettings value;

  Future<void> update(AppSettings next) async {
    value = next;
    await Future.wait([
      _storage.setBool('sound', next.sound),
      _storage.setBool('music', next.music),
      _storage.setBool('vibration', next.vibration),
      _storage.setBool('notifications', next.notifications),
      _storage.setString('locale', next.locale.languageCode),
    ]);
    notifyListeners();
  }
}
