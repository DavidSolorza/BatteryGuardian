import 'package:flutter/services.dart';

import '../constants/app_constants.dart';

class BackgroundMonitorService {
  BackgroundMonitorService();

  static const _channel = MethodChannel(AppConstants.batteryChannel);

  Future<void> start() async {
    try {
      await _channel.invokeMethod<void>('startBackgroundMonitoring');
    } on PlatformException {
      // Native service unavailable on this platform.
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stopBackgroundMonitoring');
    } on PlatformException {
      // Native service unavailable on this platform.
    }
  }

  Future<bool> isRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isBackgroundMonitoringRunning',
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> requestBatteryOptimizationExemption() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'requestBatteryOptimizationExemption',
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isBatteryOptimizationIgnored() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isBatteryOptimizationIgnored',
      );
      return result ?? true;
    } on PlatformException {
      return true;
    }
  }

  Future<void> stopNativeAlarm() async {
    try {
      await _channel.invokeMethod<void>('stopNativeAlarm');
    } on PlatformException {
      // Ignore on unsupported platforms.
    }
  }

  Future<bool> ensureRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'ensureBackgroundMonitoring',
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<String> drainNativeAlertEvents() async {
    try {
      final result = await _channel.invokeMethod<String>(
        'drainNativeAlertEvents',
      );
      return result ?? '[]';
    } on PlatformException {
      return '[]';
    }
  }

  Future<bool> isNativeAlarmActive() async {
    try {
      final result = await _channel.invokeMethod<bool>('isNativeAlarmActive');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
