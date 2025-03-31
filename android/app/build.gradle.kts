plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.lets_do_it"
    compileSdk = 35  // Use the latest stable version
    ndkVersion = "27.0.12077973"  // Explicitly specify if needed

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17  // Recommended Java version
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.lets_do_it"
        minSdk = 21  // Minimum supported version
        targetSdk = 34  // Should match compileSdk
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
