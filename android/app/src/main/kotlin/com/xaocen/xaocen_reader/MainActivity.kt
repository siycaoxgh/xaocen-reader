package com.xaocen.xaocen_reader

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "xaocen.reader/paged_input"
    private val fontsChannelName = "xaocen.reader/fonts"
    private var pagedReaderActive = false
    private var inputCaptureActive = false
    private var volumeBindingActive = false
    private var volumeUpBindingActive = false
    private var volumeDownBindingActive = false
    private lateinit var inputChannel: MethodChannel
    private lateinit var fontsChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        inputChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        fontsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, fontsChannelName)
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
