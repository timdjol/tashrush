import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _effects = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();
  bool enabled = true;
  bool musicEnabled = true;
  Future<void> play(String name) async {
    if (!enabled) return;
    try {
      await _effects.play(AssetSource('audio/$name.mp3'));
    } catch (_) {
      // Placeholder assets can be added without changing gameplay code.
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
    await _effects.dispose();
    await _music.dispose();
  }
}
