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
}
