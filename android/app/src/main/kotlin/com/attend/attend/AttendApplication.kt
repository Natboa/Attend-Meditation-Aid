package com.attend.attend

import android.app.Application
import androidx.work.Configuration
import io.flutter.embedding.engine.FlutterEngineCache

class AttendApplication : Application(), Configuration.Provider {
    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setMinimumLoggingLevel(android.util.Log.INFO)
            .build()
}
