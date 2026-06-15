import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color critical = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);

  static Color statusColor(BatteryHealthLevel level) {
    switch (level) {
      case BatteryHealthLevel.excellent:
        return primary;
      case BatteryHealthLevel.normal:
        return info;
      case BatteryHealthLevel.warning:
        return warning;
      case BatteryHealthLevel.critical:
        return critical;
    }
  }
}

enum BatteryHealthLevel {
  excellent,
  normal,
  warning,
  critical,
}
