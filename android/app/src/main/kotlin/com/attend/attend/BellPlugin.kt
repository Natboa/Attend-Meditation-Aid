package com.attend.attend

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * FlutterPlugin that exposes `attend/bells` MethodChannel for scheduling and cancelling
 * mindfulness bell alarms via Android's AlarmManager.
 *
 * Registered in GeneratedPluginRegistrant so it is available in ALL FlutterEngine
 * contexts — both foreground (MainActivity) and background (WorkManager).
 *
 * Methods:
 *   scheduleBell(id: Int, epochMs: Long, channelId: String) — schedules an exact alarm
 *   cancelBell(id: Int)                                     — cancels a scheduled alarm
 */
class BellPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    companion object {
        private const val TAG = "AttendBell"
        const val CHANNEL_NAME = "attend/bells"
    }

    // ── FlutterPlugin ──────────────────────────────────────────────────────────

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        Log.d(TAG, "BellPlugin attached to engine")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // ── MethodCallHandler ──────────────────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // Full native reschedule: reads config from SharedPrefs, schedules 30 days
            // of bells, and arms the 25-day sentinel. Runs on a background thread so
            // the main thread is not blocked by ~90-300 AlarmManager API calls.
            "triggerReschedule" -> {
                Thread { BellSchedulerReceiver.reschedule(context) }.start()
                result.success(null)
            }
            // Cancel all bell alarms and the sentinel. Called when bells are disabled.
            "cancelScheduler" -> {
                BellSchedulerReceiver.cancelAll(context)
                result.success(null)
            }
            // Individual alarm scheduling — used only for the test bell (id 998).
            "scheduleBell" -> {
                val id = call.argument<Int>("id")
                    ?: return result.error("ARGS", "id required", null)
                val epochMs = call.argument<Long>("epochMs")
                    ?: return result.error("ARGS", "epochMs required", null)
                val channelId = call.argument<String>("channelId")
                    ?: return result.error("ARGS", "channelId required", null)
                val soundRawName = call.argument<String>("soundRawName")

                scheduleBell(id, epochMs, channelId, soundRawName)
                result.success(null)
            }
            "cancelBell" -> {
                val id = call.argument<Int>("id")
                    ?: return result.error("ARGS", "id required", null)
                cancelBell(id)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    // ── Alarm management ──────────────────────────────────────────────────────

    private fun scheduleBell(id: Int, epochMs: Long, channelId: String, soundRawName: String?) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, BellAlarmReceiver::class.java).apply {
            putExtra(BellAlarmReceiver.EXTRA_NOTIF_ID, id)
            putExtra(BellAlarmReceiver.EXTRA_CHANNEL_ID, channelId)
            if (soundRawName != null) putExtra(BellAlarmReceiver.EXTRA_SOUND_RAW_NAME, soundRawName)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        // FLAG_UPDATE_CURRENT always returns non-null — safe to use !!
        val pi = PendingIntent.getBroadcast(context, id, intent, flags)!!
        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, epochMs, pi)
        Log.d(TAG, "Scheduled bell id=$id epochMs=$epochMs channelId=$channelId")
    }

    private fun cancelBell(id: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        // FLAG_NO_CREATE returns null if no alarm exists for this id.
        val intent = Intent(context, BellAlarmReceiver::class.java)
        val flags = PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        val pi = PendingIntent.getBroadcast(context, id, intent, flags)
        if (pi != null) {
            alarmManager.cancel(pi)
            pi.cancel()
            Log.d(TAG, "Cancelled bell id=$id")
        } else {
            Log.d(TAG, "cancelBell id=$id — no pending alarm found")
        }
    }
}
