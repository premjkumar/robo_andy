#!/usr/bin/env bash
set -e

echo "=== Fixing Directory Structure and MainActivity ==="

# 1. Ensure exact package directory path exists
mkdir -p app/src/main/java/com/local/assistant

# 2. Write MainActivity.java correctly
cat << 'JAVA_EOF' > app/src/main/java/com/local/assistant/MainActivity.java
package com.local.assistant;

import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
    }
}
JAVA_EOF

echo "Cleaning previous build outputs..."
gradle clean

echo "Building fresh APK..."
gradle assembleDebug

echo "Reinstalling on device..."
adb install -r app/build/outputs/apk/debug/app-debug.apk

echo "=== Done! Open 'Local Assistant' on your phone now. ==="
