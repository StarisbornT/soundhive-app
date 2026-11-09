import java.io.FileInputStream
import java.util.Properties

// Load key.properties for secure production signing
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.webedge.cre8hive"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.webedge.cre8hive"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    packaging {
        jniLibs {
            // Agora is only used for VOICE calls (call_provider.dart). These
            // optional extension libraries are for video, face/body effects
            // and screen sharing, and are loaded only if those features are
            // switched on — dropping them saves several MB per ABI.
            // If video calls are added later, delete the video_* lines.
            excludes += listOf(
                "lib/*/libagora_clear_vision_extension.so",
                "lib/*/libagora_content_inspect_extension.so",
                "lib/*/libagora_face_capture_extension.so",
                "lib/*/libagora_face_detection_extension.so",
                "lib/*/libagora_lip_sync_extension.so",
                "lib/*/libagora_screen_capture_extension.so",
                "lib/*/libagora_segmentation_extension.so",
                "lib/*/libagora_video_av1_decoder_extension.so",
                "lib/*/libagora_video_av1_encoder_extension.so",
                "lib/*/libagora_video_decoder_extension.so",
                "lib/*/libagora_video_encoder_extension.so",
                "lib/*/libagora_video_quality_analyzer_extension.so",
            )
        }
    }

    buildTypes {
        release {
            // R8: strips unused Java/Kotlin code and resources from plugins.
            // Rules for plugins that use reflection are in proguard-rules.pro.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // Replaced "debug" configuration with your official production signing configuration
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))
    implementation("com.google.firebase:firebase-analytics")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}