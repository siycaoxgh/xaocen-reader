package com.xaocen.xaocen_reader

import android.view.KeyEvent
import android.content.pm.ActivityInfo
import android.graphics.Color
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "xaocen.reader/paged_input"
    private val fontsChannelName = "xaocen.reader/fonts"
    private val windowChannelName = "xaocen.reader/window"
    private var pagedReaderActive = false
    private var inputCaptureActive = false
    private var volumeBindingActive = false
    private var volumeUpBindingActive = false
    private var volumeDownBindingActive = false
    private lateinit var inputChannel: MethodChannel
    private lateinit var fontsChannel: MethodChannel
    private lateinit var windowChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        inputChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        fontsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, fontsChannelName)
        windowChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, windowChannelName)
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
}
