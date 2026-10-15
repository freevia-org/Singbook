import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing. Create android/key.properties (git-ignored) with:
//   storeFile=/absolute/or/app-relative/path/to/upload-keystore.jks
//   storePassword=...
//   keyAlias=...
//   keyPassword=...
// Without it, a release build falls back to the DEBUG key for local preview
// builds only (with a warning). Pass -PrequireReleaseSigning=true (or set
// ORG_GRADLE_PROJECT_requireReleaseSigning=true, which `scripts/build-android.ps1
// -Production` does) to make a release build FAIL instead of using the debug key.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}
val hasReleaseKey =
    listOf("storeFile", "storePassword", "keyAlias", "keyPassword").all {
        !keystoreProperties.getProperty(it).isNullOrBlank()
    }
val requireReleaseSigning =
    (findProperty("requireReleaseSigning") as String?)?.toBoolean() == true
// Safety valve for R8 (-PminifyRelease=false) if shrinking ever breaks a plugin.
val minifyRelease = (findProperty("minifyRelease") as String?)?.toBoolean() != false
val releaseRequested =
    gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }

android {
    namespace = "org.freevia.verse"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "org.freevia.verse"
        minSdk = flutter.minSdkVersion
        // Play requires new apps/updates to target API 36 (Android 16) from
        // 2026-08-31. flutter.targetSdkVersion is 36 in Flutter 3.44; the
        // explicit floor keeps a future Flutter downgrade from lowering it.
        targetSdk = maxOf(flutter.targetSdkVersion, 36)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    // Only the app's own languages are packaged, so the Play listing shows
    // exactly en/bg/uk (see res/xml/locales_config.xml).
    androidResources {
        localeFilters += listOf("en", "bg", "uk")
    }

    // Android App Bundle: keep language, density and ABI splits enabled so
    // Play delivers per-device APKs.
    bundle {
        language { enableSplit = true }
        density { enableSplit = true }
        abi { enableSplit = true }
    }

    packaging {
        jniLibs {
            // Native libraries stay uncompressed and page-aligned in the APK
            // (required for 16 KB page-size devices; AGP aligns to 16 KB).
            useLegacyPackaging = false
        }
    }

    buildTypes {
        release {
            // Native debug symbols for Play Console crash/ANR symbolication
            // (embedded in the .aab and zipped under
            // build/app/outputs/native-debug-symbols/release/).
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
            if (hasReleaseKey) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                if (requireReleaseSigning && releaseRequested) {
                    throw GradleException(
                        "Release signing is required (-PrequireReleaseSigning=true) but " +
                            "android/key.properties is missing or incomplete. Refusing to " +
                            "sign a release with the debug key."
                    )
                }
                if (releaseRequested) {
                    logger.warn(
                        "WARNING: android/key.properties not found; signing the release " +
                            "build with the DEBUG key. This is for local preview builds only " +
                            "and must never be distributed."
                    )
                }
                signingConfig = signingConfigs.getByName("debug")
            }
            isMinifyEnabled = minifyRelease
            isShrinkResources = minifyRelease
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
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
