package com.batteryguardian.battery_guardian

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.batteryguardian/battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getBatteryDetails" -> {
                        result.success(getBatteryDetails())
                    }
                    "startBackgroundMonitoring" -> {
                        BatteryMonitorService.start(this)
                        result.success(true)
                    }
                    "stopBackgroundMonitoring" -> {
                        BatteryMonitorService.stop(this)
                        result.success(true)
                    }
                    "isBackgroundMonitoringRunning" -> {
                        result.success(BatteryMonitorService.isRunning(this))
                    }
                    "requestBatteryOptimizationExemption" -> {
                        result.success(requestBatteryOptimizationExemption())
                    }
                    "isBatteryOptimizationIgnored" -> {
                        result.success(isBatteryOptimizationIgnored())
                    }
                    "stopNativeAlarm" -> {
                        AlarmHelper.stop()
                        NotificationHelper.cancelAlarmNotification(this)
                        result.success(true)
                    }
                    "ensureBackgroundMonitoring" -> {
                        if (PrefsHelper.isBackgroundMonitoringEnabled(this)) {
                            ServiceWatchdog.ensureServiceRunning(this)
                        }
                        result.success(BatteryMonitorService.isRunning(this))
                    }
                    "drainNativeAlertEvents" -> {
                        result.success(EventLogger.drainPending(this))
                    }
                    "isNativeAlarmActive" -> {
                        result.success(AlarmHelper.isActive)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getBatteryDetails(): Map<String, Any?> {
        val intentFilter = android.content.IntentFilter(android.content.Intent.ACTION_BATTERY_CHANGED)
        val batteryStatus = registerReceiver(null, intentFilter)
            ?: return mapOf(
                "temperature" to null,
                "voltage" to null,
                "health" to null,
                "technology" to null,
            )

        val temperature = batteryStatus.getIntExtra(android.os.BatteryManager.EXTRA_TEMPERATURE, -1)
        val voltage = batteryStatus.getIntExtra(android.os.BatteryManager.EXTRA_VOLTAGE, -1)
        val health = batteryStatus.getIntExtra(android.os.BatteryManager.EXTRA_HEALTH, -1)
        val technology = batteryStatus.getStringExtra(android.os.BatteryManager.EXTRA_TECHNOLOGY)

        return mapOf(
            "temperature" to if (temperature > 0) temperature / 10.0 else null,
            "voltage" to if (voltage > 0) voltage / 1000.0 else null,
            "health" to health,
            "technology" to technology,
        )
    }

    private fun requestBatteryOptimizationExemption(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (powerManager.isIgnoringBatteryOptimizations(packageName)) return true

        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
            data = Uri.parse("package:$packageName")
        }
        startActivity(intent)
        return false
    }

    private fun isBatteryOptimizationIgnored(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isIgnoringBatteryOptimizations(packageName)
    }
}
