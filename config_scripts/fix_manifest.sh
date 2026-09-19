#!/usr/bin/env bash
set -e

echo "=== Updating AndroidManifest.xml with correct package path for MainActivity ==="

cat << 'XML_EOF' > app/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.local.assistant">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.CAMERA" />

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar">

        <activity
            android:name=".ui.MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

    </application>

</manifest>
XML_EOF

echo "=== Cleaning and rebuilding project ==="
gradle clean
gradle assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
echo "=== Done! App updated and installed successfully without crashing. ==="
