#!/usr/bin/env bash
set -e

echo "=== Updating AndroidManifest.xml to use a built-in fallback icon ==="

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
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

    </application>

</manifest>
XML_EOF

echo "=== Cleaning and building successfully ==="
gradle clean
gradle assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
echo "=== Done! App compiled, installed, and ready to run. ==="
