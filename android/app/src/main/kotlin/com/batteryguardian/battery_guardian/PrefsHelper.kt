package com.batteryguardian.battery_guardian

import android.content.Context

object PrefsHelper {
    private const val FLUTTER_PREFS = "FlutterSharedPreferences"
    private const val NATIVE_PREFS = "BatteryGuardianNative"

    private fun flutterKey(name: String) = "flutter.$name"

    fun getAlertLevel(context: Context): Int {
        val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        return prefs.getLong(flutterKey("alert_level"), 80L).toInt()
    }

    fun isSoundEnabled(context: Context): Boolean {
        val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean(flutterKey("sound_enabled"), true)
    }

    fun isVibrationEnabled(context: Context): Boolean {
        val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean(flutterKey("vibration_enabled"), true)
    }

    fun getTempThreshold(context: Context): Double {
        val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        val key = flutterKey("temp_threshold")
        val raw = prefs.all[key] ?: return 40.0
        return when (raw) {
            is String -> raw.toDoubleOrNull() ?: 40.0
            is Float -> raw.toDouble()
            is Double -> raw
            is Long -> raw.toDouble()
            is Int -> raw.toDouble()
            else -> 40.0
        }
    }

    fun isBackgroundMonitoringEnabled(context: Context): Boolean {
        val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean(flutterKey("background_monitoring_enabled"), true)
    }

    fun areChargingNotificationsEnabled(context: Context): Boolean {
        val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean(flutterKey("charging_notifications_enabled"), true)
    }

    fun isLevelAlertTriggered(context: Context): Boolean {
        val prefs = context.getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean("level_alert_triggered", false)
    }

    fun setLevelAlertTriggered(context: Context, value: Boolean) {
        val prefs = context.getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
        prefs.edit().putBoolean("level_alert_triggered", value).apply()
    }

    fun isTempAlertTriggered(context: Context): Boolean {
        val prefs = context.getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean("temp_alert_triggered", false)
    }

    fun setTempAlertTriggered(context: Context, value: Boolean) {
        val prefs = context.getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
        prefs.edit().putBoolean("temp_alert_triggered", value).apply()
    }

    fun wasCharging(context: Context): Boolean {
        val prefs = context.getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean("was_charging", false)
    }

    fun setWasCharging(context: Context, value: Boolean) {
        val prefs = context.getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
        prefs.edit().putBoolean("was_charging", value).apply()
    }

    fun wasDisconnectedInCycle(context: Context): Boolean {
        val prefs = context.getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean("was_disconnected_in_cycle", false)
    }

    fun setWasDisconnectedInCycle(context: Context, value: Boolean) {
        val prefs = context.getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
        prefs.edit().putBoolean("was_disconnected_in_cycle", value).apply()
    }
}
