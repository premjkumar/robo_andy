#!/bin/bash

set -e

PROJECT_DIR="/home/sharon/robo_andy"
cd "$PROJECT_DIR"

echo "===================================================="
echo " STEP 1: Backing up legacy com.local scripts"
echo "===================================================="
BACKUP_DIR="${PROJECT_DIR}/legacy_scripts_backup"
mkdir -p "$BACKUP_DIR"

LEGACY_FILES=(
    "force_java_clean.sh"
    "update_single_file_core.sh"
    "make_interactive.sh"
    "update_complete_assistant.sh"
    "migrate_to_kotlin.sh"
    "clean_and_rebuild.sh"
    "fix_pkg.sh"
)

for file in "${LEGACY_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Moving $file -> $BACKUP_DIR/"
        mv "$file" "$BACKUP_DIR/"
    fi
done

echo "Removing lingering com/local source directories..."
rm -rf app/src/main/java/com/local

echo "===================================================="
echo " STEP 2: Hard wiping Gradle and transform caches"
echo "===================================================="
./gradlew --stop || true
rm -rf .gradle build app/build
rm -rf ~/.gradle/caches/transforms-* ~/.gradle/caches/modules-*/files-* ~/.gradle/caches/9.7.1/transforms/ || true

echo "===================================================="
echo " STEP 3: Building fresh debug APK (No Cache)"
echo "===================================================="
./gradlew clean assembleDebug --no-build-cache --no-configuration-cache

APK_PATH="app/build/outputs/apk/debug/app-debug.apk"

if [ ! -f "$APK_PATH" ]; then
    echo "ERROR: APK was not generated at $APK_PATH!"
    exit 1
fi

echo "===================================================="
echo " STEP 4: Inspecting APK Manifest & Package Mapping"
echo "===================================================="
# Find aapt path automatically
AAPT_TOOL=$(find ${ANDROID_HOME:-$HOME/Android/Sdk}/build-tools -name "aapt" | sort -V | tail -n 1)

if [ -x "$AAPT_TOOL" ]; then
    echo "Using aapt found at: $AAPT_TOOL"
    "$AAPT_TOOL" dump badging "$APK_PATH" | grep -E "package:|launchable-activity"
else
    echo "WARNING: aapt tool not found automatically, skipping manifest dump."
fi

echo "===================================================="
echo " STEP 5: Device Reinstall & Launch"
echo "===================================================="
echo "Uninstalling old package..."
adb uninstall com.example.robo_andy || true

echo "Installing fresh APK..."
adb install -r "$APK_PATH"

echo "Launching MainActivity explicitly..."
adb shell am start -n com.example.robo_andy/.MainActivity

echo "===================================================="
echo " SUCCESS: Build and deployment complete!"
echo "===================================================="
