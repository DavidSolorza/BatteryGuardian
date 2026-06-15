import '../../features/battery/models/battery_info.dart';
import 'battery_status_helper.dart';

class CareTip {
  const CareTip({
    required this.title,
    required this.message,
    required this.icon,
    required this.priority,
  });

  final String title;
  final String message;
  final String icon;
  final int priority;
}

abstract final class BatteryCareAdvisor {
  static CareTip? bestTip({
    required BatteryInfo info,
    required int alertLevel,
    required bool isPluggedIn,
  }) {
    final tips = <CareTip>[];

    final temp = info.temperature;
    if (temp != null && temp >= 42) {
      tips.add(
        CareTip(
          title: 'Temperatura alta',
          message:
              'A ${temp.toStringAsFixed(1)}°C. Quita la funda, aleja de sol '
              'y deja enfriar antes de seguir cargando.',
          icon: 'thermostat',
          priority: 100,
        ),
      );
    } else if (temp != null && temp >= 38 && isPluggedIn) {
      tips.add(
        CareTip(
          title: 'Calor moderado',
          message:
              'La batería se está calentando. Cargar con menos brillo '
              'ayuda a mantenerla fresca.',
          icon: 'device_thermostat',
          priority: 70,
        ),
      );
    }

    if (isPluggedIn && info.level >= alertLevel) {
      tips.add(
        CareTip(
          title: 'Objetivo alcanzado',
          message:
              'Llegaste al $alertLevel%. Desconecta ahora para evitar '
              'desgaste por carga prolongada.',
          icon: 'power_off',
          priority: 95,
        ),
      );
    } else if (isPluggedIn && info.level >= alertLevel - 10) {
      tips.add(
        CareTip(
          title: 'Casi en el objetivo',
          message:
              'Vas al ${info.level}%. Prepárate para desconectar al '
              '$alertLevel% y cuidar la batería.',
          icon: 'flag',
          priority: 60,
        ),
      );
    }

    if (isPluggedIn && info.level >= 95 && info.level < alertLevel) {
      tips.add(
        CareTip(
          title: 'Carga elevada',
          message:
              'Mantener el teléfono al ${info.level}% conectado mucho tiempo '
              'acelera el desgaste. Desconecta cuando puedas.',
          icon: 'battery_alert',
          priority: 80,
        ),
      );
    }

    if (!isPluggedIn && info.level <= 15) {
      tips.add(
        CareTip(
          title: 'Batería crítica',
          message:
              'Queda ${info.level}%. Evita que llegue a 0% — conecta pronto '
              'para proteger las celdas.',
          icon: 'battery_0_bar',
          priority: 90,
        ),
      );
    } else if (!isPluggedIn && info.level <= 25) {
      tips.add(
        CareTip(
          title: 'Batería baja',
          message:
              'Al ${info.level}%. Las descargas profundas frecuentes '
              'reducen la vida útil.',
          icon: 'battery_2_bar',
          priority: 55,
        ),
      );
    }

    if (isPluggedIn &&
        info.connectedDuration > const Duration(hours: 2) &&
        info.level >= 80) {
      tips.add(
        CareTip(
          title: 'Carga prolongada',
          message:
              'Llevas ${info.connectedDuration.inHours}h+ conectado al '
              '${info.level}%. Desconectar ahora ayuda a la longevidad.',
          icon: 'timer',
          priority: 75,
        ),
      );
    }

    final hour = DateTime.now().hour;
    if (isPluggedIn && (hour >= 23 || hour < 6) && info.level >= 70) {
      tips.add(
        CareTip(
          title: 'Carga nocturna',
          message:
              'Cargar de noche al 100% estresa la batería. Usa tu objetivo '
              'de $alertLevel% y desconecta al alcanzarlo.',
          icon: 'bedtime',
          priority: 65,
        ),
      );
    }

    if (tips.isEmpty) {
      if (isPluggedIn && info.level < 80) {
        return const CareTip(
          title: 'Carga saludable',
          message:
              'Cargar entre 20% y 80% es ideal. Sigue así para '
              'alargar la vida de tu batería.',
          icon: 'thumb_up',
          priority: 10,
        );
      }
      if (!isPluggedIn && info.level >= 40 && info.level <= 80) {
        return const CareTip(
          title: 'Rango óptimo',
          message:
              'Tu batería está en zona saludable (40-80%). '
              'Es el mejor rango para el día a día.',
          icon: 'eco',
          priority: 10,
        );
      }
      return const CareTip(
        title: 'Monitoreo activo',
        message:
            'Battery Guardian vigila temperatura, carga y hábitos '
            'para ayudarte a cuidar tu batería.',
        icon: 'shield',
        priority: 5,
      );
    }

    tips.sort((a, b) => b.priority.compareTo(a.priority));
    return tips.first;
  }

  static String? estimatedTimeRemaining({
    required BatteryInfo info,
    required bool isPluggedIn,
    required int alertLevel,
  }) {
    if (isPluggedIn) return null;
    if (info.level <= 0) return null;

    // Rough heuristic: ~1% per 3-5 min of mixed use (no extra sensors).
    final minutesLeft = (info.level * 4).clamp(15, 600);
    if (minutesLeft >= 60) {
      final hours = minutesLeft ~/ 60;
      final mins = minutesLeft % 60;
      return mins > 0 ? '~${hours}h ${mins}min' : '~${hours}h';
    }
    return '~${minutesLeft}min';
  }

  static String? estimatedChargeEta({
    required BatteryInfo info,
    required int alertLevel,
    required DateTime? chargingStartedAt,
    required int? startLevel,
  }) {
    if (!BatteryStatusHelper.isPluggedIn(info.state)) return null;
    if (info.level >= alertLevel) return 'Objetivo alcanzado';
    if (chargingStartedAt == null || startLevel == null) return null;

    final gain = info.level - startLevel;
    final minutes = DateTime.now().difference(chargingStartedAt).inMinutes;
    if (gain <= 0 || minutes < 3) return 'Calculando...';

    final rate = gain / minutes;
    if (rate <= 0) return null;
    final remaining = ((alertLevel - info.level) / rate).ceil();
    if (remaining <= 0) return 'Casi listo';
    if (remaining >= 60) return '~${remaining ~/ 60}h ${remaining % 60}min';
    return '~$remaining min';
  }
}
