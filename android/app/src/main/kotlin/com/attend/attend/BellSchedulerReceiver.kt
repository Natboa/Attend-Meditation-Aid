package com.attend.attend

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import org.json.JSONObject
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import kotlin.math.max
import kotlin.random.Random

/**
 * Self-sustaining native bell scheduler. Works without Flutter/WorkManager.
 *
 * On each invocation it:
 *   1. Reads NotificationConfig JSON from FlutterSharedPreferences (written by Dart).
 *   2. Cancels stale bell alarms.
 *   3. Schedules bells for the next SCHEDULE_DAYS days via setExactAndAllowWhileIdle.
 *   4. Schedules a sentinel alarm SENTINEL_DAYS_AHEAD days from now that re-triggers
 *      this receiver, extending the horizon indefinitely without opening the app.
 *
 * Entry points:
 *   - BellPlugin.triggerReschedule()  — called from Flutter when config changes
 *   - BootReceiver                    — called after device reboot
 *   - Sentinel alarm                  — self-scheduled every SENTINEL_DAYS_AHEAD days
 */
class BellSchedulerReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "AttendBell"
        const val ACTION_RESCHEDULE = "com.attend.attend.ACTION_RESCHEDULE_BELLS"

        // SharedPreferences written by Flutter's shared_preferences plugin.
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val CONFIG_KEY = "flutter.notification_config"

        // Mirrors Dart's SoundOption.all — maps soundId to raw resource filename (no extension).
        private val SOUND_RAW_NAMES = mapOf(
            "tibetan_bowl"    to "tibetan_bowl_1",
            "meditation_bowl" to "meditation_bowl",
            "singing_bowl"    to "cuenco_zen",
            "gentle_gong"     to "gentle_gong",
            "zen_chime"       to "zen",
            "crystal_gong"    to "bmw_gong",
            "chi_gong"        to "chigong",
            "nepal_echo"      to "nepal_gong_mit_echo",
            "bamboo_flute"    to "flute",
            "deep_meditation" to "meditation",
        )

        // Bell alarm IDs: 1000–1499 (supports up to 500 bells = 10/day × 50 days).
        private const val BELL_BASE_ID = 1000
        private const val MAX_BELLS = 500

        // Sentinel is ID 997. Test bell is 998. Gatha is 2000. No conflicts.
        private const val SENTINEL_ID = 997

        private const val SCHEDULE_DAYS = 30
        private const val SENTINEL_DAYS_AHEAD = 25L
        private const val MIN_BELL_GAP_MS = 30L * 60 * 1000

        /** Schedule or reschedule the full bell set. Safe to call on any thread. */
        fun reschedule(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val configJson = prefs.getString(CONFIG_KEY, null)
            if (configJson == null) {
                Log.d(TAG, "BellSchedulerReceiver: no config in prefs, skipping")
                return
            }

            val config = try {
                parseConfig(configJson)
            } catch (e: Exception) {
                Log.e(TAG, "BellSchedulerReceiver: config parse error: ${e.message}")
                return
            }

            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

            // Always cancel stale alarms first (sentinel + all bell slots).
            cancelAll(context, am)

            if (!config.enabled) {
                Log.d(TAG, "BellSchedulerReceiver: bells disabled, cleared alarms")
                return
            }

            val zone = ZoneId.systemDefault()
            val now = LocalDateTime.now(zone)
            val today = now.toLocalDate()
            var idCursor = 0

            for (dayOffset in 0 until SCHEDULE_DAYS) {
                if (idCursor >= MAX_BELLS) break
                val date = today.plusDays(dayOffset.toLong())
                val cutoff = if (dayOffset == 0) now else null
                val times = computeRandomTimes(config, date, zone, cutoff)
                for (epochMs in times) {
                    if (idCursor >= MAX_BELLS) break
                    val rawName = SOUND_RAW_NAMES[config.bellSoundId] ?: config.bellSoundId
                    scheduleBellAlarm(context, am, BELL_BASE_ID + idCursor, epochMs, config.bellSoundId, rawName)
                    idCursor++
                }
            }
            Log.d(TAG, "BellSchedulerReceiver: scheduled $idCursor bells across $SCHEDULE_DAYS days")

            // Sentinel: fires in SENTINEL_DAYS_AHEAD days and runs reschedule() again,
            // extending the horizon perpetually without the app ever being opened.
            val sentinelMs = today.plusDays(SENTINEL_DAYS_AHEAD)
                .atStartOfDay(zone).toInstant().toEpochMilli()
            val sentinelPi = PendingIntent.getBroadcast(
                context, SENTINEL_ID,
                Intent(context, BellSchedulerReceiver::class.java).apply {
                    action = ACTION_RESCHEDULE
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, sentinelMs, sentinelPi)
            Log.d(TAG, "BellSchedulerReceiver: sentinel set for $SENTINEL_DAYS_AHEAD days from now")
        }

        fun cancelAll(context: Context) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            cancelAll(context, am)
        }

        private fun cancelAll(context: Context, am: AlarmManager) {
            for (i in 0 until MAX_BELLS) {
                cancelPendingIntent(context, am, BELL_BASE_ID + i, BellAlarmReceiver::class.java)
            }
            val sentinelPi = PendingIntent.getBroadcast(
                context, SENTINEL_ID,
                Intent(context, BellSchedulerReceiver::class.java).apply { action = ACTION_RESCHEDULE },
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
            )
            if (sentinelPi != null) { am.cancel(sentinelPi); sentinelPi.cancel() }
        }

        private fun cancelPendingIntent(context: Context, am: AlarmManager, id: Int, cls: Class<*>) {
            val pi = PendingIntent.getBroadcast(
                context, id, Intent(context, cls),
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
            )
            if (pi != null) { am.cancel(pi); pi.cancel() }
        }

        private fun scheduleBellAlarm(
            context: Context,
            am: AlarmManager,
            id: Int,
            epochMs: Long,
            soundId: String,
            soundRawName: String,
        ) {
            val channelId = "mindfulness_bell_v2_$soundId"
            val pi = PendingIntent.getBroadcast(
                context, id,
                Intent(context, BellAlarmReceiver::class.java).apply {
                    putExtra(BellAlarmReceiver.EXTRA_NOTIF_ID, id)
                    putExtra(BellAlarmReceiver.EXTRA_CHANNEL_ID, channelId)
                    putExtra(BellAlarmReceiver.EXTRA_SOUND_RAW_NAME, soundRawName)
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, epochMs, pi)
        }

        private fun computeRandomTimes(
            config: BellConfig,
            date: LocalDate,
            zone: ZoneId,
            cutoffTime: LocalDateTime?,
        ): List<Long> {
            // ISO weekday: 1=Mon … 7=Sun — matches Dart's DateTime.weekday.
            if (!config.activeDays.contains(date.dayOfWeek.value)) return emptyList()

            val startMs = date.atTime(config.startHour, 0).atZone(zone).toInstant().toEpochMilli()
            val endMs = date.atTime(config.endHour, 0).atZone(zone).toInstant().toEpochMilli()
            if (endMs <= startMs) return emptyList()

            val n = config.frequencyPerDay
            val rangeMs = endMs - startMs

            // Jittered-grid: divide window into n equal slots, pick one random time per slot.
            // Jitter is capped so adjacent bells are always ≥ MIN_BELL_GAP_MS apart.
            val times: List<Long> = if (n <= 1) {
                listOf(startMs + Random.nextLong(rangeMs))
            } else {
                val slotMs = rangeMs / n
                val jitterMs = max(1L, slotMs - MIN_BELL_GAP_MS)
                (0 until n).map { i -> startMs + i * slotMs + Random.nextLong(jitterMs) }.sorted()
            }

            val cutoffMs = cutoffTime?.atZone(zone)?.toInstant()?.toEpochMilli() ?: Long.MIN_VALUE
            return times.filter { it > cutoffMs }
        }

        private fun parseConfig(json: String): BellConfig {
            val obj = JSONObject(json)
            val arr = obj.getJSONArray("activeDays")
            val activeDays = (0 until arr.length()).map { arr.getInt(it) }
            return BellConfig(
                enabled = obj.getBoolean("enabled"),
                activeDays = activeDays,
                startHour = obj.getInt("startHour"),
                endHour = obj.getInt("endHour"),
                frequencyPerDay = obj.getInt("frequencyPerDay"),
                bellSoundId = obj.getString("bellSoundId"),
            )
        }

        private data class BellConfig(
            val enabled: Boolean,
            val activeDays: List<Int>,
            val startHour: Int,
            val endHour: Int,
            val frequencyPerDay: Int,
            val bellSoundId: String,
        )
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_RESCHEDULE) return
        Log.d(TAG, "BellSchedulerReceiver.onReceive: sentinel fired, rescheduling")
        reschedule(context)
    }
}
