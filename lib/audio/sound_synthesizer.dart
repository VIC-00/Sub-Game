import 'package:flutter/services.dart';
import 'sound_impl_stub.dart'
    if (dart.library.js_interop) 'sound_impl_web.dart';

class SoundSynthesizer {
  static bool soundEnabled = true;
  static bool hapticsEnabled = true;

  /// Triggered on standard soft tap ping
  static void playPing() {
    if (soundEnabled) {
      platformPlayPing(false);
    }
    if (hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// Proximity heartbeat when danger is near
  static void playHeartbeat() {
    if (soundEnabled) {
      platformPlayHeartbeat();
    }
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// Triggered on charged loud ping (heavy acoustic signature)
  static void playLoudPing() {
    if (soundEnabled) {
      platformPlayPing(true);
    }
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Triggered on acoustic decoy launched
  static void playDecoy() {
    if (soundEnabled) {
      platformPlayDecoy();
    }
    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Triggered when ancient relic data core is salvaged
  static void playRelicCollected() {
    if (soundEnabled) {
      platformPlayRelic();
    }
    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Triggered when the submarine hull collides or gets attacked
  static void playHullImpact() {
    if (soundEnabled) {
      platformPlayImpact();
    }
    if (hapticsEnabled) {
      HapticFeedback.vibrate();
    }
  }

  /// Triggered when the blind leviathan detects a loud ping
  static void playMonsterAlert() {
    if (soundEnabled) {
      platformPlayMonsterRoar();
    }
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
  }
}
