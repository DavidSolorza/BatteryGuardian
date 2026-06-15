import '../../providers/alerts_provider.dart';

class AlertEventModel {
  const AlertEventModel({
    this.id,
    required this.type,
    required this.message,
    required this.level,
    required this.timestamp,
  });

  final int? id;
  final AlertType type;
  final String message;
  final int level;
  final DateTime timestamp;

  bool get isPersisted => id != null;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'type': type.index,
        'message': message,
        'level': level,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory AlertEventModel.fromMap(Map<String, Object?> map) {
    return AlertEventModel(
      id: map['id'] as int?,
      type: AlertType.values[map['type'] as int],
      message: map['message'] as String,
      level: map['level'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  AlertRecord toRecord() => AlertRecord(
        type: type,
        message: message,
        timestamp: timestamp,
        level: level,
      );

  factory AlertEventModel.fromRecord(AlertRecord record) {
    return AlertEventModel(
      type: record.type,
      message: record.message,
      level: record.level,
      timestamp: record.timestamp,
    );
  }
}
