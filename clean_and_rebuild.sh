#!/usr/bin/env bash
set -e

echo "=== Removing stale Java source files ==="
rm -f app/src/main/java/com/local/assistant/MainActivity.java
rm -f app/src/main/java/com/local/assistant/core/AssistantCore.java

echo "=== Cleaning Gradle build cache ==="
gradle clean

echo "=== Rebuilding project with Kotlin sources ==="
gradle assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
echo "=== Done! Clean build and install complete. ==="
