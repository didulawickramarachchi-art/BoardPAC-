package com.example.frontend

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val secureScreenChannel = "board_pac/secure_screen"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            secureScreenChannel,
        ).setMethodCallHandler { call, result ->
            if (call.method != "setProtected") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val protected = call.argument<Boolean>("protected") ?: false
            runOnUiThread {
                if (protected) {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
                result.success(null)
            }
        }
    }
}
