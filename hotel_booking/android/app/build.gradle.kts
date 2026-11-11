import groovy.json.JsonOutput
import groovy.json.JsonSlurper
import java.net.URI
import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// One public configuration for Dart and native SDKs, also for plain flutter run.
// Read with a Provider so Gradle observes edits between builds.
val clientKeys = setOf(
    "API_BASE_URL", "GOOGLE_SERVER_CLIENT_ID", "FACEBOOK_ENABLED",
    "TTTP_FACEBOOK_APP_ID", "TTTP_FACEBOOK_CLIENT_TOKEN",
    "FIREBASE_API_KEY", "FIREBASE_APP_ID", "FIREBASE_MESSAGING_SENDER_ID", "FIREBASE_PROJECT_ID"
)
val localClientFile = rootProject.file("../config/flutter.local.json")
val clientFile = if (localClientFile.isFile) localClientFile else rootProject.file("../config/flutter.example.json")
val publicClient = try {
    val parsed = JsonSlurper().parseText(
        providers.fileContents(layout.file(provider { clientFile })).asText.get().removePrefix("\uFEFF")
    ) as? Map<*, *> ?: error("Invalid object")
    require(parsed.keys.all { it in clientKeys })
    parsed.map { (key, value) ->
        require(if (key == "FACEBOOK_ENABLED") value is Boolean else value is String && value == value.trim())
        key as String to value.toString()
    }.toMap().toMutableMap()
} catch (_: Exception) {
    throw GradleException("Invalid public client configuration. Use config/flutter.example.json keys/types only. Values withheld.")
}
// Retain script/CI support. Explicit Dart settings also configure native SDKs.
val legacyEnvironment = mapOf(
    "TTTP_FACEBOOK_APP_ID" to "TTTP_FACEBOOK_APP_ID",
    "TTTP_FACEBOOK_CLIENT_TOKEN" to "TTTP_FACEBOOK_CLIENT_TOKEN",
    "FIREBASE_API_KEY" to "TTTP_FIREBASE_API_KEY",
    "FIREBASE_APP_ID" to "TTTP_FIREBASE_APP_ID",
    "FIREBASE_MESSAGING_SENDER_ID" to "TTTP_FIREBASE_MESSAGING_SENDER_ID",
    "FIREBASE_PROJECT_ID" to "TTTP_FIREBASE_PROJECT_ID"
)
legacyEnvironment.forEach { (key, env) ->
    providers.environmentVariable(env).orNull?.let { publicClient[key] = it }
}
try {
    providers.gradleProperty("dart-defines").orNull?.split(",")?.filter { it.isNotEmpty() }?.forEach {
        val entry = String(Base64.getDecoder().decode(it), Charsets.UTF_8).split("=", limit = 2)
        if (entry.size == 2 && entry[0] in clientKeys) publicClient[entry[0]] = entry[1]
    }
} catch (_: Exception) {
    throw GradleException("Invalid encoded Dart configuration. Values withheld.")
}
require(publicClient["FACEBOOK_ENABLED"] in listOf(null, "true", "false")) { "FACEBOOK_ENABLED must be boolean." }
val apiUrl = publicClient["API_BASE_URL"].orEmpty()
val apiUri = try { if (apiUrl.isEmpty()) null else URI(apiUrl) } catch (_: Exception) {
    throw GradleException("API_BASE_URL must be an HTTP(S) URL without credentials, query or fragment.")
}
require(apiUri == null || (apiUri.scheme in listOf("http", "https") && apiUri.host != null &&
    apiUri.rawUserInfo == null && apiUri.rawQuery == null && apiUri.rawFragment == null)) {
    "API_BASE_URL must be an HTTP(S) URL without credentials, query or fragment."
}
val firebaseKeys = listOf("FIREBASE_API_KEY", "FIREBASE_APP_ID", "FIREBASE_MESSAGING_SENDER_ID", "FIREBASE_PROJECT_ID")
require(firebaseKeys.none { !publicClient[it].isNullOrEmpty() } || firebaseKeys.all { !publicClient[it].isNullOrEmpty() }) {
    "Provide all four public FIREBASE_* settings."
}
require(publicClient["FACEBOOK_ENABLED"] != "true" ||
    listOf("TTTP_FACEBOOK_APP_ID", "TTTP_FACEBOOK_CLIENT_TOKEN").all { !publicClient[it].isNullOrEmpty() }) {
    "Facebook is enabled but its public Android settings are missing."
}
val clientJson = JsonOutput.toJson(publicClient.mapValues { (key, value) ->
    if (key == "FACEBOOK_ENABLED") value == "true" else value
})

android {
    namespace = "com.example.hotel_booking"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        resValues = true
        buildConfig = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.hotel_booking"
        // Public SDK configuration only. The Meta app secret stays on backend.
        buildConfigField("String", "TETRA_CLIENT_CONFIGURATION", JsonOutput.toJson(clientJson))
        val facebookAppId = publicClient["TTTP_FACEBOOK_APP_ID"].orEmpty()
        resValue("string", "facebook_app_id", facebookAppId)
        resValue("string", "facebook_client_token", publicClient["TTTP_FACEBOOK_CLIENT_TOKEN"].orEmpty())
        resValue("string", "fb_login_protocol_scheme", "fb$facebookAppId")
        // Public Firebase settings also initialize Android's background receiver.
        val firebasePublic = mapOf(
            "google_app_id" to "FIREBASE_APP_ID",
            "google_api_key" to "FIREBASE_API_KEY",
            "gcm_defaultSenderId" to "FIREBASE_MESSAGING_SENDER_ID",
            "project_id" to "FIREBASE_PROJECT_ID"
        ).mapValues { publicClient[it.value].orEmpty() }
        if (firebasePublic.values.any { it.isNotEmpty() }) {
            firebasePublic.forEach { (resource, value) -> resValue("string", resource, value) }
        }
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.biometric:biometric:1.1.0")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Flutter already selects/launches the device. Prepare the API port on authorized
// USB phones for debug builds; emulators use their host alias without forwarding.
val prepareUsbApi by tasks.registering {
    doLast {
        if (apiUri != null && apiUri.host != "127.0.0.1" && apiUri.host != "localhost") return@doLast
        val port = if (apiUri == null) 8000 else if (apiUri.port >= 0) apiUri.port else if (apiUri.scheme == "https") 443 else 80
        val adb = File(android.sdkDirectory, "platform-tools/adb${if (System.getProperty("os.name").startsWith("Windows")) ".exe" else ""}")
        val listing = providers.exec {
            commandLine(adb.absolutePath, "devices")
            isIgnoreExitValue = true
        }
        if (listing.result.get().exitValue != 0) {
            logger.warn("USB API forwarding unavailable. Check Android platform-tools and USB authorization.")
            return@doLast
        }
        listing.standardOutput.asText.get().lineSequence().map { it.trim().split(Regex("\\s+")) }
            .filter { it.size == 2 && it[1] == "device" && !it[0].startsWith("emulator-") && !it[0].contains(":") }
            .forEach { device ->
                val forwarding = providers.exec {
                    commandLine(adb.absolutePath, "-s", device[0], "reverse", "tcp:$port", "tcp:$port")
                    isIgnoreExitValue = true
                }
                if (forwarding.result.get().exitValue != 0) {
                    logger.warn("USB API forwarding failed. Reconnect and authorize the phone, then run again.")
                }
            }
    }
}
tasks.matching { it.name == "compileFlutterBuildDebug" }.configureEach { dependsOn(prepareUsbApi) }
