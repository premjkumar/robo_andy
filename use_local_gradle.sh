#!/usr/bin/env bash
set -e

ZIP_PATH="$(pwd)/gradle-9.7.1-bin.zip"

echo "=== Configuring wrapper to use local archive: $ZIP_PATH ==="
mkdir -p gradle/wrapper

cat << PROP_EOF > gradle/wrapper/gradle-wrapper.properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=file\://$ZIP_PATH
networkTimeout=60000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
PROP_EOF

echo "=== Running clean build with local Gradle 9.7.1 bundle ==="
./gradlew clean assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk

echo "=== Success! App successfully built using the local distribution and installed. ==="
