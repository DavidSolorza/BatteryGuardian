package com.batteryguardian.battery_guardian

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

object EventLogger {
    private const val PREFS = "BatteryGuardianNative"
    private const val KEY_QUEUE = "pending_alert_events"
    private const val MAX_EVENTS = 80

    fun log(context: Context, type: Int, message: String, level: Int) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val existing = prefs.getString(KEY_QUEUE, "[]") ?: "[]"
        val array = JSONArray(existing)

        val event = JSONObject().apply {
            put("type", type)
            put("message", message)
            put("level", level)
            put("timestamp", System.currentTimeMillis())
        }
        array.put(event)

        val trimmed = JSONArray()
        val start = (array.length() - MAX_EVENTS).coerceAtLeast(0)
        for (i in start until array.length()) {
            trimmed.put(array.get(i))
        }

        prefs.edit().putString(KEY_QUEUE, trimmed.toString()).apply()
    }

    fun drainPending(context: Context): String {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val data = prefs.getString(KEY_QUEUE, "[]") ?: "[]"
        prefs.edit().remove(KEY_QUEUE).apply()
        return data
    }
}
