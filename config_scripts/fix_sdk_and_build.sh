#!/usr/bin/env bash
set -e

echo "=== Configuring Android SDK Location for System Gradle ==="

# 1. Automatically write local.properties with your SDK path
echo "sdk.dir=/home/sharon/Android/Sdk" > local.properties

# 2. Also export ANDROID_HOME just in case
export ANDROID_HOME="/home/sharon/Android/Sdk"

echo "local.properties created successfully. Running build..."
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
