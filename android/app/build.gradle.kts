plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.scamto_app"
    compileSdk = 36 

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        // Volvemos a la sintaxis clásica que tu versión de Kotlin sí entiende
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.scamto_app"
        
        // Mínimo para ML Kit y reconocimiento facial
        minSdk = flutter.minSdkVersion 
        multiDexEnabled = true
        
        targetSdk = 34
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.mlkit:face-detection:16.1.6")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
