import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static const _effectPlayerCount = 4;
  final List<AudioPlayer> _effects =
      List.generate(_effectPlayerCount, (_) => AudioPlayer());
  final AudioPlayer _music = AudioPlayer();
  int _nextEffect = 0;
  bool enabled = true;
  bool musicEnabled = true;

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

  Future<void> play(String name) async {
    if (!enabled) return;
    try {
      final player = _effects[_nextEffect];
      _nextEffect = (_nextEffect + 1) % _effects.length;
      await player.play(
        AssetSource('audio/$name.mp3'),
        volume: _effectVolumes[name] ?? .75,
      );
    } catch (_) {
      // Audio must never interrupt gameplay if a platform decoder fails.
    }
  }

  Future<void> playMusic() async {
    if (!musicEnabled) return;
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.play(AssetSource('audio/music.mp3'), volume: .35);
    } catch (_) {
      // Optional placeholder music can be supplied later.
    }
  }

  Future<void> syncMusicPreference() async {
    if (!musicEnabled) {
      await _music.stop();
    } else if (_music.state != PlayerState.playing) {
      await playMusic();
    }
  }

  Future<void> dispose() async {
    for (final player in _effects) {
      await player.dispose();
    }
    await _music.dispose();
  }
}
