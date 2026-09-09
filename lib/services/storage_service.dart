import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService(this._preferences);
  final SharedPreferences _preferences;

  static Future<StorageService> create() async =>
      StorageService(await SharedPreferences.getInstance());

  int getInt(String key, [int fallback = 0]) =>
      _preferences.getInt(key) ?? fallback;
  bool getBool(String key, [bool fallback = false]) =>
      _preferences.getBool(key) ?? fallback;
  String? getString(String key) => _preferences.getString(key);
  List<String> getStringList(String key) =>
      _preferences.getStringList(key) ?? const [];
  Future<void> setInt(String key, int value) => _preferences.setInt(key, value);
  Future<void> setBool(String key, bool value) =>
      _preferences.setBool(key, value);
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);
  Future<void> setStringList(String key, List<String> value) =>
      _preferences.setStringList(key, value);
  Future<void> setJson(String key, Map<String, Object?> value) =>
      setString(key, jsonEncode(value));
  Map<String, Object?>? getJson(String key) {
    final source = getString(key);
    if (source == null) return null;
    return jsonDecode(source) as Map<String, Object?>;
  }
}
