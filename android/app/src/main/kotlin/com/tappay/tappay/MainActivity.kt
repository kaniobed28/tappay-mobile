package com.tappay.tappay

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tappay/hce")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isSupported" -> result.success(
                        packageManager.hasSystemFeature(PackageManager.FEATURE_NFC_HOST_CARD_EMULATION),
                    )
                    "setPayload" -> {
                        val text = call.argument<String>("text")
                        if (text.isNullOrEmpty()) {
                            result.error("BAD_ARGS", "text is required", null)
                        } else {
                            TapPayHceService.setNdefText(text)
                            result.success(true)
                        }
                    }
                    "clearPayload" -> {
                        TapPayHceService.clear()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
