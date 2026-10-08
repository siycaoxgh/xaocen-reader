package com.xaocen.reader

import android.view.KeyEvent
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.graphics.Color
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.Manifest
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "xaocen.reader/paged_input"
    private val fontsChannelName = "xaocen.reader/fonts"
    private val windowChannelName = "xaocen.reader/window"
    private val ttsChannelName = "xaocen.reader/tts_background"
    private val accountChannelName = "xaocen.reader/account"
    private var pagedReaderActive = false
    private var inputCaptureActive = false
    private var volumeBindingActive = false
    private var volumeUpBindingActive = false
    private var volumeDownBindingActive = false
    private lateinit var inputChannel: MethodChannel
    private lateinit var fontsChannel: MethodChannel
    private lateinit var windowChannel: MethodChannel
    private lateinit var ttsChannel: MethodChannel
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var audioFocusHeld = false
    private var mediaSession: MediaSession? = null
    private val audioFocusListener = AudioManager.OnAudioFocusChangeListener { change ->
        when (change) {
            AudioManager.AUDIOFOCUS_GAIN -> {
                if (audioFocusHeld) ttsChannel.invokeMethod("audioFocusGained", null)
            }
            AudioManager.AUDIOFOCUS_LOSS,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                if (audioFocusHeld) ttsChannel.invokeMethod("audioFocusLost", null)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        inputChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        fontsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, fontsChannelName)
        windowChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, windowChannelName)
        ttsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ttsChannelName)
        val accountChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, accountChannelName)
        accountChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "openExternalUrl" -> {
                    val value = call.arguments as? String
                    if (value.isNullOrBlank()) {
                        result.error("invalid_url", "URL is required", null)
                    } else {
                        try {
                            startActivity(Intent(Intent.ACTION_VIEW, android.net.Uri.parse(value)))
                            result.success(true)
                        } catch (error: Exception) {
                            result.error("open_failed", error.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
        ttsChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    startTtsBackgroundSession()
                    result.success(null)
                }
                "stop" -> {
                    stopTtsBackgroundSession()
                    result.success(null)
                }
                "setPlaybackState" -> {
                    updateTtsMediaPlaybackState(call.arguments?.toString() ?: "stopped")
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        windowChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setDisplayCutout" -> {
                    val extend = call.arguments as? Boolean ?: false
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                        val params = window.attributes
                        params.layoutInDisplayCutoutMode = if (extend) {
                            android.view.WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
                        } else {
                            android.view.WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_NEVER
                        }
                        window.attributes = params
                    }
                    result.success(null)
                }
                "setSystemBars" -> {
                    val args = call.arguments as? Map<*, *>
                    val showStatus = args?.get("showStatusBar") as? Boolean ?: true
                    val hideNavigation = args?.get("hideNavigationBar") as? Boolean ?: false
                    window.statusBarColor = Color.TRANSPARENT
                    window.navigationBarColor = Color.TRANSPARENT
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                        val controller = window.insetsController
                        if (controller != null) {
                            controller.systemBarsBehavior =
                                android.view.WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                            var types = 0
                            if (!showStatus) types = types or android.view.WindowInsets.Type.statusBars()
                            if (hideNavigation) types = types or android.view.WindowInsets.Type.navigationBars()
                            if (types != 0) controller.hide(types)
                            var showTypes = 0
                            if (showStatus) showTypes = showTypes or android.view.WindowInsets.Type.statusBars()
                            if (!hideNavigation) showTypes = showTypes or android.view.WindowInsets.Type.navigationBars()
                            if (showTypes != 0) controller.show(showTypes)
                        }
                    }
                    result.success(null)
                }
                "setScreenOrientation" -> {
                    when (call.arguments as? String) {
                        "portrait" -> requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
                        "landscape" -> requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
                        "autoRotate" -> requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR
                        else -> requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
                    }
                    result.success(null)
                }
                "getBatteryStatus" -> {
                    val manager = getSystemService(android.content.Context.BATTERY_SERVICE) as android.os.BatteryManager
                    val level = manager.getIntProperty(android.os.BatteryManager.BATTERY_PROPERTY_CAPACITY)
                    val intent = registerReceiver(null, android.content.IntentFilter(android.content.Intent.ACTION_BATTERY_CHANGED))
                    val status = intent?.getIntExtra(android.os.BatteryManager.EXTRA_STATUS, -1) ?: -1
                    val charging = status == android.os.BatteryManager.BATTERY_STATUS_CHARGING ||
                        status == android.os.BatteryManager.BATTERY_STATUS_FULL
                    if (level !in 0..100) {
                        result.success(null)
                    } else {
                        result.success(mapOf("percent" to level, "charging" to charging))
                    }
                }
                else -> result.notImplemented()
            }
        }
        fontsChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "listAvailableFonts" -> {
                    // Android intentionally exposes only fonts that are visible
                    // through the public system asset API.  If a vendor does
                    // not expose that list, Dart safely falls back to the
                    // platform default rather than guessing private paths.
                    val names = resources.assets.list("fonts")
                        ?.mapNotNull { file ->
                            val family = file.substringBeforeLast(
                                '.',
                                missingDelimiterValue = "",
                            ).replace('_', ' ').trim()
                            family.takeIf { it.isNotBlank() }?.let {
                                file to it
                            }
                        }
                        ?.distinctBy { it.first }
                        ?.sortedBy { it.second }
                        ?: emptyList()
                    result.success(names.map { (file, family) ->
                        mapOf(
                            "id" to "android.system.file.${file.lowercase()}",
                            "familyName" to family,
                            "displayName" to family,
                        )
                    })
                }
                else -> result.notImplemented()
            }
        }
        inputChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setPagedActive" -> {
                    pagedReaderActive = call.arguments as? Boolean ?: false
                    result.success(null)
                }
                "setInputCaptureActive" -> {
                    inputCaptureActive = call.arguments as? Boolean ?: false
                    result.success(null)
                }
                "setVolumeBindingActive" -> {
                    when (val args = call.arguments) {
                        is Boolean -> volumeBindingActive = args
                        is Map<*, *> -> {
                            volumeBindingActive = args["all"] as? Boolean ?: false
                            volumeUpBindingActive = args["up"] as? Boolean ?: false
                            volumeDownBindingActive = args["down"] as? Boolean ?: false
                        }
                    }
                    result.success(null)
                }
                "setKeepScreenOn" -> {
                    val enabled = call.arguments as? Boolean ?: false
                    if (enabled) {
                        window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val isVolume = event.keyCode == KeyEvent.KEYCODE_VOLUME_UP ||
            event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN
        val keyBindingActive = when (event.keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP -> volumeUpBindingActive
            KeyEvent.KEYCODE_VOLUME_DOWN -> volumeDownBindingActive
            else -> volumeBindingActive
        }
        if ((keyBindingActive || inputCaptureActive) && isVolume) {
            if (event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
                val input = if (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
                    "android.volumeUp"
                } else {
                    "android.volumeDown"
                }
                inputChannel.invokeMethod("volumeInput", input)
            }
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action == TtsForegroundService.ACTION_NOTIFICATION_STOP) {
            stopTtsBackgroundSession()
            ttsChannel.invokeMethod("mediaCommand", "stop")
        } else if (intent.action == TtsForegroundService.ACTION_MEDIA_COMMAND) {
            ttsChannel.invokeMethod(
                "mediaCommand",
                intent.getStringExtra(TtsForegroundService.EXTRA_MEDIA_COMMAND),
            )
        }
    }

    override fun onDestroy() {
        if (isFinishing) stopTtsBackgroundSession()
        super.onDestroy()
    }

    private fun startTtsBackgroundSession() {
        startTtsMediaSession()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 5807)
        }
        val intent = Intent(this, TtsForegroundService::class.java).apply {
            action = TtsForegroundService.ACTION_START
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        requestTtsAudioFocus()
    }

    private fun stopTtsBackgroundSession() {
        abandonTtsAudioFocus()
        stopService(Intent(this, TtsForegroundService::class.java))
        releaseTtsMediaSession()
    }

    private fun startTtsMediaSession() {
        if (mediaSession != null) return
        mediaSession = MediaSession(this, "晓枨阅读朗读").apply {
            setFlags(
                MediaSession.FLAG_HANDLES_MEDIA_BUTTONS or
                    MediaSession.FLAG_HANDLES_TRANSPORT_CONTROLS,
            )
            setCallback(object : MediaSession.Callback() {
                override fun onPlay() = sendMediaCommand("playPause")
                override fun onPause() = sendMediaCommand("playPause")
                override fun onSkipToNext() = sendMediaCommand("next")
                override fun onSkipToPrevious() = sendMediaCommand("previous")
                override fun onStop() = sendMediaCommand("stop")
            })
            setActive(true)
        }
        activeTtsMediaSession = mediaSession
    }

    private fun sendMediaCommand(command: String) {
        if (::ttsChannel.isInitialized) ttsChannel.invokeMethod("mediaCommand", command)
    }

    private fun releaseTtsMediaSession() {
        mediaSession?.setCallback(null)
        mediaSession?.isActive = false
        mediaSession?.release()
        mediaSession = null
        activeTtsMediaSession = null
    }

    private fun updateTtsMediaPlaybackState(state: String) {
        val session = mediaSession ?: return
        val actions = PlaybackState.ACTION_PLAY or
            PlaybackState.ACTION_PAUSE or
            PlaybackState.ACTION_PLAY_PAUSE or
            PlaybackState.ACTION_SKIP_TO_NEXT or
            PlaybackState.ACTION_SKIP_TO_PREVIOUS or
            PlaybackState.ACTION_STOP
        val playbackState = when (state) {
            "playing" -> PlaybackState.STATE_PLAYING
            "paused" -> PlaybackState.STATE_PAUSED
            else -> PlaybackState.STATE_STOPPED
        }
        session.setPlaybackState(
            PlaybackState.Builder()
                .setActions(actions)
                .setState(playbackState, PlaybackState.PLAYBACK_POSITION_UNKNOWN, 1.0f)
                .build(),
        )
        if (::ttsChannel.isInitialized) {
            startService(Intent(this, TtsForegroundService::class.java).apply {
                action = TtsForegroundService.ACTION_UPDATE
                putExtra(TtsForegroundService.EXTRA_PLAYBACK_STATE, state)
            })
        }
    }

    companion object {
        @JvmStatic
        var activeTtsMediaSession: MediaSession? = null
    }

    private fun requestTtsAudioFocus() {
        audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
            .build()
        val result = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                .setAudioAttributes(attributes)
                .setOnAudioFocusChangeListener(audioFocusListener)
                .build()
            audioManager?.requestAudioFocus(audioFocusRequest!!)
        } else {
            @Suppress("DEPRECATION")
            audioManager?.requestAudioFocus(
                audioFocusListener,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK,
            )
        }
        audioFocusHeld = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
    }

    private fun abandonTtsAudioFocus() {
        if (!audioFocusHeld) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { audioManager?.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            audioManager?.abandonAudioFocus(audioFocusListener)
        }
        audioFocusRequest = null
        audioFocusHeld = false
    }
}
