package com.batteryguardian.battery_guardian

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import java.io.File

object AlarmHelper {
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private val handler = Handler(Looper.getMainLooper())
    private var soundRunnable: Runnable? = null
    private var vibrationRunnable: Runnable? = null
    private var isActive = false

    fun start(context: Context, soundEnabled: Boolean, vibrationEnabled: Boolean) {
        if (isActive) return
        isActive = true

        if (soundEnabled) {
            playSound(context)
            soundRunnable = object : Runnable {
                override fun run() {
                    if (isActive) {
                        playSound(context)
                        handler.postDelayed(this, 3000)
                    }
                }
            }
            handler.postDelayed(soundRunnable!!, 3000)
        }

        if (vibrationEnabled) {
            vibrate(context)
            vibrationRunnable = object : Runnable {
                override fun run() {
                    if (isActive) {
                        vibrate(context)
                        handler.postDelayed(this, 3000)
                    }
                }
            }
            handler.postDelayed(vibrationRunnable!!, 3000)
        }
    }

    fun stop() {
        isActive = false
        soundRunnable?.let { handler.removeCallbacks(it) }
        vibrationRunnable?.let { handler.removeCallbacks(it) }
        soundRunnable = null
        vibrationRunnable = null

        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
        } catch (_: Exception) {
        }
        mediaPlayer = null

        try {
            vibrator?.cancel()
        } catch (_: Exception) {
        }
    }

    private fun playSound(context: Context) {
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
        } catch (_: Exception) {
        }

        val soundPath = PrefsHelper.getCustomSound(context)
        mediaPlayer = MediaPlayer().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            isLooping = true
        }

        try {
            when {
                soundPath.startsWith("local:") -> {
                    val filePath = soundPath.removePrefix("local:")
                    mediaPlayer?.setDataSource(filePath)
                }
                soundPath.startsWith("assets/") -> {
                    val assetPath = "flutter_assets/$soundPath"
                    val afd = context.assets.openFd(assetPath)
                    mediaPlayer?.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                    afd.close()
                }
                else -> {
                    val file = File(soundPath)
                    if (file.exists()) {
                        mediaPlayer?.setDataSource(soundPath)
                    } else {
                        playDefaultSound(context)
                        return
                    }
                }
            }
            mediaPlayer?.prepare()
            mediaPlayer?.start()
        } catch (_: Exception) {
            playDefaultSound(context)
        }
    }

    private fun playDefaultSound(context: Context) {
        try {
            mediaPlayer?.release()
        } catch (_: Exception) {
        }

        val alarmUri: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        mediaPlayer = MediaPlayer().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            setDataSource(context, alarmUri)
            isLooping = true
            prepare()
            start()
        }
    }

    private fun vibrate(context: Context) {
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = context.getSystemService(VibratorManager::class.java)
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        val pattern = longArrayOf(0, 500, 200, 500)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator?.vibrate(VibrationEffect.createWaveform(pattern, -1))
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(pattern, 0)
        }
    }
}
