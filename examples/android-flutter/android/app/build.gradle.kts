import java.util.Properties
import java.io.FileInputStream
import java.util.Base64

dependencies {
  implementation("androidx.browser:browser:1.8.+")
  implementation("com.google.androidbrowserhelper:androidbrowserhelper:2.4.+")
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

var dartEnvironmentVariables = emptyMap<String, String>()
if (project.hasProperty("dart-defines")) {
    val prop = project.property("dart-defines") as String
    dartEnvironmentVariables = prop.split(",").associate {
        val (left, right) = String(Base64.getDecoder().decode(it)).split("=")
        left to right.toString()
    }
}

android {
    namespace = "fi.mainiotech.decidimparticipanttoken"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "fi.mainiotech.decidimparticipanttoken"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["OAUTH_HOST"] = dartEnvironmentVariables["OAUTH_HOST"] as String
    }

    signingConfigs {
        create("local") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            // Signing with the local keys for demonstrating the trusted web activity intent.
            // Use `flutter run --release` to run the application.
            signingConfig = signingConfigs.getByName("local")
        }
    }
}

flutter {
    source = "../.."
}
