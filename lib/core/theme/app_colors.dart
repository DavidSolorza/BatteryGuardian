import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color background = Color(0xFF0F172A);
  static const Color card = Color(0xFF1E293B);
  static const Color cardElevated = Color(0xFF334155);
  static const Color primary = Color(0xFF22C55E);
  static const Color primaryDark = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color critical = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color divider = Color(0xFF334155);
  static const Color shimmerBase = Color(0xFF1E293B);
  static const Color shimmerHighlight = Color(0xFF334155);

  static Color statusColor(BatteryHealthLevel level) {
    switch (level) {
      case BatteryHealthLevel.excellent:
        return primary;
      case BatteryHealthLevel.normal:
        return const Color(0xFF38BDF8);
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
