import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import 'alert_event_model.dart';
import 'charging_session_model.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createChargingSessionsTable(db);
    await _createAlertEventsTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createAlertEventsTable(db);
    }
  }

  Future<void> _createChargingSessionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE charging_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        start_level INTEGER NOT NULL,
        end_level INTEGER,
        avg_temperature REAL,
        duration_minutes INTEGER
      )
    ''');
  }

  Future<void> _createAlertEventsTable(Database db) async {
    await db.execute('''
      CREATE TABLE alert_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        message TEXT NOT NULL,
        level INTEGER NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertSession(ChargingSessionModel session) async {
    final db = await database;
    return db.insert('charging_sessions', session.toMap());
  }

  Future<int> updateSession(ChargingSessionModel session) async {
    final db = await database;
    return db.update(
      'charging_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<List<ChargingSessionModel>> getAllSessions() async {
    final db = await database;
    final maps = await db.query(
      'charging_sessions',
      orderBy: 'start_time DESC',
    );
    return maps.map(ChargingSessionModel.fromMap).toList();
  }

  Future<List<ChargingSessionModel>> getSessionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final maps = await db.query(
      'charging_sessions',
      where: 'start_time >= ? AND start_time <= ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'start_time ASC',
    );
    return maps.map(ChargingSessionModel.fromMap).toList();
  }

  Future<ChargingSessionModel?> getActiveSession() async {
    final db = await database;
    final maps = await db.query(
      'charging_sessions',
      where: 'end_time IS NULL',
      orderBy: 'start_time DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ChargingSessionModel.fromMap(maps.first);
  }

  Future<void> closeStaleActiveSessions({
    required bool isPluggedIn,
    required int currentLevel,
  }) async {
    if (isPluggedIn) return;

    final db = await database;
    final now = DateTime.now();
    final maps = await db.query(
      'charging_sessions',
      where: 'end_time IS NULL',
    );

    for (final map in maps) {
      final session = ChargingSessionModel.fromMap(map);
      final duration = now.difference(session.startTime);
      final durationMinutes = duration.inSeconds <= 0
          ? 0
          : (duration.inSeconds / 60).ceil();

      await db.update(
        'charging_sessions',
        {
          'end_time': now.millisecondsSinceEpoch,
          'end_level': currentLevel,
          'duration_minutes': durationMinutes,
        },
        where: 'id = ?',
        whereArgs: [session.id],
      );
    }
  }

  Future<void> deleteAllSessions() async {
    final db = await database;
    await db.delete('charging_sessions');
  }

  Future<int> insertAlertEvent(AlertEventModel event) async {
    final db = await database;
    return db.insert('alert_events', event.toMap());
  }

  Future<List<AlertEventModel>> getRecentAlertEvents({int limit = 100}) async {
    final db = await database;
    final maps = await db.query(
      'alert_events',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map(AlertEventModel.fromMap).toList();
  }

  Future<void> deleteAllAlertEvents() async {
    final db = await database;
    await db.delete('alert_events');
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('charging_sessions');
    await db.delete('alert_events');
  }
}
