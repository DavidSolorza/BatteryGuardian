import 'package:battery_plus/battery_plus.dart';

import '../../features/battery/models/battery_info.dart';
import 'battery_status_helper.dart';

class LiveChargeStats {
  const LiveChargeStats({
    required this.isActive,
    required this.currentLevel,
    required this.startLevel,
    required this.levelGain,
    required this.duration,
    required this.chargeRatePerHour,
    required this.estimatedMinutesToTarget,
    required this.targetLevel,
    this.temperature,
    this.state = BatteryState.unknown,
  });

  final bool isActive;
  final int currentLevel;
  final int startLevel;
  final int levelGain;
  final Duration duration;
  final double chargeRatePerHour;
  final int? estimatedMinutesToTarget;
  final int targetLevel;
  final double? temperature;
  final BatteryState state;

  static LiveChargeStats inactive({int targetLevel = 80}) => LiveChargeStats(
        isActive: false,
        currentLevel: 0,
        startLevel: 0,
        levelGain: 0,
        duration: Duration.zero,
        chargeRatePerHour: 0,
        estimatedMinutesToTarget: null,
        targetLevel: targetLevel,
      );
}

abstract final class ChargeMetrics {
  static LiveChargeStats fromSession({
    required BatteryInfo info,
    required DateTime? startedAt,
    required int? startLevel,
    required int targetLevel,
  }) {
    final pluggedIn = BatteryStatusHelper.isPluggedIn(info.state);

    if (startedAt == null || startLevel == null) {
      if (!pluggedIn) {
        return LiveChargeStats.inactive(targetLevel: targetLevel);
      }
      return LiveChargeStats(
        isActive: true,
        currentLevel: info.level,
        startLevel: info.level,
        levelGain: 0,
        duration: Duration.zero,
        chargeRatePerHour: 0,
        estimatedMinutesToTarget: null,
        targetLevel: targetLevel,
        temperature: info.temperature,
        state: info.state,
      );
    }

    final duration = DateTime.now().difference(startedAt);
    final gain = info.level - startLevel;
    final hours = duration.inSeconds / 3600;
    final rate = hours > 0.01 ? gain / hours : 0.0;
    final minutesToTarget = rate > 0.1 && info.level < targetLevel
        ? ((targetLevel - info.level) / rate * 60).round()
        : null;

    return LiveChargeStats(
      isActive: true,
      currentLevel: info.level,
      startLevel: startLevel,
      levelGain: gain,
      duration: duration,
      chargeRatePerHour: rate,
      estimatedMinutesToTarget: minutesToTarget,
      targetLevel: targetLevel,
      temperature: info.temperature,
      state: info.state,
    );
  }
}
