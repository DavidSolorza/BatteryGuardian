import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../../features/battery/models/battery_info.dart';

class BatteryService {
  BatteryService({Battery? battery}) : _battery = battery ?? Battery();

  final Battery _battery;
  static const _platform = MethodChannel(AppConstants.batteryChannel);

  Stream<BatteryState> get onBatteryStateChanged =>
      _battery.onBatteryStateChanged;

  Future<BatteryInfo> fetchBatteryInfo({
    Duration? connectedDuration,
    List<double>? temperatureSamples,
  }) async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    final details = await _fetchNativeDetails();

    return BatteryInfo(
      level: level,
      state: state,
      temperature: details.temperature,
      voltage: details.voltage,
      health: details.health,
      technology: details.technology,
      connectedDuration: connectedDuration ?? Duration.zero,
      temperatureSamples: temperatureSamples ?? const [],
    );
  }

  Future<_NativeBatteryDetails> _fetchNativeDetails() async {
    try {
      final result = await _platform.invokeMethod<Map<dynamic, dynamic>>(
        'getBatteryDetails',
      );
      if (result == null) return const _NativeBatteryDetails();

      return _NativeBatteryDetails(
        temperature: (result['temperature'] as num?)?.toDouble(),
        voltage: (result['voltage'] as num?)?.toDouble(),
        health: result['health'] as int?,
        technology: result['technology'] as String?,
      );
    } on PlatformException {
      return const _NativeBatteryDetails();
    }
  }
}

class _NativeBatteryDetails {
  const _NativeBatteryDetails({
    this.temperature,
    this.voltage,
    this.health,
    this.technology,
  });

  final double? temperature;
  final double? voltage;
  final int? health;
  final String? technology;
}
