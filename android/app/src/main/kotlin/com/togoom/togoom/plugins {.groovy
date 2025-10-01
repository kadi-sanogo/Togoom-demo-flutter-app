plugins {
    id("com.android.application")
    id("kotlin-android")
    // Le plugin Flutter doit être appliqué après Android et Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.togoom.togoom"
    compileSdk = 36  // Remis à 36 pour compatibilité avec camera_android
    ndkVersion = "27.0.12077973"
    
    defaultConfig {
        applicationId = "com.togoom.togoom"
        minSdk = 24
        targetSdk = 36  // Remis à 36 pour compatibilité avec les plugins
        multiDexEnabled = true
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false   // Désactive la minification
            isShrinkResources = false     // Désactive le shrinkResources
        }
    }
    
    // Configuration simplifiée pour les nouvelles versions ML Kit
      /* configurations.all {
        resolutionStrategy {
            force("androidx.core:core:1.12.0")
            force("androidx.appcompat:appcompat:1.6.1")
            force("com.google.android.material:material:1.10.0")
        }
    }*/ 
}

dependencies {
    // Dépendances Android avec versions spécifiques pour éviter le conflit lStar
   /* implementation("androidx.core:core:1.9.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.9.0")
    implementation("androidx.fragment:fragment:1.6.1")
    implementation("androidx.activity:activity:1.7.2")
    implementation("androidx.multidex:multidex:2.0.1") */
}

flutter {
    source = "../.."
}