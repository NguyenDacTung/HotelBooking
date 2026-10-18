package com.example.hotel_booking

import io.flutter.embedding.android.FlutterFragmentActivity
import android.os.Bundle
import java.io.File
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
