plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ← tambahkan ini
}

android {
    namespace = "com.example.kasir"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.kasir"
        minSdk = flutter.minSdkVersion  // ← ubah dari flutter.minSdkVersion ke 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Keystore rilis tetap supaya SHA-1 aplikasi selalu sama (lokal & CI).
    // File kasir.jks TIDAK ikut di-commit (lihat android/.gitignore):
    //  - lokal  : buat sekali dengan perintah di README/instruksi
    //  - CI     : di-decode dari secret KEYSTORE_BASE64 oleh workflow
    // Kalau file tidak ada, jatuh kembali ke signing debug bawaan.
    // Daftarkan SHA-1 keystore ini di Firebase Console agar Google Sign-In jalan.
    val releaseKeystore = file("kasir.jks")

    signingConfigs {
        create("release") {
            if (releaseKeystore.exists()) {
                storeFile = releaseKeystore
                storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "kasirku123"
                keyAlias = System.getenv("KEY_ALIAS") ?: "kasirku"
                keyPassword = System.getenv("KEY_PASSWORD") ?: "kasirku123"
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (releaseKeystore.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
