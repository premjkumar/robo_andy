#!/bin/bash

set -e

PROJECT_DIR="/home/sharon/robo_andy"
BACKUP_DIR="${PROJECT_DIR}/legacy_scripts_backup"

echo "=== Step 1: Backing up legacy com.local scripts ==="
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

echo "=== Step 2: Removing lingering com/local package directories ==="
rm -rf app/src/main/java/com/local

echo "=== Step 3: Stopping Gradle daemons & wiping build caches ==="
./gradlew --stop || true
rm -rf .gradle build app/build

echo "=== Step 4: Verifying source tree for com.local references ==="
REMNANTS=$(grep -rn --exclude-dir={legacy_scripts_backup,.gradle,build,.idea} "com.local" app/src/ 2>/dev/null || true)

if [ -n "$REMNANTS" ]; then
    echo "WARNING: Found remaining com.local references:"
    echo "$REMNANTS"
    echo "Please update these source files to com.example.robo_andy before building."
else
    echo "No com.local references found in app/src/!"
fi

echo "=== Step 5: Building fresh debug APK ==="
./gradlew assembleDebug --no-configuration-cache

echo "=== Step 6: Uninstalling old APK and reinstalling fresh package ==="
adb uninstall com.example.robo_andy || true
adb install -r app/build/outputs/apk/debug/app-debug.apk

echo "=== Step 7: Launching MainActivity ==="
adb shell am start -n com.example.robo_andy/.MainActivity

echo "=== SUCCESS! Application launched. ==="
