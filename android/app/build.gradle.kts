plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.tripplanner.trip_planner_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    // ensure any transitive dependency of desugar_jdk_libs is upgraded
    configurations.all {
        resolutionStrategy {
            force("com.android.tools:desugar_jdk_libs:2.1.4")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Kotlin DSL uses "is" prefix for boolean flags
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        // setting jvmTarget directly; warning is fine
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.tripplanner.trip_planner_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// add desugaring dependency support

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}


flutter {
    source = "../.."
}
