plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

val requiresReleaseKeystore = gradle.startParameter.taskNames.any { taskName ->
    taskName.contains("Release", ignoreCase = true)
}
if (requiresReleaseKeystore && !keystorePropertiesFile.exists()) {
    throw GradleException(
        "Missing android/key.properties for release build. " +
            "Create it from android/key.properties.example."
    )
}

android {
    namespace = "app.akirabizhub.pos"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "app.akirabizhub.pos"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// #region agent log
try {
    file("/home/eng-susan/Desktop/Software Projects/M-Apps/bizhub/.cursor/debug-910678.log")
        .appendText(
            """{"sessionId":"910678","hypothesisId":"B","runId":"agp9-upgrade","location":"android/app/build.gradle.kts","message":"resolved gradle version","data":{"gradleVersion":"${gradle.gradleVersion}"},"timestamp":${System.currentTimeMillis()}}""" +
                "\n",
        )
} catch (_: Exception) {
}
// #endregion

