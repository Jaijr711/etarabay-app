package com.defended.etarabay

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // What the phone can do, for lib/services/device_performance.dart:
        // a phone Android itself calls low-RAM, or one with little memory or
        // few cores, gets the app's lighter drawing.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "etarabay/device")
            .setMethodCallHandler { call, result ->
                if (call.method == "profile") {
                    val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                    val info = ActivityManager.MemoryInfo()
                    am.getMemoryInfo(info)
                    result.success(mapOf(
                        "lowRam" to am.isLowRamDevice,
                        "totalMemMb" to (info.totalMem / (1024 * 1024)).toInt(),
                        "cores" to Runtime.getRuntime().availableProcessors(),
                        "sdk" to Build.VERSION.SDK_INT,
                    ))
                } else {
                    result.notImplemented()
                }
            }
    }
}
