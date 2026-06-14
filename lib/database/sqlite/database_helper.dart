import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
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
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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

  Future<void> deleteAllSessions() async {
    final db = await database;
    await db.delete('charging_sessions');
  }
}
