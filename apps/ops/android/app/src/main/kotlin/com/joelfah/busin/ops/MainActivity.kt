package com.joelfah.busin.ops

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createUpdatesChannel()
    }

    // The channel the server's notifications name (busin_updates), as in the student app. Android 8 and later need it
    // to exist, and it is where the person can mute or change these notifications.
    private fun createUpdatesChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            "busin_updates",
            getString(R.string.channel_updates_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply { description = getString(R.string.channel_updates_description) }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }
}
