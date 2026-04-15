package com.attend.attend

import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val batteryChannel = "attend/battery"
    private val notifChannel = "attend/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register BellPlugin manually — it is not in pubspec.yaml so GeneratedPluginRegistrant
        // does not include it automatically. For the WorkManager background engine (which does
        // not call configureFlutterEngine) the bells channel will throw MissingPluginException;
        // that is acceptable since WorkManager rescheduling is handled separately.
        flutterEngine.plugins.add(BellPlugin())

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, batteryChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isIgnoringBatteryOptimizations" -> {
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        val intent = Intent(
                            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, notifChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Clears the flutter_local_notifications scheduled-notification
                    // cache. Called once on first launch after a corrupt-cache bug
                    // (BigTextStyleInformation missing type parameter). Safe to call:
                    // pending alarms still fire via Intent extras; only cancel() /
                    // pendingNotificationRequests() rely on this cache.
                    "clearScheduledCache" -> {
                        // flutter_local_notifications stores scheduled notifications in a
                        // SharedPreferences file AND key both named "scheduled_notifications".
                        // "notification_plugin_cache" is a separate file used for other prefs.
                        applicationContext
                            .getSharedPreferences("scheduled_notifications", MODE_PRIVATE)
                            .edit()
                            .remove("scheduled_notifications")
                            .apply()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
