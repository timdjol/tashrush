import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    this.sound = true,
    this.music = true,
    this.vibration = true,
    this.notifications = true,
    this.soundVolume = .85,
    this.musicVolume = .55,
    this.locale = const Locale('en'),
  });
  final bool sound;
  final bool music;
  final bool vibration;
  final bool notifications;
  final double soundVolume;
  final double musicVolume;
  final Locale locale;

  AppSettings copyWith({
    bool? sound,
    bool? music,
    bool? vibration,
    bool? notifications,
    double? soundVolume,
    double? musicVolume,
    Locale? locale,
  }) =>
      AppSettings(
        sound: sound ?? this.sound,
        music: music ?? this.music,
        vibration: vibration ?? this.vibration,
        notifications: notifications ?? this.notifications,
        soundVolume: soundVolume ?? this.soundVolume,
        musicVolume: musicVolume ?? this.musicVolume,
        locale: locale ?? this.locale,
      );
}
