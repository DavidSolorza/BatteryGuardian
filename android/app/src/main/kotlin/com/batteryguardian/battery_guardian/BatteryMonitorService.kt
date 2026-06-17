package com.batteryguardian.battery_guardian

import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper

class BatteryMonitorService : Service() {
    private var batteryReceiver: BroadcastReceiver? = null
    private val handler = Handler(Looper.getMainLooper())
    private var pollRunnable: Runnable? = null

    override fun onCreate() {
        super.onCreate()
        PrefsHelper.setServiceRunning(this, true)
        NotificationHelper.createChannels(this)
        startForeground(
            NotificationHelper.NOTIFICATION_MONITORING,
            NotificationHelper.buildMonitoringNotification(this, 0, false),
        )
        registerBatteryReceiver()
        pollCurrentBatteryState()
        startPolling()
        ServiceWatchdog.schedule(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP_ALARM -> {
                AlarmHelper.stop()
                NotificationHelper.cancelAlarmNotification(this)
            }
            ACTION_STOP_SERVICE -> {
                ServiceWatchdog.cancel(this)
                stopSelf()
                return START_NOT_STICKY
            }
        }
        pollCurrentBatteryState()
        return START_STICKY
    }

    override fun onDestroy() {
        pollRunnable?.let { handler.removeCallbacks(it) }
        pollRunnable = null
        PrefsHelper.setServiceRunning(this, false)
        batteryReceiver?.let { unregisterReceiver(it) }
        batteryReceiver = null
        AlarmHelper.stop()

        if (PrefsHelper.isBackgroundMonitoringEnabled(this)) {
            ServiceRestartReceiver.schedule(this)
        }
        super.onDestroy()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        if (PrefsHelper.isBackgroundMonitoringEnabled(this)) {
            ServiceWatchdog.ensureServiceRunning(this)
        }
        super.onTaskRemoved(rootIntent)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startPolling() {
        pollRunnable?.let { handler.removeCallbacks(it) }
        pollRunnable = object : Runnable {
            override fun run() {
                pollCurrentBatteryState()
                val interval = if (PrefsHelper.isPowerSavingMode(this@BatteryMonitorService)) {
                    120_000L
                } else {
                    45_000L
                }
                handler.postDelayed(this, interval)
            }
        }
        handler.postDelayed(pollRunnable!!, pollIntervalMs())
    }

    private fun pollIntervalMs(): Long {
        return if (PrefsHelper.isPowerSavingMode(this)) 120_000L else 45_000L
    }

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
        val lastKnown = PrefsHelper.getLastKnownLevel(this)
        val percent = if (level >= 0 && scale > 0) {
            val pct = (level * 100) / scale
            PrefsHelper.setLastKnownLevel(this, pct)
            pct
        } else if (lastKnown >= 0) {
            lastKnown
        } else {
            0
        }

        val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        val plugged = intent.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0)
        val isPluggedIn = plugged != 0
        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
            status == BatteryManager.BATTERY_STATUS_FULL ||
            (isPluggedIn && status == BatteryManager.BATTERY_STATUS_NOT_CHARGING)

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
                    val type = if (PrefsHelper.wasDisconnectedInCycle(this)) 4 else 2
                    PrefsHelper.setWasDisconnectedInCycle(this, false)
                    val body = "Monitoreando carga desde $percent%"
                    NotificationHelper.showEventNotification(this, title, body)
                    EventLogger.log(this, type, body, percent)
                    SessionLogger.onChargingStarted(this, percent, temperature)
                } else {
                    PrefsHelper.setWasDisconnectedInCycle(this, true)
                    val body = "Nivel actual: $percent%"
                    NotificationHelper.showEventNotification(
                        this,
                        "Cargador desconectado",
                        body,
                    )
                    EventLogger.log(this, 3, body, percent)
                    SessionLogger.onChargingStopped(this, percent, temperature)
                    AlarmHelper.stop()
                    NotificationHelper.cancelAlarmNotification(this)
                    resetChargingAlertFlags()
                }
            } else {
                if (isCharging) {
                    SessionLogger.onChargingStarted(this, percent, temperature)
                } else {
                    SessionLogger.onChargingStopped(this, percent, temperature)
                    AlarmHelper.stop()
                    NotificationHelper.cancelAlarmNotification(this)
                    resetChargingAlertFlags()
                }
            }
            PrefsHelper.setWasCharging(this, isCharging)
        } else if (isCharging) {
            SessionLogger.sampleTemperature(temperature)
        }

        if (!isPluggedIn) {
            PrefsHelper.setHighLevelSince(this, 0L)
            PrefsHelper.setOverchargeAlertTriggered(this, false)
            PrefsHelper.setFullChargeAlertTriggered(this, false)
        }

        val alertLevel = PrefsHelper.getAlertLevel(this)
        val levelTriggered = PrefsHelper.isLevelAlertTriggered(this)

        if (isPluggedIn && !levelTriggered && percent >= alertLevel) {
            PrefsHelper.setLevelAlertTriggered(this, true)
            val body =
                "Alcanzaste el $alertLevel% configurado. Desconecta el cargador para prolongar su vida útil."
            NotificationHelper.showLevelAlarmNotification(this, percent, alertLevel)
            EventLogger.log(this, 0, body, percent)
            AlarmHelper.start(
                this,
                PrefsHelper.isSoundEnabled(this) && !PrefsHelper.isQuietHoursActive(this),
                PrefsHelper.isVibrationEnabled(this) && !PrefsHelper.isQuietHoursActive(this),
            )
            showAlarmActivity("¡Batería al $percent%!", body, percent)
        }

        val tempThreshold = PrefsHelper.getTempThreshold(this)
        val tempTriggered = PrefsHelper.isTempAlertTriggered(this)
        if (
            isPluggedIn &&
            temperature != null &&
            !tempTriggered &&
            temperature >= tempThreshold
        ) {
            PrefsHelper.setTempAlertTriggered(this, true)
            val body =
                "La batería alcanzó ${"%.1f".format(temperature)}°C. Deja enfriar el dispositivo."
            NotificationHelper.showAlarmNotification(
                this,
                "Temperatura elevada",
                body,
            )
            EventLogger.log(this, 1, body, percent)
            AlarmHelper.start(
                this,
                PrefsHelper.isSoundEnabled(this) && !PrefsHelper.isQuietHoursActive(this),
                PrefsHelper.isVibrationEnabled(this) && !PrefsHelper.isQuietHoursActive(this),
            )
            showAlarmActivity("Temperatura elevada", "La batería alcanzó ${"%.1f".format(temperature)}°C. Deja enfriar el dispositivo.", percent)
        } else if (temperature != null && temperature < tempThreshold - 2) {
            PrefsHelper.setTempAlertTriggered(this, false)
        }

        if (
            PrefsHelper.isLowBatteryAlertEnabled(this) &&
            !isPluggedIn &&
            percent > 0 &&
            !PrefsHelper.isLowBatteryAlertTriggered(this) &&
            percent <= PrefsHelper.getLowBatteryLevel(this)
        ) {
            PrefsHelper.setLowBatteryAlertTriggered(this, true)
            val body = "Queda $percent% de batería. Conecta el cargador pronto."
            NotificationHelper.showAlarmNotification(
                this,
                "Batería baja",
                body,
            )
            EventLogger.log(this, 5, body, percent)
            AlarmHelper.start(
                this,
                PrefsHelper.isSoundEnabled(this) && !PrefsHelper.isQuietHoursActive(this),
                PrefsHelper.isVibrationEnabled(this) && !PrefsHelper.isQuietHoursActive(this),
            )
            showAlarmActivity("Batería baja", body, percent)
        } else if (percent > PrefsHelper.getLowBatteryLevel(this) + 5) {
            PrefsHelper.setLowBatteryAlertTriggered(this, false)
        }

        if (
            PrefsHelper.isFullChargeAlertEnabled(this) &&
            isPluggedIn &&
            !PrefsHelper.isFullChargeAlertTriggered(this) &&
            percent >= 100
        ) {
            PrefsHelper.setFullChargeAlertTriggered(this, true)
            val body = "La batería llegó al 100%. Puedes desconectar el cargador."
            NotificationHelper.showAlarmNotification(
                this,
                "Carga completa",
                body,
            )
            EventLogger.log(this, 6, body, percent)
            AlarmHelper.start(
                this,
                PrefsHelper.isSoundEnabled(this) && !PrefsHelper.isQuietHoursActive(this),
                PrefsHelper.isVibrationEnabled(this) && !PrefsHelper.isQuietHoursActive(this),
            )
            showAlarmActivity("Carga completa", body, percent)
        }

        if (PrefsHelper.isOverchargeAlertEnabled(this) && isPluggedIn && percent >= 95) {
            val since = PrefsHelper.getHighLevelSince(this)
            val highLevelSince = if (since == 0L) {
                val now = System.currentTimeMillis()
                PrefsHelper.setHighLevelSince(this, now)
                now
            } else {
                since
            }
            val pluggedMinutes = ((System.currentTimeMillis() - highLevelSince) / 60000L).toInt()
            if (pluggedMinutes >= 30 && !PrefsHelper.isOverchargeAlertTriggered(this)) {
                PrefsHelper.setOverchargeAlertTriggered(this, true)
                val body =
                    "Llevas $pluggedMinutes min conectado al $percent%. Desconecta para cuidar la batería."
                NotificationHelper.showAlarmNotification(
                    this,
                    "Carga prolongada",
                    body,
                )
                EventLogger.log(this, 7, body, percent)
                AlarmHelper.start(
                    this,
                    PrefsHelper.isSoundEnabled(this) && !PrefsHelper.isQuietHoursActive(this),
                    PrefsHelper.isVibrationEnabled(this) && !PrefsHelper.isQuietHoursActive(this),
                )
                showAlarmActivity("Carga prolongada", body, percent)
            }
        } else if (percent < 95) {
            PrefsHelper.setHighLevelSince(this, 0L)
            PrefsHelper.setOverchargeAlertTriggered(this, false)
        }

        val notification = NotificationHelper.buildMonitoringNotification(
            this,
            percent,
            isCharging,
        )
        startForeground(NotificationHelper.NOTIFICATION_MONITORING, notification)
    }

    private fun resetChargingAlertFlags() {
        PrefsHelper.setLevelAlertTriggered(this, false)
        PrefsHelper.setTempAlertTriggered(this, false)
        PrefsHelper.setFullChargeAlertTriggered(this, false)
        PrefsHelper.setOverchargeAlertTriggered(this, false)
        PrefsHelper.setHighLevelSince(this, 0L)
    }

    private fun showAlarmActivity(title: String, body: String, level: Int) {
        try {
            val intent = android.content.Intent(this, AlarmActivity::class.java).apply {
                addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK or
                    android.content.Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra(AlarmActivity.EXTRA_TITLE, title)
                putExtra(AlarmActivity.EXTRA_BODY, body)
                putExtra(AlarmActivity.EXTRA_LEVEL, level)
            }
            startActivity(intent)
        } catch (_: Exception) {
        }
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
            ServiceWatchdog.schedule(context)
        }

        fun stop(context: Context) {
            ServiceWatchdog.cancel(context)
            val intent = Intent(context, BatteryMonitorService::class.java).apply {
                action = ACTION_STOP_SERVICE
            }
            context.startService(intent)
        }

        fun isRunning(context: Context): Boolean {
            return PrefsHelper.isServiceRunning(context)
        }
    }
}
