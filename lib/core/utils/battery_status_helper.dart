import 'package:battery_plus/battery_plus.dart';

import '../theme/app_colors.dart';
import '../../features/battery/models/battery_info.dart';

abstract final class BatteryStatusHelper {
  static BatteryHealthLevel resolveHealthLevel(BatteryInfo info) {
    final temp = info.temperature;
    final level = info.level;

    if (level >= 95 || (temp != null && temp >= 45)) {
      return BatteryHealthLevel.critical;
    }
    if (level >= 80 || (temp != null && temp >= 40)) {
      return BatteryHealthLevel.warning;
    }
    if (level >= 50 && (temp == null || temp < 40)) {
      return BatteryHealthLevel.normal;
    }
    if (level < 20) {
      return BatteryHealthLevel.warning;
    }
    return BatteryHealthLevel.excellent;
  }

  static String healthLabel(BatteryHealthLevel level) {
    switch (level) {
      case BatteryHealthLevel.excellent:
        return 'Excelente';
      case BatteryHealthLevel.normal:
        return 'Normal';
      case BatteryHealthLevel.warning:
        return 'Advertencia';
      case BatteryHealthLevel.critical:
        return 'Crítico';
    }
  }

  static String stateLabel(BatteryState state) {
    switch (state) {
      case BatteryState.charging:
        return 'Cargando';
      case BatteryState.discharging:
        return 'Descargando';
      case BatteryState.full:
        return 'Completa';
      case BatteryState.connectedNotCharging:
        return 'Conectado sin carga';
      case BatteryState.unknown:
        return 'Desconocido';
    }
  }

  static bool isCharging(BatteryState state) {
    return state == BatteryState.charging || state == BatteryState.full;
  }
}
