package com.joelfah.busin.student

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createUpdatesChannel()
        // The boarding code screen asks for the secure flag: no screenshots, no screen recording, and a
        // blank preview in the recent-apps list.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.busin/screen_security")
            .setMethodCallHandler { call, result ->
                if (call.method == "setSecure") {
                    if (call.arguments as? Boolean == true) {
                        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    // The channel the server's notifications name (busin_updates). Android 8 and later need it to exist, and it
    // is where the person can mute or change these notifications.
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
