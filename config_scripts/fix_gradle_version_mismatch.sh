#!/usr/bin/env bash
set -e

echo "=== Fixing Gradle & Plugin Version Compatibility ==="

# 1. Downgrade/Pin Gradle wrapper version to 8.5 (fully compatible with AGP 8.2.0 & Kotlin 1.9.24)
gradle wrapper --gradle-version 8.5

# 2. Update settings.gradle.kts with matching plugin versions
cat << 'SETTINGS_EOF' > settings.gradle.kts
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("com.android.application") version "8.2.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "LocalAssistant"
include(":app")
SETTINGS_EOF

chmod +x gradlew
echo "Configuration fixed! Rerun build now..."
./build_apk.sh
