import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum RpgSfx {
  hit('sfx/hit.wav'),
  breath('sfx/breath.wav'),
  chest('sfx/chest.wav'),
  levelUp('sfx/levelup.wav');

  const RpgSfx(this.assetPath);
  final String assetPath;
}

/// Toggleable cross-platform SFX player using tiny bundled WAV effects.
class RpgSfxService {
  AudioPlayer? _player;

  bool get _hasPlatformBinding {
    try {
      ServicesBinding.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> play(RpgSfx sfx, {required bool enabled}) async {
    if (!enabled || !_hasPlatformBinding) return;
    try {
      final player = _player ??= AudioPlayer();
      await player.stop();
      await player.play(AssetSource(sfx.assetPath), volume: 0.55);
    } catch (_) {
      // Safe no-op in headless tests or unsupported audio devices.
    }
  }

  void dispose() {
    _player?.dispose();
    _player = null;
  }
}
