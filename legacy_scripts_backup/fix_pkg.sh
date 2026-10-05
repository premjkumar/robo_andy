#!/bin/bash
set -e
NEW_PATH="com/example/robo_andy"

echo "==> Re-creating correct directory structure..."
mkdir -p "app/src/main/java/$NEW_PATH"

echo "==> Moving any misplaced Kotlin files into the correct directory..."
find app/src/main/java -name "*.kt" ! -path "app/src/main/java/com/example/robo_andy/*" -exec mv {} "app/src/main/java/$NEW_PATH/" \;

echo "==> Updating all package statements to com.example.robo_andy..."
find "app/src/main/java" -name "*.kt" -exec sed -i 's/package .*/package com.example.robo_andy/g' {} +

echo "==> Cleaning up old directory trees if empty..."
rm -rf app/src/main/java/com/local 2>/dev/null || true
rm -rf app/src/main/java/com/example/assistant 2>/dev/null || true

echo "==> Package fix complete!"
