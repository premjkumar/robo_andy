#!/usr/bin/env bash
set -e

echo "=== Updating app/build.gradle with Java 17 & No-Compress Rules ==="

cat << 'GRADLE_EOF' > app/build.gradle
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.local.assistant'
    compileSdk 34

    defaultConfig {
        applicationId "com.local.assistant"
        minSdk 26
        targetSdk 34
        versionCode 1
        versionName "1.0"

        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    // Prevent packaging task from failing on large native binaries and model files
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    aaptOptions {
        noCompress "task", "so"
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'com.squareup.okhttp3:okhttp:4.11.0'
    implementation 'com.google.mediapipe:tasks-genai:0.10.35'
}
GRADLE_EOF

echo "Running clean build..."
gradle clean assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk

echo "=== Success! APK packaged and installed cleanly. ==="
