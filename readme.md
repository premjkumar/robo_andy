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
│   │       ├── java/com/local/assistant/
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

If you'd like to create the file directly from your Fedora terminal in one go, you can run this quick command:

```bash
cat << 'EOF' > README.md
# robo_andy 🤖
... (paste contents here) ...
EOF