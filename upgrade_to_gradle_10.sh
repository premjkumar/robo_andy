#!/usr/bin/env bash
set -e

echo "=== Upgrading Gradle Wrapper to version 10.0 ==="

# Ensure gradle/wrapper directory exists
mkdir -p gradle/wrapper

# Update gradle-wrapper.properties to use Gradle 10
cat << 'PROP_EOF' > gradle/wrapper/gradle-wrapper.properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-10.0-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
PROP_EOF

echo "=== Running build with Gradle 10 ==="
./gradlew clean
./gradlew assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk

echo "=== Success! Running smoothly on Gradle 10. ==="
