pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

// #region agent log
try {
    val wrapper = java.util.Properties()
    file("gradle/wrapper/gradle-wrapper.properties").inputStream().use { wrapper.load(it) }
    java.io.File("/home/eng-susan/Desktop/Software Projects/M-Apps/bizhub/.cursor/debug-910678.log")
        .appendText(
            """{"sessionId":"910678","hypothesisId":"A","runId":"agp9-upgrade","location":"android/settings.gradle.kts","message":"wrapper and plugin versions","data":{"hasDistributionUrl":${wrapper.getProperty("distributionUrl") != null},"distributionUrl":"${wrapper.getProperty("distributionUrl")}","agp":"9.1.0","kgp":"2.4.0"},"timestamp":${System.currentTimeMillis()}}""" +
                "\n",
        )
} catch (e: Exception) {
    java.io.File("/home/eng-susan/Desktop/Software Projects/M-Apps/bizhub/.cursor/debug-910678.log")
        .appendText(
            """{"sessionId":"910678","hypothesisId":"A","location":"android/settings.gradle.kts","message":"wrapper properties failed","data":{"error":"${e.message}"},"timestamp":${System.currentTimeMillis()}}""" +
                "\n",
        )
}
// #endregion

include(":app")
