class ChargingSessionModel {
  const ChargingSessionModel({
    this.id,
    required this.startTime,
    this.endTime,
    required this.startLevel,
    this.endLevel,
    this.avgTemperature,
    this.durationMinutes,
  });

  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final int startLevel;
  final int? endLevel;
  final double? avgTemperature;
  final int? durationMinutes;

  bool get isComplete => endTime != null && endLevel != null;

  Duration get duration {
    if (durationMinutes != null) {
      return Duration(minutes: durationMinutes!);
    }
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return Duration.zero;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'start_level': startLevel,
      'end_level': endLevel,
      'avg_temperature': avgTemperature,
      'duration_minutes': durationMinutes,
    };
  }

  factory ChargingSessionModel.fromMap(Map<String, dynamic> map) {
    return ChargingSessionModel(
      id: map['id'] as int?,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
          : null,
      startLevel: map['start_level'] as int,
      endLevel: map['end_level'] as int?,
      avgTemperature: (map['avg_temperature'] as num?)?.toDouble(),
      durationMinutes: map['duration_minutes'] as int?,
    );
  }

  ChargingSessionModel copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    int? startLevel,
    int? endLevel,
    double? avgTemperature,
    int? durationMinutes,
  }) {
    return ChargingSessionModel(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startLevel: startLevel ?? this.startLevel,
      endLevel: endLevel ?? this.endLevel,
      avgTemperature: avgTemperature ?? this.avgTemperature,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}
