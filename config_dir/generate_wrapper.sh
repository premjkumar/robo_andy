#!/usr/bin/env bash
set -e

echo "=== Generating Gradle Wrapper for robo_andy ==="

# Make sure gradle is available or install it temporarily via dnf
if ! command -v gradle &> /dev/null; then
    sudo dnf install gradle -y
fi

# Initialize gradle wrapper files in current directory
gradle wrapper --gradle-version 8.5

# Grant execution permissions
chmod +x gradlew

echo "Wrapper generated successfully! Now running build..."
./build_apk.sh
