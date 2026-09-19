#!/usr/bin/env bash
set -e

echo "=== Updating for AGP 9.0 Built-in Kotlin Support ==="

# 1. Update settings.gradle.kts (Android plugin 9.0.0 only)
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

# 2. Update app/build.gradle.kts (Remove external kotlin plugin)
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

echo "Configuration updated! Running system Gradle build..."
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
