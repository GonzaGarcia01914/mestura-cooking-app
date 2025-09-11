plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // aplicado sin versión (ya está en settings)
}

android {
    namespace = "com.example.app_cocina"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Necesario para usar APIs del JDK en dispositivos antiguos
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.gonzalogarcia.mestura"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val ksPath = System.getenv("ANDROID_KEYSTORE")
            val ksPass = System.getenv("ANDROID_KEYSTORE_PASSWORD")
            val keyAl = System.getenv("ANDROID_KEY_ALIAS")
            val keyPass = System.getenv("ANDROID_KEY_ALIAS_PASSWORD")

            if (!ksPath.isNullOrBlank() && !ksPass.isNullOrBlank() && !keyAl.isNullOrBlank() && !keyPass.isNullOrBlank()) {
                storeFile = file(ksPath)
                storePassword = ksPass
                keyAlias = keyAl
                keyPassword = keyPass
            } else {
                // Variables de entorno faltantes. Permitimos compilar debug;
                // la compilación release fallará si no se configuran.
                // println("[Gradle] Faltan variables de entorno para firma release")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Soporte de desugaring para java.time y otras APIs del JDK
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

