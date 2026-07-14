plugins {
    id("com.android.application")
    id("kotlin-android")
    // Le plugin Flutter doit être appliqué APRÈS Android et Kotlin
    id("dev.flutter.flutter-gradle-plugin")
    // Plugin Google Services (OBLIGATOIRE pour Firebase)
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.reclamation_attijari"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        // ── Core Library Desugaring ──────────────────────────────────────────
        // OBLIGATOIRE pour flutter_local_notifications (utilise des APIs Java 8+
        // qui ne sont pas disponibles nativement sur toutes les versions Android).
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.reclamation_attijari"
        // minSdk 23 requis par firebase_messaging
        minSdk = 23
        // targetSdk 35 requis pour POST_NOTIFICATIONS (Android 13+)
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Multidex est activé automatiquement pour minSdk >= 21,
        // mais on le force pour la compatibilité avec le desugaring.
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // ── Core Library Desugaring (bibliothèque Java 8+ rétrocompatible) ──────
    // Requis explicitement quand isCoreLibraryDesugaringEnabled = true
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
