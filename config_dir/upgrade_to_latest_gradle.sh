#!/usr/bin/env bash
set -e

echo "=== Upgrading Gradle Wrapper to latest stable (9.7.1) ==="

mkdir -p gradle/wrapper

cat << 'PROP_EOF' > gradle/wrapper/gradle-wrapper.properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-9.7.1-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
PROP_EOF

echo "=== Running build with Gradle 9.7.1 ==="
./gradlew clean
./gradlew assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk

echo "=== Success! Running smoothly on the latest Gradle release. ==="
