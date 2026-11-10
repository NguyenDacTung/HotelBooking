package com.example.hotel_booking

import io.flutter.embedding.android.FlutterFragmentActivity
import android.os.Bundle
import android.os.Build
import org.json.JSONObject
import java.io.File
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tetra/client-config")
            .setMethodCallHandler { call, result ->
                if (call.method != "load") {
                    result.notImplemented()
                } else {
                    val config = JSONObject(BuildConfig.TETRA_CLIENT_CONFIGURATION)
                    if (config.optString("API_BASE_URL").isEmpty()) {
                        val emulator = Build.FINGERPRINT.startsWith("generic") ||
                            Build.FINGERPRINT.startsWith("unknown") ||
                            Build.MODEL.contains("google_sdk") || Build.MODEL.contains("Emulator") ||
                            Build.MODEL.contains("Android SDK built for") ||
                            Build.PRODUCT.contains("sdk") || Build.HARDWARE in listOf("goldfish", "ranchu")
                        config.put("API_BASE_URL", if (emulator) "http://10.0.2.2:8000" else "http://127.0.0.1:8000")
                    }
                    result.success(config.toString())
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tetra/biometric-login")
            .setMethodCallHandler(BiometricLogin(this))
    }
    override fun onCreate(savedInstanceState: Bundle?) {
        // OSM reloads these preferences when each native map is created.
        // Use our app identity, not the generic example package/library agent.
        // Keep map cache private and separate from tiles fetched before this fix.
        val mapCache = File(cacheDir, "tetra-osm-v1").apply { mkdirs() }
        val tiles = File(mapCache, "tiles").apply { mkdirs() }
        @Suppress("DEPRECATION")
        val version = packageManager.getPackageInfo(packageName, 0).versionName ?: "1.0"
        getSharedPreferences("${packageName}_preferences", MODE_PRIVATE).edit()
            .putString("osmdroid.userAgentValue", "TETRAHotel/$version (Android; $packageName)")
            .putString("osmdroid.basePath", mapCache.absolutePath)
            .putString("osmdroid.cachePath", tiles.absolutePath)
            .apply()
        super.onCreate(savedInstanceState)
    }
}
