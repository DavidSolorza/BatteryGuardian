package com.batteryguardian.battery_guardian

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase

object SessionLogger {
    private const val DB_NAME = "battery_guardian.db"
    private var activeSessionId: Long = -1L
    private var sessionStartMs: Long = 0L
    private var sessionStartLevel: Int = 0
    private val temperatures = mutableListOf<Double>()

    private fun openDb(context: Context): SQLiteDatabase? {
        return try {
            val path = context.getDatabasePath(DB_NAME)
            path.parentFile?.mkdirs()
            val db = SQLiteDatabase.openOrCreateDatabase(path, null)
            db.execSQL(
                "CREATE TABLE IF NOT EXISTS charging_sessions (" +
                    "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                    "start_time INTEGER NOT NULL, " +
                    "end_time INTEGER, " +
                    "start_level INTEGER NOT NULL, " +
                    "end_level INTEGER, " +
                    "avg_temperature REAL, " +
                    "duration_minutes INTEGER)"
            )
            db
        } catch (_: Exception) {
            null
        }
    }

    fun onChargingStarted(context: Context, level: Int, temperature: Double?) {
        if (activeSessionId >= 0) return

        sessionStartMs = System.currentTimeMillis()
        sessionStartLevel = level
        temperatures.clear()
        temperature?.let { temperatures.add(it) }

        val values = ContentValues().apply {
            put("start_time", sessionStartMs)
            put("start_level", sessionStartLevel)
        }
        val db = openDb(context) ?: return
        try {
            activeSessionId = db.insert("charging_sessions", null, values)
        } catch (_: Exception) {
            db.close()
        }
    }

    fun onChargingStopped(context: Context, level: Int, temperature: Double?) {
        if (activeSessionId < 0) return

        temperature?.let { temperatures.add(it) }
        val endMs = System.currentTimeMillis()
        val durationMinutes = ((endMs - sessionStartMs) / 60000L).toInt().coerceAtLeast(0)
        val avgTemp = if (temperatures.isEmpty()) null else temperatures.average()

        val values = ContentValues().apply {
            put("end_time", endMs)
            put("end_level", level)
            put("duration_minutes", durationMinutes)
            avgTemp?.let { put("avg_temperature", it) }
        }
        val db = openDb(context)
        if (db != null) {
            try {
                db.update(
                    "charging_sessions",
                    values,
                    "id = ?",
                    arrayOf(activeSessionId.toString()),
                )
            } catch (_: Exception) {
            }
        }

        activeSessionId = -1L
        sessionStartMs = 0L
        sessionStartLevel = 0
        temperatures.clear()
    }

    fun sampleTemperature(temperature: Double?) {
        if (activeSessionId < 0 || temperature == null) return
        temperatures.add(temperature)
    }

    fun reset() {
        activeSessionId = -1L
        sessionStartMs = 0L
        sessionStartLevel = 0
        temperatures.clear()
    }
}
