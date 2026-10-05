# robo_andy 🤖

`robo_andy` is a lightweight, local-first, zero-cost personal assistant built for Android, running entirely offline using Google AI Edge (MediaPipe GenAI). Developed natively on Fedora via CLI tools (Gradle, OpenJDK 21, and the Android SDK), it bypasses Android Studio completely to ensure high performance and absolute control over the toolchain.

---

## Features

* **100% Local & Offline:** Powered by on-device models with zero cloud dependencies or recurring API costs.
* **Continuous Voice Interaction:** Features hands-free speech recognition (`SpeechRecognizer`) and offline text-to-speech feedback.
* **Device Tool Routing:** Modular architecture designed to process offline user intent queries and interface with device hardware (including camera and audio permissions).
* **Lightweight CLI Toolchain:** Built, managed, and deployed strictly through Gradle and `adb` on Linux.

---

## Project Structure

```text
robo_andy/
├── app/
│   ├── src/
│   │   └── main/
│   │       ├── java/com/example/robo_andy/
│   │       │   ├── MainActivity.kt        # UI, continuous listening, permissions, & TTS
│   │       │   └── core/
│   │       │       └── AssistantCore.kt   # Offline response handling & intent routing
│   │       ├── res/                       # Layouts and application resources
│   │       └── AndroidManifest.xml        # Manifest definitions and permissions
│   │   build.gradle                       # App-level build configuration
│   └── build.gradle                       # Project-level build configuration
├── gradle/
│   └── wrapper/
│       └── gradle-wrapper.properties      # Local Gradle wrapper distribution mapping
├── gradlew                                # Gradle build script
└── local.properties                       # Android SDK path configuration
Prerequisites & Setup
Ensure you have the following installed on your Fedora environment:
    OpenJDK 21
    Android SDK (configured in local.properties)
    Gradle Wrapper / Bundle (bundled locally via gradle-9.7.1-bin.zip)
Configuration
Verify that your local.properties file points correctly to your Android SDK path:
Properties
sdk.dir=/home/sharon/Android/Sdk
Building and Deploying
Connect your Android device via USB with USB debugging enabled, then use the following commands from the project root:
1. Clean Build (Debug APK)
Bash
./gradlew clean assembleDebug
2. Install on Connected Device
Bash
adb install -r app/build/outputs/apk/debug/app-debug.apk
3. Monitor Live Logs & Debugging
To inspect real-time runtime events, component triggers, or stack traces:
Bash
adb logcat -c && adb logcat | grep -E "AndroidRuntime|FATAL|MainActivity|AssistantCore"
License
This project is licensed under the MIT License - feel free to adapt it for your own local assistant workflows.
***
# Robo Andy (`robo_andy`)  ( moved to direct download of AI model)

`robo_andy` is an offline Android assistant application built with Kotlin. It leverages local on-device AI inference using MediaPipe GenAI (`LlmInference`) along with native Android Speech-to-Text, Text-to-Speech, and Camera integrations.

---

## Features

* **Local On-Device AI:** Downloads and executes the TinyLlama LLM locally using MediaPipe / LiteRT-LM, ensuring privacy and offline capabilities.
* **Speech-to-Text (STT):** Uses Android's built-in `SpeechRecognizer` to capture voice commands.
* **Text-to-Speech (TTS):** Speaks out AI responses and status updates using `TextToSpeech`.
* **Vision Integration:** Captures camera preview snapshots.
* **Robust Model Handling:** Automatically downloads the `.task` model file into internal app storage on first launch with real-time download progress tracking.

---

## Tech Stack & Architecture

* **Language:** Kotlin
* **UI:** Android Views (XML layouts with `MainActivity`)
* **Concurrency:** Kotlin Coroutines (`Dispatchers.IO`, `lifecycleScope`)
* **AI Engine:** MediaPipe Tasks GenAI (`com.google.mediapipe:tasks-genai`)
* **Networking:** OkHttp (for downloading model weights from Hugging Face)

---

## Project Structure

* `app/src/main/java/com/example/robo_andy/MainActivity.kt` — Manages UI interactions, permissions, STT/TTS loops, and camera execution.
* `app/src/main/java/com/example/robo_andy/ModelRepository.kt` — Handles asynchronous model downloading, internal storage caching, and local `LlmInference` execution.
* `app/src/main/AndroidManifest.xml` — Declares necessary permissions (`INTERNET`, `RECORD_AUDIO`, `CAMERA`).
* `app/build.gradle` — Groovy build script configuring SDK targets and NDK ABI filters.

---

## Prerequisites & Setup

1. **Android Studio** (Koala or newer recommended).
2. **Android SDK Platform 34** / Minimum SDK 26 (Android 8.0+).
3. **Physical Device or Emulator:**
   * A 64-bit device or emulator (`arm64-v8a`) is strongly recommended for running on-device LLMs smoothly.

---

## Configuration & Permissions

### 1. AndroidManifest.xml
Ensure your manifest includes the required permissions for internet access (to download the model file), microphone, and camera:

```xml
<manifest xmlns:android="[http://schemas.android.com/apk/res/android](http://schemas.android.com/apk/res/android)">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.CAMERA" />

    <application
        ... >
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