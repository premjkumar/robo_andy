#!/usr/bin/env bash
set -e

echo "=== Updating AndroidManifest.xml with Fully Qualified Activity Name ==="

cat << 'XML_EOF' > app/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.CAMERA" />

    <application
        android:allowBackup="true"
        android:icon="@android:drawable/ic_menu_compass"
        android:label="@string/app_name"
        android:roundIcon="@android:drawable/ic_menu_compass"
        android:supportsRtl="true"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar">

        <activity
            android:name="com.local.assistant.MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

    </application>

</manifest>
XML_EOF

echo "=== Cleaning and Rebuilding APK ==="
./gradlew clean assembleDebug

echo "=== Reinstalling on Device ==="
adb uninstall com.local.assistant || true
adb install app/build/outputs/apk/debug/app-debug.apk

echo "=== Done! Launch the app to verify. ==="
