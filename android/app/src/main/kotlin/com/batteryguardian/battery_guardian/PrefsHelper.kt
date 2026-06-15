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

    fun getCustomSound(context: Context): String {
        val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        return prefs.getString(flutterKey("custom_sound"), "assets/sounds/alarm.wav")
            ?: "assets/sounds/alarm.wav"
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

    fun isLowBatteryAlertEnabled(context: Context): Boolean {
        val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean(flutterKey("low_battery_alert_enabled"), true)
    }

    fun getLowBatteryLevel(context: Context): Int {
        val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        return prefs.getLong(flutterKey("low_battery_level"), 20L).toInt()
    }

    fun isFullChargeAlertEnabled(context: Context): Boolean {
        val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean(flutterKey("full_charge_alert_enabled"), true)
    }

    fun isOverchargeAlertEnabled(context: Context): Boolean {
        val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean(flutterKey("overcharge_alert_enabled"), true)
    }

    fun isPowerSavingMode(context: Context): Boolean {
        val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean(flutterKey("power_saving_mode"), false)
    }

    fun isQuietHoursEnabled(context: Context): Boolean {
        val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean(flutterKey("quiet_hours_enabled"), false)
    }

    fun getQuietHoursStart(context: Context): Int {
        val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        return prefs.getLong(flutterKey("quiet_hours_start"), 23L).toInt()
    }

    fun getQuietHoursEnd(context: Context): Int {
        val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        return prefs.getLong(flutterKey("quiet_hours_end"), 7L).toInt()
    }

    fun isQuietHoursActive(context: Context): Boolean {
        if (!isQuietHoursEnabled(context)) return false
        val start = getQuietHoursStart(context)
        val end = getQuietHoursEnd(context)
        val hour = java.util.Calendar.getInstance().get(java.util.Calendar.HOUR_OF_DAY)
        if (start == end) return false
        return if (start < end) {
            hour in start until end
        } else {
            hour >= start || hour < end
        }
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

    fun isLowBatteryAlertTriggered(context: Context): Boolean {
        val prefs = context.getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean("low_battery_alert_triggered", false)
    }

    fun setLowBatteryAlertTriggered(context: Context, value: Boolean) {
        val prefs = context.getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
        prefs.edit().putBoolean("low_battery_alert_triggered", value).apply()
    }

    fun isFullChargeAlertTriggered(context: Context): Boolean {
        val prefs = context.getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean("full_charge_alert_triggered", false)
    }

    fun setFullChargeAlertTriggered(context: Context, value: Boolean) {
        val prefs = context.getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
        prefs.edit().putBoolean("full_charge_alert_triggered", value).apply()
    }

    fun isOverchargeAlertTriggered(context: Context): Boolean {
        val prefs = context.getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean("overcharge_alert_triggered", false)
    }

    fun setOverchargeAlertTriggered(context: Context, value: Boolean) {
        val prefs = context.getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
        prefs.edit().putBoolean("overcharge_alert_triggered", value).apply()
    }

    fun getHighLevelSince(context: Context): Long {
        val prefs = context.getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
        return prefs.getLong("high_level_since", 0L)
    }

    fun setHighLevelSince(context: Context, value: Long) {
        val prefs = context.getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
        prefs.edit().putLong("high_level_since", value).apply()
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

    fun setServiceRunning(context: Context, value: Boolean) {
        val prefs = context.getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
        prefs.edit().putBoolean("service_running", value).apply()
    }

    fun isServiceRunning(context: Context): Boolean {
        val prefs = context.getSharedPreferences(NATIVE_PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean("service_running", false)
    }
}
