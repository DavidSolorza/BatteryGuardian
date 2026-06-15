import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

import '../constants/app_constants.dart';
import 'custom_sound_service.dart';

class AlarmService {
  AlarmService();

  final AudioPlayer _player = AudioPlayer();
  Timer? _vibrationTimer;
  Timer? _soundTimer;
  Timer? _previewTimer;
  bool _isActive = false;

  bool get isActive => _isActive;

  Future<void> start({
    required bool soundEnabled,
    required bool vibrationEnabled,
    String soundPath = 'sounds/alarm.wav',
  }) async {
    if (_isActive) return;
    _isActive = true;

    if (soundEnabled) {
      await _playSound(soundPath, loop: true);
      _soundTimer = Timer.periodic(AppConstants.alarmRepeatInterval, (_) {
        _playSound(soundPath, loop: true);
      });
    }

    if (vibrationEnabled) {
      await _vibrate();
      _vibrationTimer = Timer.periodic(AppConstants.alarmRepeatInterval, (_) {
        _vibrate();
      });
    }
  }

  Future<void> preview({
    required String soundPath,
    required bool soundEnabled,
    required bool vibrationEnabled,
    Duration duration = const Duration(seconds: 3),
  }) async {
    await stopPreview();

    if (soundEnabled) {
      await _playSound(soundPath, loop: false);
    }
    if (vibrationEnabled) {
      await _vibrate();
    }

    _previewTimer = Timer(duration, stopPreview);
  }

  Future<void> stopPreview() async {
    _previewTimer?.cancel();
    _previewTimer = null;
    await _player.stop();
    if (await Vibration.hasVibrator() == true) {
      await Vibration.cancel();
    }
  }

  Future<void> stop() async {
    _isActive = false;
    _soundTimer?.cancel();
    _vibrationTimer?.cancel();
    _soundTimer = null;
    _vibrationTimer = null;
    await stopPreview();
  }

  Future<void> _playSound(String path, {required bool loop}) async {
    try {
      await _player.stop();
      await _player.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.release,
      );

      if (CustomSoundService.isLocalPath(path)) {
        final filePath = CustomSoundService.localFilePath(path);
        await _player.play(DeviceFileSource(filePath));
      } else {
        final assetPath = path.startsWith('assets/')
            ? path.replaceFirst('assets/', '')
            : path;
        await _player.play(AssetSource(assetPath));
      }
    } catch (_) {
      // Asset or file may be missing; alarm continues via vibration.
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
