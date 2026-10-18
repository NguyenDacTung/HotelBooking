plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

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
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.hotel_booking"
        // Public SDK configuration only. The Meta app secret stays on backend.
        val facebookAppId = providers.environmentVariable("TTTP_FACEBOOK_APP_ID").orElse("").get()
        resValue("string", "facebook_app_id", facebookAppId)
        resValue("string", "facebook_client_token", providers.environmentVariable("TTTP_FACEBOOK_CLIENT_TOKEN").orElse("").get())
        resValue("string", "fb_login_protocol_scheme", "fb$facebookAppId")
        // Public Firebase settings also initialize Android's background receiver.
        val firebasePublic = mapOf(
            "google_app_id" to "TTTP_FIREBASE_APP_ID",
            "google_api_key" to "TTTP_FIREBASE_API_KEY",
            "gcm_defaultSenderId" to "TTTP_FIREBASE_MESSAGING_SENDER_ID",
            "project_id" to "TTTP_FIREBASE_PROJECT_ID"
        ).mapValues { providers.environmentVariable(it.value).orElse("").get() }
        if (firebasePublic.values.any { it.isNotEmpty() }) {
            require(firebasePublic.values.all { it.isNotEmpty() }) { "Provide all four TTTP_FIREBASE public settings." }
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
