package com.batteryguardian.battery_guardian

import android.app.Activity
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView

class AlarmActivity : Activity() {
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setTurnScreenOn(true)
            setShowWhenLocked(true)
            val window = window
            if (window != null) {
                window.addFlags(
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                        WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
                )
            }
        }

        val title = intent.getStringExtra(EXTRA_TITLE) ?: "Alarma"
        val body = intent.getStringExtra(EXTRA_BODY) ?: ""
        val level = intent.getIntExtra(EXTRA_LEVEL, 0)

        setContentView(createLayout(title, body, level))

        startAlarmSound()
        startVibration()
    }

    private fun createLayout(title: String, body: String, level: Int): android.widget.LinearLayout {
        val layout = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            gravity = android.view.Gravity.CENTER
            setPadding(48, 48, 48, 48)
            setBackgroundColor(android.graphics.Color.parseColor("#CC000000"))
        }

        val icon = TextView(this).apply {
            text = "🔔"
            textSize = 64f
            gravity = android.view.Gravity.CENTER
        }
        layout.addView(icon)

        val spacer1 = android.widget.Space(this).apply {
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.MATCH_PARENT, 32
            )
        }
        layout.addView(spacer1)

        val levelText = TextView(this).apply {
            text = "$level%"
            textSize = 56f
            gravity = android.view.Gravity.CENTER
            setTextColor(android.graphics.Color.WHITE)
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        }
        layout.addView(levelText)

        val spacer2 = android.widget.Space(this).apply {
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.MATCH_PARENT, 16
            )
        }
        layout.addView(spacer2)

        val bodyText = TextView(this).apply {
            text = body
            textSize = 20f
            gravity = android.view.Gravity.CENTER
            setTextColor(android.graphics.Color.argb(230, 255, 255, 255))
        }
        layout.addView(bodyText)

        val spacer3 = android.widget.Space(this).apply {
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.MATCH_PARENT, 48
            )
        }
        layout.addView(spacer3)

        val dismissButton = Button(this).apply {
            text = "DETENER ALARMA"
            setTextColor(android.graphics.Color.WHITE)
            setBackgroundColor(android.graphics.Color.parseColor("#EF4444"))
            textSize = 22f
            setPadding(32, 24, 32, 24)
            setOnClickListener {
                stopAlarm()
                finish()
            }
        }
        layout.addView(dismissButton)

        val hint = TextView(this).apply {
            text = "Alarma de Battery Guardian"
            textSize = 14f
            gravity = android.view.Gravity.CENTER
            setTextColor(android.graphics.Color.argb(100, 255, 255, 255))
        }

        val spacer4 = android.widget.Space(this).apply {
            layoutParams = android.widget.LinearLayout.LayoutParams(
                android.widget.LinearLayout.LayoutParams.MATCH_PARENT, 24
            )
        }
        layout.addView(spacer4)
        layout.addView(hint)

        return layout
    }

    private fun startAlarmSound() {
        try {
            val soundPath = PrefsHelper.getCustomSound(this)
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                isLooping = true
            }

            when {
                soundPath.startsWith("local:") -> {
                    val filePath = soundPath.removePrefix("local:")
                    mediaPlayer?.setDataSource(filePath)
                }
                soundPath.startsWith("assets/") -> {
                    val assetPath = "flutter_assets/$soundPath"
                    val afd = assets.openFd(assetPath)
                    mediaPlayer?.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                    afd.close()
                }
                else -> {
                    val alarmUri: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                        ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    mediaPlayer?.setDataSource(this, alarmUri)
                }
            }
            mediaPlayer?.prepare()
            mediaPlayer?.start()
        } catch (_: Exception) {
        }
    }

    private fun startVibration() {
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(VibratorManager::class.java)
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(VIBRATOR_SERVICE) as Vibrator
        }

        val pattern = longArrayOf(0, 500, 200, 500)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(pattern, 0)
        }
    }

    private fun stopAlarm() {
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
        } catch (_: Exception) {
        }
        mediaPlayer = null
        vibrator?.cancel()
        AlarmHelper.stop()
        NotificationHelper.cancelAlarmNotification(this)
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAlarm()
    }

    companion object {
        const val EXTRA_TITLE = "alarm_title"
        const val EXTRA_BODY = "alarm_body"
        const val EXTRA_LEVEL = "alarm_level"
    }
}
