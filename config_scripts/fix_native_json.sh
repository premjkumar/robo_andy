#!/usr/bin/env bash
set -e

echo "=== Updating build.gradle.kts (Removing external json dependency) ==="

cat << 'BUILD_EOF' > app/build.gradle.kts
plugins {
    id("com.android.application")
}

android {
    namespace = "com.local.assistant"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.local.assistant"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    
    // OkHttp for internet access and tool queries
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
}
BUILD_EOF

echo "Running clean build..."
gradle clean assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk

echo "=== Build Successful! Robo Andy is ready with internet access and native core functionality. ==="
