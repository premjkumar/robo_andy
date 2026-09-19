#!/usr/bin/env bash

# Exit immediately if any command fails
set -e

echo "=== Starting Android Build Process on Fedora 44 ==="

# 1. Locate or Export Android SDK Path (Adjust if your SDK is located elsewhere)
if [ -z "$ANDROID_HOME" ]; then
    export ANDROID_HOME="$HOME/Android/Sdk"
fi

if [ ! -d "$ANDROID_HOME" ]; then
    echo "Error: Android SDK not found at $ANDROID_HOME."
    echo "Please install Android Studio / SDK tools or update the ANDROID_HOME path in this script."
    exit 1
fi

echo "Using Android SDK at: $ANDROID_HOME"

# 2. Check for Java 17 or 21 (Required for modern Android Gradle builds)
if ! java -version 2>&1 | grep -E "(17|21)" > /dev/null; then
    echo "Warning: Java 17 or 21 is recommended. Current Java version:"
    java -version
fi

# 3. Ensure the Gradle wrapper has execution permissions
if [ -f "./gradlew" ]; then
    chmod +x ./gradlew
else
    echo "Error: 'gradlew' not found in the current directory. Are you in the project root?"
    exit 1
fi

# 4. Clean previous builds and compile the APK
echo "Cleaning old build files..."
./gradlew clean

echo "Compiling and building Debug APK..."
./gradlew assembleDebug

# 5. Output results
APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
if [ -f "$APK_PATH" ]; then
    echo "=================================================="
    echo " Build Successful!"
    echo " APK generated at: $(pwd)/$APK_PATH"
    echo "=================================================="
    
    # Optional: Automatically push and install to connected phone if ADB is available
    if command -v adb &> /dev/null; then
        if adb devices | grep -w "device" > /dev/null; then
            echo "Connected Android device detected. Installing APK..."
            adb install -r "$APK_PATH"
            echo "Installation complete!"
        else
            echo "No active ADB device detected. Transfer the APK manually to your phone to run it."
        fi
    fi
else
    echo "Build failed: APK file could not be located."
    exit 1
fi
