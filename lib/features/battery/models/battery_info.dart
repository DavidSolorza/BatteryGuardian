import 'package:battery_plus/battery_plus.dart';

class BatteryInfo {
  const BatteryInfo({
    required this.level,
    required this.state,
    this.temperature,
    this.voltage,
    this.health,
    this.technology,
    this.connectedDuration = Duration.zero,
    this.temperatureSamples = const [],
  });

  final int level;
  final BatteryState state;
  final double? temperature;
  final double? voltage;
  final int? health;
  final String? technology;
  final Duration connectedDuration;
  final List<double> temperatureSamples;

  BatteryInfo copyWith({
    int? level,
    BatteryState? state,
    double? temperature,
    double? voltage,
    int? health,
    String? technology,
    Duration? connectedDuration,
    List<double>? temperatureSamples,
  }) {
    return BatteryInfo(
      level: level ?? this.level,
      state: state ?? this.state,
      temperature: temperature ?? this.temperature,
      voltage: voltage ?? this.voltage,
      health: health ?? this.health,
      technology: technology ?? this.technology,
      connectedDuration: connectedDuration ?? this.connectedDuration,
      temperatureSamples: temperatureSamples ?? this.temperatureSamples,
    );
  }

  static BatteryInfo initial() => const BatteryInfo(
        level: 0,
        state: BatteryState.unknown,
      );

  bool hasUiChangedFrom(BatteryInfo other) {
    if (level != other.level || state != other.state) return true;

    final tempA = temperature?.toStringAsFixed(1);
    final tempB = other.temperature?.toStringAsFixed(1);
    if (tempA != tempB) return true;

    final voltA = voltage?.toStringAsFixed(2);
    final voltB = other.voltage?.toStringAsFixed(2);
    if (voltA != voltB) return true;

    if (connectedDuration.inMinutes != other.connectedDuration.inMinutes) {
      return true;
    }

    return false;
  }

  bool hasAlertRelevantChangeFrom(BatteryInfo other) {
    return level != other.level ||
        state != other.state ||
        temperature?.round() != other.temperature?.round();
  }
}
