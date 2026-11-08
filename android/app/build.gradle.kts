import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The maintainer's copy lives outside the repo; CI and contributors keep using
// android/key.properties.
val keyPropertiesFile = File(System.getProperty("user.home"), ".config/lubelogger/key.properties")
    .takeIf { it.exists() } ?: rootProject.file("key.properties")
val keyProperties = Properties().apply {
    if (keyPropertiesFile.exists()) load(keyPropertiesFile.inputStream())
}
// Without key.properties, the "release" signingConfig below would be left with
// all-null fields, and Gradle fails the release build with a cryptic
// "keystore file not set" error. Fall back to the debug key instead, with a
// clear warning — a contributor building locally still gets a working APK,
// just not one suitable for distribution.
val hasReleaseKeystore = keyPropertiesFile.exists()
if (!hasReleaseKeystore) {
    logger.warn(
        "key.properties not found — release build will be signed with the " +
            "debug key, not the real release keystore. Not suitable for distribution."
    )
}

android {
    namespace = "page.codeberg.doyouhost.lubelogger_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications relies on core library desugaring.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keyProperties["keyAlias"] as String?
                keyPassword = keyProperties["keyPassword"] as String?
                storeFile = keyProperties["storeFile"]?.let { file(it) }
                storePassword = keyProperties["storePassword"] as String?
            }
        }
    }

    defaultConfig {
        applicationId = "page.codeberg.doyouhost.lubelogger_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (hasReleaseKeystore) "release" else "debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required by flutter_local_notifications when core library desugaring is on.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
