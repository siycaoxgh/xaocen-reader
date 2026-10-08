import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningProperties = Properties()
val releaseSigningPropertiesFile = rootProject.file("key.properties")
if (releaseSigningPropertiesFile.isFile) {
    releaseSigningPropertiesFile.inputStream().use { stream ->
        releaseSigningProperties.load(stream)
    }
}

fun releaseSigningValue(propertyName: String, environmentName: String): String? =
    releaseSigningProperties
        .getProperty(propertyName)
        ?.trim()
        ?.takeIf(String::isNotEmpty)
        ?: System.getenv(environmentName)?.trim()?.takeIf(String::isNotEmpty)

val releaseStorePath =
    releaseSigningValue("storeFile", "XAOCEN_ANDROID_KEYSTORE_PATH")
val releaseStorePassword =
    releaseSigningValue("storePassword", "XAOCEN_ANDROID_KEYSTORE_PASSWORD")
val releaseKeyAlias =
    releaseSigningValue("keyAlias", "XAOCEN_ANDROID_KEY_ALIAS")
val releaseKeyPassword =
    releaseSigningValue("keyPassword", "XAOCEN_ANDROID_KEY_PASSWORD")

// Gradle configuration also runs for IDE sync and debug builds. Require the
// production key only when a Release task is actually requested, while never
// allowing a Release artifact to fall back to the debug certificate.
val releaseTaskRequested =
    gradle.startParameter.taskNames.any { taskName ->
        taskName.contains("release", ignoreCase = true)
    }

if (releaseTaskRequested) {
    val missingValues =
        listOf(
            "storeFile / XAOCEN_ANDROID_KEYSTORE_PATH" to releaseStorePath,
            "storePassword / XAOCEN_ANDROID_KEYSTORE_PASSWORD" to releaseStorePassword,
            "keyAlias / XAOCEN_ANDROID_KEY_ALIAS" to releaseKeyAlias,
            "keyPassword / XAOCEN_ANDROID_KEY_PASSWORD" to releaseKeyPassword,
        ).filter { (_, value) -> value == null }.map { (name, _) -> name }

    if (missingValues.isNotEmpty()) {
        throw GradleException(
            "XAOCEN Android Release signing is not configured. Missing: " +
                missingValues.joinToString() +
                ". Copy android/key.properties.example to android/key.properties " +
                "and fill it locally, or set the documented XAOCEN_ANDROID_* environment variables.",
        )
    }

    val releaseStoreFile = rootProject.file(releaseStorePath!!)
    if (!releaseStoreFile.isFile) {
        throw GradleException(
            "XAOCEN Android Release keystore does not exist: ${releaseStoreFile.absolutePath}",
        )
    }
}

android {
    namespace = "com.xaocen.reader"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.xaocen.reader"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            releaseStorePath?.let { storeFile = rootProject.file(it) }
            releaseStorePassword?.let { storePassword = it }
            releaseKeyAlias?.let { keyAlias = it }
            releaseKeyPassword?.let { keyPassword = it }
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
