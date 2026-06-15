import '../../database/sqlite/charging_session_model.dart';
import '../../features/battery/models/battery_info.dart';
import 'battery_status_helper.dart';

class BatteryHealthScore {
  const BatteryHealthScore({
    required this.score,
    required this.label,
    required this.detail,
  });

  final int score;
  final String label;
  final String detail;

  static BatteryHealthScore fromLiveState({
    required BatteryInfo info,
    required int alertLevel,
    required int? careHabitScore,
  }) {
    var score = 85;

    final temp = info.temperature;
    if (temp != null) {
      if (temp >= 45) {
        score -= 30;
      } else if (temp >= 40) {
        score -= 18;
      } else if (temp >= 38) {
        score -= 8;
      }
    }

    final plugged = BatteryStatusHelper.isPluggedIn(info.state);
    if (plugged) {
      if (info.level >= 100) {
        score -= 20;
      } else if (info.level > alertLevel + 5) {
        score -= 12;
      } else if (info.level > alertLevel) {
        score -= 6;
      }
      if (info.connectedDuration > const Duration(hours: 3)) {
        score -= 10;
      }
    } else {
      if (info.level <= 10) {
        score -= 25;
      } else if (info.level <= 20) {
        score -= 12;
      } else if (info.level >= 40 && info.level <= 80) {
        score += 8;
      }
    }

    if (careHabitScore != null) {
      score = ((score * 0.6) + (careHabitScore * 0.4)).round();
    }

    score = score.clamp(0, 100);
    return BatteryHealthScore(
      score: score,
      label: _label(score),
      detail: _detail(score, plugged, info.level),
    );
  }

  static int fromSessions(List<ChargingSessionModel> sessions) {
    if (sessions.isEmpty) return 50;

    final recent = sessions.take(15).toList();
    var score = 60;

    final optimalEnd = recent
        .where((s) {
          final end = s.endLevel ?? 0;
          return end >= 50 && end <= 90;
        })
        .length;
    score += ((optimalEnd / recent.length) * 25).round();

    final avoidedFull = recent.where((s) => (s.endLevel ?? 0) < 98).length;
    score += ((avoidedFull / recent.length) * 15).round();

    final longSessions = recent
        .where((s) => s.duration > const Duration(hours: 4))
        .length;
    score -= longSessions * 4;

    return score.clamp(0, 100);
  }

  static String _label(int score) {
    if (score >= 85) return 'Excelente';
    if (score >= 70) return 'Bueno';
    if (score >= 50) return 'Regular';
    return 'Mejorable';
  }

  static String _detail(int score, bool plugged, int level) {
    if (score >= 85) {
      return 'Tus hábitos de carga ayudan a prolongar la batería.';
    }
    if (plugged && level >= 90) {
      return 'Desconecta pronto para mejorar tu puntuación.';
    }
    if (!plugged && level <= 20) {
      return 'Evita descargas profundas frecuentes.';
    }
    return 'Sigue las recomendaciones para mejorar.';
  }
}

abstract final class QuietHoursHelper {
  static bool isActive({
    required bool enabled,
    required int startHour,
    required int endHour,
  }) {
    if (!enabled) return false;
    final hour = DateTime.now().hour;
    if (startHour == endHour) return false;
    if (startHour < endHour) {
      return hour >= startHour && hour < endHour;
    }
    return hour >= startHour || hour < endHour;
  }
}
