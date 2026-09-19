#!/usr/bin/env bash
set -e

echo "=== Aligning Project to Gradle 9.7.1 & AGP 9.0.0 ==="

# 1. Configure settings.gradle.kts for AGP 9.0.0 and Kotlin 2.4.0
cat << 'SETTINGS_EOF' > settings.gradle.kts
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("com.android.application") version "9.0.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "LocalAssistant"
include(":app")
SETTINGS_EOF

# 2. Configure app/build.gradle.kts
cat << 'BUILD_EOF' > app/build.gradle.kts
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
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
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
}
BUILD_EOF

echo "Configuration updated for Gradle 9. Building with system Gradle..."
gradle assembleDebug

# 3. Output results
APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
if [ -f "$APK_PATH" ]; then
    echo "=================================================="
    echo " Build Successful!"
    echo " APK generated at: $(pwd)/$APK_PATH"
    echo "=================================================="
else
    echo "Build failed: APK file could not be located."
    exit 1
fi
