#!/usr/bin/env bash
set -e

echo "=== Configuring wrapper to use the downloaded Gradle 9.7.1 bundle ==="
mkdir -p gradle/wrapper

cat << 'PROP_EOF' > gradle/wrapper/gradle-wrapper.properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-9.7.1-bin.zip
networkTimeout=60000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
PROP_EOF

echo "=== Running clean build and installing the debug APK ==="
./gradlew clean assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk

echo "=== All set! App is built with Gradle 9.7.1 and installed successfully. ==="
