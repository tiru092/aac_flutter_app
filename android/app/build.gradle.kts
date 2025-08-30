plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Add Google Services plugin for Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.aacpp.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = System.getenv("KEY_ALIAS") ?: "svarah"
            keyPassword = System.getenv("KEY_PASSWORD") ?: ""
            storeFile = file("keystore/svarah.keystore")
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
    applicationId = "com.svarah.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
    versionCode = 2
    versionName = "1.1.0"
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false  // Disable for now due to R8 issues
            isShrinkResources = false
        }
        getByName("debug") {
            // Configure the existing 'debug' buildType. We removed the applicationIdSuffix
            // to match the existing firebase/google-services configuration while you
            // have uninstalled the release app from the device.
            isDebuggable = true
        }
    }
}

flutter {
    source = "../.."
}
