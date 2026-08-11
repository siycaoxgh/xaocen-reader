package com.xaocen.xaocen_reader

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "xaocen.reader/paged_input"
    private var pagedReaderActive = false
    private var inputCaptureActive = false
    private var volumeBindingActive = false
    private lateinit var inputChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        inputChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
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
                    volumeBindingActive = call.arguments as? Boolean ?: false
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
        if ((volumeBindingActive || inputCaptureActive) && isVolume) {
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
