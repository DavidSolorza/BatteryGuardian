package com.batteryguardian.battery_guardian

import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.IBinder

class BatteryMonitorService : Service() {
    private var batteryReceiver: BroadcastReceiver? = null

    override fun onCreate() {
        super.onCreate()
        NotificationHelper.createChannels(this)
        startForeground(
            NotificationHelper.NOTIFICATION_MONITORING,
            NotificationHelper.buildMonitoringNotification(this, 0, false),
        )
        registerBatteryReceiver()
        pollCurrentBatteryState()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP_ALARM -> {
                AlarmHelper.stop()
                NotificationHelper.cancelAlarmNotification(this)
            }
            ACTION_STOP_SERVICE -> {
                stopSelf()
                return START_NOT_STICKY
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        batteryReceiver?.let { unregisterReceiver(it) }
        batteryReceiver = null
        AlarmHelper.stop()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun registerBatteryReceiver() {
        batteryReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent != null) {
                    handleBatteryChanged(intent)
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_BATTERY_CHANGED)
            addAction(Intent.ACTION_POWER_CONNECTED)
            addAction(Intent.ACTION_POWER_DISCONNECTED)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(batteryReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(batteryReceiver, filter)
        }
    }

    private fun pollCurrentBatteryState() {
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        if (intent != null) {
            handleBatteryChanged(intent)
        }
    }

    private fun handleBatteryChanged(intent: Intent) {
        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, 100)
        val percent = if (level >= 0 && scale > 0) (level * 100) / scale else 0

        val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
            status == BatteryManager.BATTERY_STATUS_FULL

        val temperatureRaw = intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1)
        val temperature = if (temperatureRaw > 0) temperatureRaw / 10.0 else null

        val wasCharging = PrefsHelper.wasCharging(this)
        val chargingNotifications = PrefsHelper.areChargingNotificationsEnabled(this)

        if (isCharging != wasCharging) {
            if (chargingNotifications) {
                if (isCharging) {
                    val title = if (PrefsHelper.wasDisconnectedInCycle(this)) {
                        "Cargador reconectado"
                    } else {
                        "Cargador conectado"
                    }
                    PrefsHelper.setWasDisconnectedInCycle(this, false)
                    NotificationHelper.showEventNotification(
                        this,
                        title,
                        "Monitoreando carga desde $percent%",
                    )
                } else {
                    PrefsHelper.setWasDisconnectedInCycle(this, true)
                    NotificationHelper.showEventNotification(
                        this,
                        "Cargador desconectado",
                        "Nivel actual: $percent%",
                    )
                    AlarmHelper.stop()
                    NotificationHelper.cancelAlarmNotification(this)
                    PrefsHelper.setLevelAlertTriggered(this, false)
                    PrefsHelper.setTempAlertTriggered(this, false)
                }
            } else if (!isCharging) {
                AlarmHelper.stop()
                NotificationHelper.cancelAlarmNotification(this)
                PrefsHelper.setLevelAlertTriggered(this, false)
                PrefsHelper.setTempAlertTriggered(this, false)
            }
            PrefsHelper.setWasCharging(this, isCharging)
        }

        val alertLevel = PrefsHelper.getAlertLevel(this)
        val levelTriggered = PrefsHelper.isLevelAlertTriggered(this)

        if (isCharging && !levelTriggered && percent >= alertLevel) {
            PrefsHelper.setLevelAlertTriggered(this, true)
            NotificationHelper.showLevelAlarmNotification(this, percent, alertLevel)
            AlarmHelper.start(
                this,
                PrefsHelper.isSoundEnabled(this),
                PrefsHelper.isVibrationEnabled(this),
            )
        }

        val tempThreshold = PrefsHelper.getTempThreshold(this)
        val tempTriggered = PrefsHelper.isTempAlertTriggered(this)
        if (
            isCharging &&
            temperature != null &&
            !tempTriggered &&
            temperature >= tempThreshold
        ) {
            PrefsHelper.setTempAlertTriggered(this, true)
            NotificationHelper.showAlarmNotification(
                this,
                "Temperatura elevada",
                "La batería alcanzó ${"%.1f".format(temperature)}°C. Deja enfriar el dispositivo.",
            )
            AlarmHelper.start(
                this,
                PrefsHelper.isSoundEnabled(this),
                PrefsHelper.isVibrationEnabled(this),
            )
        } else if (temperature != null && temperature < tempThreshold - 2) {
            PrefsHelper.setTempAlertTriggered(this, false)
        }

        val notification = NotificationHelper.buildMonitoringNotification(
            this,
            percent,
            isCharging,
        )
        startForeground(NotificationHelper.NOTIFICATION_MONITORING, notification)
    }

    companion object {
        const val ACTION_STOP_ALARM = "com.batteryguardian.STOP_ALARM"
        const val ACTION_STOP_SERVICE = "com.batteryguardian.STOP_SERVICE"

        fun start(context: Context) {
            val intent = Intent(context, BatteryMonitorService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, BatteryMonitorService::class.java).apply {
                action = ACTION_STOP_SERVICE
            }
            context.startService(intent)
        }

        fun isRunning(context: Context): Boolean {
            val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
            @Suppress("DEPRECATION")
            return manager.getRunningServices(Int.MAX_VALUE).any {
                it.service.className == BatteryMonitorService::class.java.name
            }
        }
    }
}
