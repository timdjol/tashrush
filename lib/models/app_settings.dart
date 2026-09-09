import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    this.sound = true,
    this.music = true,
    this.vibration = true,
    this.notifications = true,
    this.locale = const Locale('en'),
  });
  final bool sound;
  final bool music;
  final bool vibration;
  final bool notifications;
  final Locale locale;

  AppSettings copyWith({
    bool? sound,
    bool? music,
    bool? vibration,
    bool? notifications,
    Locale? locale,
  }) =>
      AppSettings(
        sound: sound ?? this.sound,
        music: music ?? this.music,
        vibration: vibration ?? this.vibration,
        notifications: notifications ?? this.notifications,
        locale: locale ?? this.locale,
      );
}
