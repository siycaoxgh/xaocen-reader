package com.xaocen.reader

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.content.pm.ServiceInfo

/** Keeps the process eligible for background system TTS and exposes media controls. */
class TtsForegroundService : Service() {
    companion object {
        const val ACTION_START = "com.xaocen.reader.action.TTS_START"
        const val ACTION_STOP = "com.xaocen.reader.action.TTS_STOP"
        const val ACTION_NOTIFICATION_STOP = "com.xaocen.reader.action.TTS_NOTIFICATION_STOP"
        const val ACTION_UPDATE = "com.xaocen.reader.action.TTS_UPDATE"
        const val ACTION_MEDIA_COMMAND = "com.xaocen.reader.action.TTS_MEDIA_COMMAND"
        const val EXTRA_MEDIA_COMMAND = "mediaCommand"
        const val EXTRA_PLAYBACK_STATE = "playbackState"
        private const val CHANNEL_ID = "xaocen_tts"
        private const val NOTIFICATION_ID = 5804
        private var playbackState = "playing"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP, ACTION_NOTIFICATION_STOP -> {
                stopForegroundCompat()
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_UPDATE -> {
                playbackState = intent.getStringExtra(EXTRA_PLAYBACK_STATE) ?: playbackState
                getSystemService(NotificationManager::class.java)
                    .notify(NOTIFICATION_ID, buildNotification())
                return START_STICKY
            }
        }

        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        stopForegroundCompat()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildNotification(): Notification {
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE
            } else {
                0
            }
        val openIntent = PendingIntent.getActivity(
            this,
            5805,
            Intent(this, MainActivity::class.java).apply {
                action = ACTION_START
                this.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            flags,
        )
        val stopIntent = PendingIntent.getActivity(
            this,
            5806,
            Intent(this, MainActivity::class.java).apply {
                action = ACTION_NOTIFICATION_STOP
                this.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            flags,
        )
        val previousIntent = mediaCommandIntent(5807, "previous")
        val playPauseIntent = mediaCommandIntent(5808, "playPause")
        val nextIntent = mediaCommandIntent(5809, "next")
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }
        val style = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            Notification.MediaStyle()
                .setMediaSession(MainActivity.activeTtsMediaSession?.sessionToken)
                .setShowActionsInCompactView(0, 1, 2)
        } else {
            null
        }
        val result = builder
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle("\u6653\u67a8\u9605\u8bfb")
            .setContentText("\u6b63\u5728\u6717\u8bfb")
            .setContentIntent(openIntent)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_TRANSPORT)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOnlyAlertOnce(true)
            .addAction(Notification.Action.Builder(
                android.R.drawable.ic_media_previous,
                "\u4e0a\u4e00\u6bb5",
                previousIntent,
            ).build())
            .addAction(Notification.Action.Builder(
                if (playbackState == "playing") {
                    android.R.drawable.ic_media_pause
                } else {
                    android.R.drawable.ic_media_play
                },
                if (playbackState == "playing") "\u6682\u505c" else "\u64ad\u653e",
                playPauseIntent,
            ).build())
            .addAction(Notification.Action.Builder(
                android.R.drawable.ic_media_next,
                "\u4e0b\u4e00\u6bb5",
                nextIntent,
            ).build())
            .addAction(Notification.Action.Builder(
                android.R.drawable.ic_media_pause,
                "\u505c\u6b62\u6717\u8bfb",
                stopIntent,
            ).build())
        if (style != null) result.setStyle(style)
        return result.build()
    }

    private fun mediaCommandIntent(requestCode: Int, command: String): PendingIntent {
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE
            } else {
                0
            }
        return PendingIntent.getActivity(
            this,
            requestCode,
            Intent(this, MainActivity::class.java).apply {
                action = ACTION_MEDIA_COMMAND
                putExtra(EXTRA_MEDIA_COMMAND, command)
                this.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            flags,
        )
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                "\u6717\u8bfb",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "晓枨阅读朗读"
                setShowBadge(false)
            },
        )
    }

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }
}
