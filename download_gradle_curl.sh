#!/usr/bin/env bash
set -e

echo "=== Downloading Gradle 9.7.1 distribution via curl ==="
curl -L -o gradle-9.7.1-bin.zip https://services.gradle.org/distributions/gradle-9.7.1-bin.zip

echo "=== Configuring wrapper properties to use local distribution or exact URL ==="
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

echo "=== Running build with Gradle 9.7.1 ==="
./gradlew clean assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk

echo "=== Success! App built and installed successfully. ==="
