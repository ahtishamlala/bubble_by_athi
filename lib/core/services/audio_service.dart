import 'package:flutter/services.dart';

/// Centralized Audio and Tactile Feedback Service for 6 in 1 Games
class AudioService {
  static final AudioService instance = AudioService._internal();
  factory AudioService() => instance;
  AudioService._internal();

  bool isMuted = false;

  void toggleMute() {
    isMuted = !isMuted;
  }

  /// Bubble Pop sound and impact
  void playPop({int combo = 1}) {
    if (isMuted) return;
    SystemSound.play(SystemSoundType.click);
    if (combo > 2) {
      HapticFeedback.heavyImpact();
    } else if (combo > 1) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  /// Bubble shooting / projectile launch
  void playShoot() {
    if (isMuted) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
  }

  /// Candy match / Block clear combo
  void playMatch({int combo = 1}) {
    if (isMuted) return;
    SystemSound.play(SystemSoundType.click);
    if (combo > 1) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  /// Button or menu tap
  void playClick() {
    if (isMuted) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
  }

  /// Victory / Level complete
  void playVictory() {
    if (isMuted) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 150), () {
      HapticFeedback.mediumImpact();
    });
  }

  /// Game over / Out of moves
  void playGameOver() {
    if (isMuted) return;
    HapticFeedback.heavyImpact();
  }
}
