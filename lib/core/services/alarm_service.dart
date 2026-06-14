import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

import '../constants/app_constants.dart';

class AlarmService {
  AlarmService();

  final AudioPlayer _player = AudioPlayer();
  Timer? _vibrationTimer;
  Timer? _soundTimer;
  bool _isActive = false;

  bool get isActive => _isActive;

  Future<void> start({
    required bool soundEnabled,
    required bool vibrationEnabled,
    String soundAsset = 'sounds/alarm.wav',
  }) async {
    if (_isActive) return;
    _isActive = true;

    if (soundEnabled) {
      await _playSound(soundAsset);
      _soundTimer = Timer.periodic(AppConstants.alarmRepeatInterval, (_) {
        _playSound(soundAsset);
      });
    }

    if (vibrationEnabled) {
      await _vibrate();
      _vibrationTimer = Timer.periodic(AppConstants.alarmRepeatInterval, (_) {
        _vibrate();
      });
    }
  }

  Future<void> stop() async {
    _isActive = false;
    _soundTimer?.cancel();
    _vibrationTimer?.cancel();
    _soundTimer = null;
    _vibrationTimer = null;
    await _player.stop();
    if (await Vibration.hasVibrator() == true) {
      await Vibration.cancel();
    }
  }

  Future<void> _playSound(String asset) async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(asset));
    } catch (_) {
      // Asset may be missing on some builds; alarm continues via vibration.
    }
  }

  Future<void> _vibrate() async {
    if (await Vibration.hasVibrator() == true) {
      await Vibration.vibrate(
        pattern: [0, 500, 200, 500],
        intensities: [0, 255, 0, 255],
      );
    }
  }

  void dispose() {
    stop();
    _player.dispose();
  }
}
