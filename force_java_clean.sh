#!/usr/bin/env bash
set -e

echo "=== Forcing Clean Java-Only Build (No Kotlin Engine) ==="

# 1. Disable built-in Kotlin and configure properties
cat << 'PROP_EOF' > gradle.properties
android.useAndroidX=true
android.builtInKotlin=false
PROP_EOF

# 2. Settings configuration
cat << 'SETTINGS_EOF' > settings.gradle.kts
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("com.android.application") version "8.7.0" apply false
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

# 3. Build configuration (Pure Java)
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
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
}
BUILD_EOF

# 4. Ensure SDK path is present
echo "sdk.dir=/home/sharon/Android/Sdk" > local.properties

echo "Running system Gradle build..."
gradle assembleDebug

# 5. Output results
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
