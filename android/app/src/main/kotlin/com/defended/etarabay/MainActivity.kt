package com.defended.etarabay

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

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

        // The in-app update, for lib/widgets/update_flow.dart: the APK the
        // app downloaded into cache/update/ goes to Android's own installer.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "etarabay/install")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        // Android 8 and up asks once per app; below, the
                        // installer asks by itself.
                        "canInstall" -> result.success(
                            Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
                                packageManager.canRequestPackageInstalls())
                        // The APK this phone is running, which an update
                        // patch is applied to.
                        "installedApk" -> result.success(applicationInfo.sourceDir)
                        "openInstallSettings" -> {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                startActivity(Intent(
                                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                    Uri.parse("package:$packageName")))
                            }
                            result.success(null)
                        }
                        "install" -> {
                            val path = call.argument<String>("path")
                            if (path == null) {
                                result.error("no_path", "no path", null)
                            } else {
                                val uri = FileProvider.getUriForFile(
                                    this, "$packageName.updates", File(path))
                                val intent = Intent(Intent.ACTION_VIEW).apply {
                                    setDataAndType(uri, "application/vnd.android.package-archive")
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(null)
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("install_failed", e.message, null)
                }
            }
    }
}
