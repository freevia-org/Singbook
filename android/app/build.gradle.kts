import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

dependencies {
    // Used by the Google Drive mobile Picker authorization flow. The user
    // explicitly grants one visible folder with the narrow drive.file scope.
    implementation("com.google.android.gms:play-services-auth:21.6.0")
}

// Opt-in workaround for deterministic fixture E2E builds under AGP 9.
// Ordinary debug builds use embedded Cronet for real providers and must keep
// its cronet-shared runtime dependency.
val fixtureE2e = providers.gradleProperty("singbookFixtureE2e").orNull == "true"
configurations.configureEach {
    if (fixtureE2e && name.contains("Debug", ignoreCase = true)) {
        exclude(group = "org.chromium.net", module = "cronet-shared")
    }
}

// Release signing. Create android/key.properties (git-ignored) with:
//   storeFile=/absolute/or/app-relative/path/to/upload-keystore.jks
//   storePassword=...
//   keyAlias=...
//   keyPassword=...
// Without it, a release build FAILS: it never silently uses the DEBUG key.
// For a local preview APK only, pass -PallowDebugSigning=true (or set
// ORG_GRADLE_PROJECT_allowDebugSigning=true, which the non-production
// `scripts/build-android.ps1` does after a warning). -PrequireReleaseSigning=true
// (set by `-Production`) overrides allowDebugSigning and always demands the key.
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
val allowDebugSigning =
    (findProperty("allowDebugSigning") as String?)?.toBoolean() == true
// Safety valve for R8 (-PminifyRelease=false) if shrinking ever breaks a plugin.
val minifyRelease = (findProperty("minifyRelease") as String?)?.toBoolean() != false
val releaseRequested =
    gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }

android {
    namespace = "org.freevia.singbook"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "org.freevia.singbook"
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

    // Only the app's own languages (one per lib/l10n/app_*.arb catalog) are
    // packaged. Keep this list and res/xml/locales_config.xml in sync with the
    // ARB files; test/ui/l10n_test.dart-style checks or a review should catch drift.
    androidResources {
        localeFilters += listOf(
            "ar", "bg", "cs", "da", "de", "el", "en", "es", "et", "fi", "fr",
            "ga", "hi", "hr", "hu", "id", "it", "ja", "ko", "lt", "lv", "mt",
            "nl", "pl", "pt", "ro", "ru", "sk", "sl", "sv", "tr", "uk", "vi", "zh",
        )
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
                if (releaseRequested && (requireReleaseSigning || !allowDebugSigning)) {
                    throw GradleException(
                        "android/key.properties is missing or incomplete, so the release " +
                            "build cannot be signed. Refusing to sign a release with the " +
                            "debug key. Create the file (see README, Release signing); for a " +
                            "local preview APK only, pass -PallowDebugSigning=true."
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
