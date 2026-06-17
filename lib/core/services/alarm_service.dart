import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

import '../constants/app_constants.dart';
import 'custom_sound_service.dart';

class AlarmService {
  AlarmService();

  final AudioPlayer _player = AudioPlayer();
  Timer? _vibrationTimer;
  Timer? _previewTimer;
  Timer? _timeoutTimer;
  bool _isActive = false;

  bool get isActive => _isActive;

  Future<void> start({
    required bool soundEnabled,
    required bool vibrationEnabled,
    String soundPath = 'sounds/alarm.wav',
    Duration? timeout,
  }) async {
    if (_isActive) return;
    _isActive = true;

    if (soundEnabled) {
      await _playSound(soundPath, loop: true);
    }

    if (vibrationEnabled) {
      await _vibrate();
      _vibrationTimer = Timer.periodic(AppConstants.alarmRepeatInterval, (_) {
        _vibrate();
      });
    }

    _timeoutTimer = Timer(timeout ?? const Duration(minutes: 10), stop);
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
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    _previewTimer?.cancel();
    _previewTimer = null;
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.release);
    if (await Vibration.hasVibrator() == true) {
      await Vibration.cancel();
    }
  }

  Future<void> _playSound(String path, {required bool loop}) async {
    try {
      final source = _soundSource(path);
      await _player.stop();
      await _player.setSource(source);
      await _player.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.release,
      );
      await _player.resume();
    } catch (_) {
    }
  }

  Source _soundSource(String path) {
    if (CustomSoundService.isLocalPath(path)) {
      final filePath = CustomSoundService.localFilePath(path);
      return DeviceFileSource(filePath);
    }
    final assetPath = path.startsWith('assets/')
        ? path.replaceFirst('assets/', '')
        : path;
    return AssetSource(assetPath);
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
