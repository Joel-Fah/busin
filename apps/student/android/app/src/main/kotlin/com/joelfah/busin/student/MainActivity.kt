package com.joelfah.busin.student

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
}
