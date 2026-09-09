import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class HapticService {
  bool enabled = true;
  Future<void> light() async {
    if (enabled) await HapticFeedback.selectionClick();
  }

  Future<void> medium() async {
    if (enabled) await HapticFeedback.mediumImpact();
  }

  Future<void> strong() async {
    if (!enabled) return;
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(duration: 120, amplitude: 180);
    } else {
      await HapticFeedback.heavyImpact();
    }
  }
}
