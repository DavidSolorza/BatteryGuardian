package com.batteryguardian.battery_guardian

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmStopReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != ACTION_STOP_ALARM) return
        AlarmHelper.stop()
        NotificationHelper.cancelAlarmNotification(context)
    }

    companion object {
        const val ACTION_STOP_ALARM = "com.batteryguardian.STOP_ALARM"
    }
}
