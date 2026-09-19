#!/usr/bin/env bash
set -e

echo "=== Ensuring Gradle is Installed ==="
if ! command -v gradle &> /dev/null; then
    sudo dnf install gradle -y
fi

echo "=== Generating Gradle Wrapper Files ==="
gradle wrapper --gradle-version 8.5

echo "=== Granting Execution Permissions ==="
chmod +x gradlew

echo "=== Running APK Build ==="
./build_apk.sh
