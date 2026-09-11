import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static const _effectPlayerCount = 4;
  final List<AudioPlayer> _effects =
      List.generate(_effectPlayerCount, (_) => AudioPlayer());
  final AudioPlayer _music = AudioPlayer();
  int _nextEffect = 0;
  bool _startingMusic = false;
  bool _pausedByLifecycle = false;
  bool _persistentDuck = false;
  bool _temporaryDuck = false;
  Timer? _duckTimer;
  bool enabled = true;
  bool musicEnabled = true;
  double effectsVolume = .85;
  double musicVolume = .55;

  static const _audioAssets = [
    'audio/place.mp3',
    'audio/clear.mp3',
    'audio/combo.mp3',
    'audio/explosion.mp3',
    'audio/gold.mp3',
    'audio/game_over.mp3',
    'audio/button.mp3',
    'audio/achievement.mp3',
    'audio/music.mp3',
  ];

  static const Map<String, double> _effectVolumes = {
    'place': .62,
    'clear': .78,
    'combo': .80,
    'explosion': .88,
    'gold': .76,
    'game_over': .82,
    'button': .52,
    'achievement': .78,
  };

  Future<void> initialize() async {
    try {
      await AudioCache.instance.loadAll(_audioAssets);
    } catch (_) {
      // A missing optional sound must not prevent the app from starting.
    }
  }

  Future<void> play(String name) async {
    if (!enabled) return;
    try {
      final player = _effects[_nextEffect];
      _nextEffect = (_nextEffect + 1) % _effects.length;
      await player.play(
        AssetSource('audio/$name.mp3'),
        volume: (_effectVolumes[name] ?? .75) * effectsVolume,
      );
    } catch (_) {
      // Audio must never interrupt gameplay if a platform decoder fails.
    }
  }

  Future<void> playMusic() async {
    if (!musicEnabled || _pausedByLifecycle || _startingMusic) return;
    _startingMusic = true;
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.play(
        AssetSource('audio/music.mp3'),
        volume: _effectiveMusicVolume,
      );
    } catch (_) {
      // Optional placeholder music can be supplied later.
    } finally {
      _startingMusic = false;
    }
  }

  double get _effectiveMusicVolume =>
      .35 * musicVolume * ((_persistentDuck || _temporaryDuck) ? .28 : 1);

  Future<void> syncMusicPreference() async {
    if (!musicEnabled) {
      await _music.stop();
    } else if (!_pausedByLifecycle && _music.state != PlayerState.playing) {
      await playMusic();
    } else {
      await _music.setVolume(_effectiveMusicVolume);
    }
  }

  Future<void> pauseForLifecycle() async {
    _pausedByLifecycle = _music.state == PlayerState.playing;
    if (_pausedByLifecycle) await _music.pause();
  }

  Future<void> resumeAfterLifecycle() async {
    if (!_pausedByLifecycle) return;
    _pausedByLifecycle = false;
    await syncMusicPreference();
  }

  Future<void> setDucked(bool value) async {
    _persistentDuck = value;
    if (_music.state == PlayerState.playing) {
      await _music.setVolume(_effectiveMusicVolume);
    }
  }

  Future<void> duckFor(Duration duration) async {
    _duckTimer?.cancel();
    _temporaryDuck = true;
    if (_music.state == PlayerState.playing) {
      await _music.setVolume(_effectiveMusicVolume);
    }
    _duckTimer = Timer(duration, () async {
      _temporaryDuck = false;
      if (_music.state == PlayerState.playing) {
        await _music.setVolume(_effectiveMusicVolume);
      }
    });
  }

  Future<void> dispose() async {
    _duckTimer?.cancel();
    for (final player in _effects) {
      await player.dispose();
    }
    await _music.dispose();
  }
}
