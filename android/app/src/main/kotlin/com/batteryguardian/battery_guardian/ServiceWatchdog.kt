package com.batteryguardian.battery_guardian

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock

object ServiceWatchdog {
    private const val REQUEST_CODE = 9100
    private const val INTERVAL_MS = 15 * 60 * 1000L

    fun schedule(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, ServiceWatchdogReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        alarmManager.setInexactRepeating(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            SystemClock.elapsedRealtime() + INTERVAL_MS,
            INTERVAL_MS,
            pendingIntent,
        )
    }

    fun cancel(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, ServiceWatchdogReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager.cancel(pendingIntent)
    }

    fun ensureServiceRunning(context: Context) {
        if (!PrefsHelper.isBackgroundMonitoringEnabled(context)) return
        if (!BatteryMonitorService.isRunning(context)) {
            BatteryMonitorService.start(context)
        }
        schedule(context)
    }
}

class ServiceWatchdogReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        ServiceWatchdog.ensureServiceRunning(context)
    }
}
