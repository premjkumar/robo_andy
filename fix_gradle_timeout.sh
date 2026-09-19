#!/usr/bin/env bash
set -e

echo "=== Adjusting Gradle Wrapper properties with a higher network timeout ==="

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

echo "=== Re-running build with expanded timeout ==="
./gradlew clean
./gradlew assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk

echo "=== Done! Successfully built and installed. ==="
