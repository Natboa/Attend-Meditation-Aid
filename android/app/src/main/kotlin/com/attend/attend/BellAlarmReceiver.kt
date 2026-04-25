package com.attend.attend

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * Handles bell alarms scheduled via AlarmManager. Posts the mindfulness bell
 * notification directly, bypassing flutter_local_notifications' ScheduledNotificationReceiver
 * which was silently failing on Samsung One UI / Android 16.
 *
 * Reads channelId and notifId from Intent extras — both are stored in the PendingIntent
 * by BellPlugin.scheduleBell() at scheduling time.
 */
class BellAlarmReceiver : BroadcastReceiver() {

    companion object {
        const val TAG = "AttendBell"
        const val EXTRA_NOTIF_ID = "notifId"
        const val EXTRA_CHANNEL_ID = "channelId"
        const val EXTRA_SOUND_RAW_NAME = "soundRawName"

        // Ensures the notification channel exists with the correct sound.
        // Called natively so bells work even if the Flutter-side channel creation failed.
        fun ensureChannel(context: Context, channelId: String, soundRawName: String) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (nm.getNotificationChannel(channelId) != null) return
            val soundUri = Uri.parse(
                "android.resource://${context.packageName}/raw/$soundRawName"
            )
            val audioAttrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .build()
            val channel = NotificationChannel(
                channelId,
                "Mindfulness bell",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                setSound(soundUri, audioAttrs)
            }
            nm.createNotificationChannel(channel)
            Log.d(TAG, "Created channel natively: $channelId sound=$soundRawName")
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val notifId = intent.getIntExtra(EXTRA_NOTIF_ID, -1)
        val channelId = intent.getStringExtra(EXTRA_CHANNEL_ID)
        val soundRawName = intent.getStringExtra(EXTRA_SOUND_RAW_NAME)

        Log.d(TAG, "BellAlarmReceiver.onReceive: notifId=$notifId channelId=$channelId soundRawName=$soundRawName")

        if (notifId == -1 || channelId == null) {
            Log.e(TAG, "Missing extras — notifId=$notifId channelId=$channelId, aborting")
            return
        }

        // Guarantee the channel exists with the correct sound before posting.
        // This is the native fallback for cases where Flutter-side channel creation failed.
        if (soundRawName != null) {
            ensureChannel(context, channelId, soundRawName)
        }

        try {
            // Icon: look up the launcher icon the same way flutter_local_notifications does.
            // getIdentifier("@mipmap/ic_launcher", "drawable", package) resolves to
            // R.mipmap.ic_launcher via Android's @type/name resource syntax.
            val iconResId = context.resources.getIdentifier(
                "@mipmap/ic_launcher", "drawable", context.packageName
            ).takeIf { it != 0 } ?: R.mipmap.ic_launcher

            val notification = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(iconResId)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .setTimeoutAfter(5000) // auto-dismiss after 5 s — bell plays, then clears
                .build()

            val nm = NotificationManagerCompat.from(context)
            nm.notify(notifId, notification)
            Log.d(TAG, "Bell notification posted: id=$notifId channel=$channelId")
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException posting bell id=$notifId: ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to post bell id=$notifId: ${e.message}", e)
        }
    }
}
