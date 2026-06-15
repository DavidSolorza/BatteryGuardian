package com.batteryguardian.battery_guardian

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

import com.batteryguardian.battery_guardian.R

object NotificationHelper {
    const val CHANNEL_MONITORING = "battery_monitoring"
    const val CHANNEL_ALERTS = "battery_alerts"
    const val CHANNEL_EVENTS = "battery_events"

    const val NOTIFICATION_MONITORING = 1001
    const val NOTIFICATION_ALARM = 2001
    const val NOTIFICATION_EVENT = 3001

    fun createChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java)

        val monitoring = NotificationChannel(
            CHANNEL_MONITORING,
            "Monitoreo de batería",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Servicio activo en segundo plano"
            setShowBadge(false)
        }

        val alerts = NotificationChannel(
            CHANNEL_ALERTS,
            "Alertas de batería",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Alertas cuando la batería alcanza el nivel configurado"
            enableVibration(true)
            enableLights(true)
        }

        val events = NotificationChannel(
            CHANNEL_EVENTS,
            "Eventos de carga",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Conexión y desconexión del cargador"
        }

        manager.createNotificationChannel(monitoring)
        manager.createNotificationChannel(alerts)
        manager.createNotificationChannel(events)
    }

    fun buildMonitoringNotification(
        context: Context,
        level: Int,
        isCharging: Boolean,
    ): Notification {
        createChannels(context)
        val status = if (isCharging) "Cargando · $level%" else "Descargando · $level%"
        val alertLevel = PrefsHelper.getAlertLevel(context)

        return NotificationCompat.Builder(context, CHANNEL_MONITORING)
            .setContentTitle("Battery Guardian activo")
            .setContentText("$status · Alerta al $alertLevel%")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(openAppIntent(context))
            .build()
    }

    fun showAlarmNotification(
        context: Context,
        title: String,
        body: String,
    ) {
        createChannels(context)
        val manager = context.getSystemService(NotificationManager::class.java)

        val stopIntent = Intent(context, AlarmStopReceiver::class.java).apply {
            action = AlarmStopReceiver.ACTION_STOP_ALARM
        }
        val stopPending = PendingIntent.getBroadcast(
            context,
            0,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ALERTS)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Detener alarma",
                stopPending,
            )
            .setContentIntent(openAppIntent(context))
            .build()

        manager.notify(NOTIFICATION_ALARM, notification)
    }

    fun showLevelAlarmNotification(context: Context, level: Int, alertLevel: Int) {
        showAlarmNotification(
            context,
            "¡Batería al $level%!",
            "Alcanzaste el $alertLevel% configurado. Desconecta el cargador.",
        )
    }

    fun showEventNotification(context: Context, title: String, body: String) {
        createChannels(context)
        val manager = context.getSystemService(NotificationManager::class.java)

        val notification = NotificationCompat.Builder(context, CHANNEL_EVENTS)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setContentIntent(openAppIntent(context))
            .build()

        manager.notify(
            System.currentTimeMillis().toInt(),
            notification,
        )
    }

    fun cancelAlarmNotification(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.cancel(NOTIFICATION_ALARM)
    }

    private fun openAppIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
