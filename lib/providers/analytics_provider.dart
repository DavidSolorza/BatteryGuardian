import 'package:flutter/foundation.dart';

import '../database/sqlite/charging_session_model.dart';
import '../database/sqlite/database_helper.dart';

class AnalyticsData {
  const AnalyticsData({
    this.avgChargeDuration = Duration.zero,
    this.dailyChargeCount = 0,
    this.fullChargeCount = 0,
    this.avgTemperature = 0,
    this.totalConnectedHours = 0,
    this.weeklyDurations = const [],
    this.monthlyDurations = const [],
    this.weeklyLabels = const [],
    this.monthlyLabels = const [],
  });

  final Duration avgChargeDuration;
  final int dailyChargeCount;
  final int fullChargeCount;
  final double avgTemperature;
  final double totalConnectedHours;
  final List<double> weeklyDurations;
  final List<double> monthlyDurations;
  final List<String> weeklyLabels;
  final List<String> monthlyLabels;
}

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsProvider({DatabaseHelper? databaseHelper})
      : _db = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  AnalyticsData _data = const AnalyticsData();
  bool _isLoading = true;
  String? _error;

  AnalyticsData get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAnalytics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final sessions = await _db.getAllSessions();
      final completed =
          sessions.where((s) => s.isComplete).toList(growable: false);

      _data = _computeAnalytics(completed);
    } catch (e) {
      _error = 'No se pudieron calcular las analíticas';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  AnalyticsData _computeAnalytics(List<ChargingSessionModel> sessions) {
    if (sessions.isEmpty) return const AnalyticsData();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final durations = sessions.map((s) => s.duration).toList();
    final totalDuration = durations.fold<Duration>(
      Duration.zero,
      (prev, d) => prev + d,
    );
    final avgDuration = Duration(
      minutes: (totalDuration.inMinutes / sessions.length).round(),
    );

    final dailyCount = sessions
        .where((s) => s.startTime.isAfter(todayStart))
        .length;

    final fullCount =
        sessions.where((s) => (s.endLevel ?? 0) >= 99).length;

    final temps = sessions
        .where((s) => s.avgTemperature != null)
        .map((s) => s.avgTemperature!)
        .toList();
    final avgTemp = temps.isEmpty
        ? 0.0
        : temps.reduce((a, b) => a + b) / temps.length;

    final totalHours =
        totalDuration.inMinutes / 60.0;

    final weekly = _weeklyData(sessions, now);
    final monthly = _monthlyData(sessions, now);

    return AnalyticsData(
      avgChargeDuration: avgDuration,
      dailyChargeCount: dailyCount,
      fullChargeCount: fullCount,
      avgTemperature: avgTemp,
      totalConnectedHours: totalHours,
      weeklyDurations: weekly.$1,
      weeklyLabels: weekly.$2,
      monthlyDurations: monthly.$1,
      monthlyLabels: monthly.$2,
    );
  }

  (List<double>, List<String>) _weeklyData(
    List<ChargingSessionModel> sessions,
    DateTime now,
  ) {
    final durations = <double>[];
    final labels = <String>[];
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    for (var i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final nextDay = day.add(const Duration(days: 1));
      final daySessions = sessions.where(
        (s) =>
            s.startTime.isAfter(day.subtract(const Duration(seconds: 1))) &&
            s.startTime.isBefore(nextDay),
      );

      final totalMinutes = daySessions.fold<int>(
        0,
        (sum, s) => sum + s.duration.inMinutes,
      );

      durations.add(totalMinutes.toDouble());
      labels.add(days[day.weekday - 1]);
    }

    return (durations, labels);
  }

  (List<double>, List<String>) _monthlyData(
    List<ChargingSessionModel> sessions,
    DateTime now,
  ) {
    final durations = <double>[];
    final labels = <String>[];

    for (var i = 3; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 1);

      final monthSessions = sessions.where(
        (s) =>
            s.startTime.isAfter(monthStart.subtract(const Duration(days: 1))) &&
            s.startTime.isBefore(monthEnd),
      );

      final totalMinutes = monthSessions.fold<int>(
        0,
        (sum, s) => sum + s.duration.inMinutes,
      );

      durations.add(totalMinutes.toDouble());
      labels.add(_monthLabel(monthStart.month));
    }

    return (durations, labels);
  }

  String _monthLabel(int month) {
    const names = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return names[month - 1];
  }

  Future<void> refresh() => loadAnalytics();
}
