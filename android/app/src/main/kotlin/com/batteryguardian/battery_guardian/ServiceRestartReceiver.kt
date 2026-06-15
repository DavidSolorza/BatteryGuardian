package com.batteryguardian.battery_guardian

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.SystemClock

class ServiceRestartReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (PrefsHelper.isBackgroundMonitoringEnabled(context)) {
            BatteryMonitorService.start(context)
            ServiceWatchdog.schedule(context)
        }
    }

    companion object {
        private const val REQUEST_CODE = 9101
        private const val RESTART_DELAY_MS = 3000L

        fun schedule(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, ServiceRestartReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            alarmManager.set(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                SystemClock.elapsedRealtime() + RESTART_DELAY_MS,
                pendingIntent,
            )
        }
    }
}
