package com.hifivetech.smartpdf

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Draw behind system bars (edge-to-edge) for Android 15+ compliance.
        // Flutter's SafeArea handles inset padding in the UI.
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "smart_pdf/content_resolver",
        ).setMethodCallHandler { call, result ->
            if (call.method == "readContentUri") {
                val uri = call.argument<String>("uri")
                if (uri == null) {
                    result.error("INVALID_ARG", "uri is null", null)
                    return@setMethodCallHandler
                }
                try {
                    val parsed = android.net.Uri.parse(uri)
                    val bytes = contentResolver.openInputStream(parsed)?.use { it.readBytes() }
                    if (bytes == null) {
                        result.error("READ_FAILED", "Could not open stream for URI", null)
                    } else {
                        result.success(bytes)
                    }
                } catch (e: Exception) {
                    result.error("READ_FAILED", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
