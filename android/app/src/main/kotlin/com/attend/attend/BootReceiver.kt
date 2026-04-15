package com.attend.attend

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import dev.fluttercommunity.workmanager.BackgroundWorker

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        // BackgroundWorker reads DART_TASK_KEY to know which Dart task to run.
        // Without it the worker fails immediately and bells are never rescheduled.
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
