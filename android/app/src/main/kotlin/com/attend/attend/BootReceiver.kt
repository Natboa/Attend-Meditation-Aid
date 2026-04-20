package com.attend.attend

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import dev.fluttercommunity.workmanager.BackgroundWorker

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        // Reschedule bells entirely in native Kotlin — no Flutter engine needed.
        // BellSchedulerReceiver reads config from SharedPreferences and arms all
        // alarms + the self-sustaining sentinel in one synchronous pass.
        BellSchedulerReceiver.reschedule(context)
        Log.d("AttendBell", "BootReceiver: native bell reschedule triggered")

        // WorkManager is kept only to refresh the daily gatha notification content,
        // which requires a Flutter engine to load the gatha JSON asset.
        val inputData = Data.Builder()
            .putString(BackgroundWorker.DART_TASK_KEY, "attend_daily_bell_scheduler")
            .build()

        val request = OneTimeWorkRequestBuilder<BackgroundWorker>()
            .setInputData(inputData)
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.NOT_REQUIRED)
                    .build()
            )
            .build()

        WorkManager.getInstance(context).enqueue(request)
    }
}
