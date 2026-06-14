import 'package:flutter/foundation.dart';

import '../database/sqlite/charging_session_model.dart';
import '../database/sqlite/database_helper.dart';

class HistoryProvider extends ChangeNotifier {
  HistoryProvider({DatabaseHelper? databaseHelper})
      : _db = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  List<ChargingSessionModel> _sessions = [];
  bool _isLoading = true;
  String? _error;

  List<ChargingSessionModel> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _sessions.isEmpty;

  Future<void> loadSessions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sessions = await _db.getAllSessions();
      _sessions = _sessions.where((s) => s.isComplete).toList();
    } catch (e) {
      _error = 'No se pudo cargar el historial';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadSessions();

  Future<void> clearHistory() async {
    await _db.deleteAllSessions();
    _sessions = [];
    notifyListeners();
  }
}
