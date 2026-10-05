#!/bin/bash
set -e

echo "===================================================="
echo " STEP 1: Writing settings.gradle"
echo "===================================================="
cat << 'SETTINGS_EOF' > settings.gradle
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "Robo Andy"
include ':app'
SETTINGS_EOF

echo "===================================================="
echo " STEP 2: Writing build.gradle ( configured for Java 21 )"
echo "===================================================="
cat << 'GRADLE_EOF' > app/build.gradle
plugins {
    id 'com.android.application' version '8.5.0'
    id 'org.jetbrains.kotlin.android' version '1.9.24'
}

android {
    namespace 'com.example.robo_andy'
    compileSdk 34

    defaultConfig {
        applicationId "com.example.robo_andy"
        minSdk 26
        targetSdk 34
        versionCode 1
        versionName "1.0"

        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_21
        targetCompatibility JavaVersion.VERSION_21
    }
    
    kotlinOptions {
        jvmTarget = '21'
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    
    // Upgraded MediaPipe GenAI library for modern LiteRT model parsing
    implementation 'com.google.mediapipe:tasks-genai:0.10.35'
    
    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.1.5'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
}
GRADLE_EOF

echo "===================================================="
echo " STEP 3: Writing UI Layout (activity_main.xml)"
echo "===================================================="
cat << 'XML_EOF' > app/src/main/res/layout/activity_main.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp"
    android:gravity="center_horizontal">

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="🤖 Robo Andy Robotics Companion"
        android:textSize="20sp"
        android:textStyle="bold"
        android:layout_marginBottom="4dp" />

    <TextView
        android:id="@+id/statusTextView"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Initializing UI..."
        android:textSize="12sp"
        android:textColor="#E65100"
        android:layout_marginBottom="12dp"
        android:gravity="center" />

    <ScrollView
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1"
        android:background="#F5F5F5"
        android:padding="12dp"
        android:layout_marginBottom="12dp">

        <TextView
            android:id="@+id/responseTextView"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="UI loaded. Preparing internal memory sandbox..."
            android:textSize="15sp"
            android:textColor="#333333" />
    </ScrollView>

    <EditText
        android:id="@+id/promptEditText"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Type a command or question..."
        android:inputType="text"
        android:layout_marginBottom="8dp" />

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:weightSum="3"
        android:layout_marginBottom="8dp">

        <Button
            android:id="@+id/sendButton"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="Send Text"
            android:textSize="12sp" />

        <Button
            android:id="@+id/voiceButton"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="🎤 Voice"
            android:textSize="12sp"
            android:layout_marginStart="4dp"
            android:layout_marginEnd="4dp" />

        <Button
            android:id="@+id/visionButton"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="📷 Vision"
            android:textSize="12sp" />
    </LinearLayout>

</LinearLayout>
XML_EOF

echo "===================================================="
echo " STEP 4: Writing AssistantManager.kt"
echo "===================================================="
cat << 'MGR_EOF' > app/src/main/java/com/example/robo_andy/AssistantManager.kt
package com.example.robo_andy

import android.app.Activity
import android.content.Context
import android.util.Log
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import java.io.File
import kotlin.concurrent.thread

class AssistantManager(private val context: Context, private val onStatusChanged: (String, Boolean) -> Unit) {
    private var llmInference: LlmInference? = null
    var isModelLoaded: Boolean = false
        private set
    var initializationStatus: String = "Preparing internal memory..."
        private set

    init {
        thread(start = true) {
            try {
                val internalModelFile = File(context.filesDir, "model.task")

                if (!internalModelFile.exists()) {
                    initializationStatus = "Copying model to internal memory..."
                    (context as? Activity)?.runOnUiThread { onStatusChanged(initializationStatus, false) }

                    val sourceFile = File(context.getExternalFilesDir(null), "model.task")
                    if (sourceFile.exists()) {
                        Log.d("RoboAndy", "Copying model from staging to internal memory...")
                        sourceFile.copyTo(internalModelFile, overwrite = true)
                        Log.d("RoboAndy", "Copy complete!")
                    } else {
                        Log.e("RoboAndy", "Source model file not found in staging directory.")
                    }
                }

                if (internalModelFile.exists()) {
                    initializationStatus = "Loading TinyLlama into memory (takes 10-15s)..."
                    (context as? Activity)?.runOnUiThread { onStatusChanged(initializationStatus, false) }

                    Log.d("RoboAndy", "Initializing LlmInference from: ${internalModelFile.absolutePath}")
                    val options = LlmInference.LlmInferenceOptions.builder()
                        .setModelPath(internalModelFile.absolutePath)
                        .setMaxTokens(512)
                        .build()

                    llmInference = LlmInference.createFromOptions(context, options)
                    isModelLoaded = true
                    initializationStatus = "Model loaded successfully!"
                    Log.d("RoboAndy", "Model loaded successfully!")
                } else {
                    isModelLoaded = false
                    initializationStatus = "Error: model.task missing from internal storage."
                    Log.e("RoboAndy", initializationStatus)
                }
            } catch (e: Exception) {
                isModelLoaded = false
                val errorMsg = e.localizedMessage ?: e.javaClass.simpleName
                initializationStatus = "AI Error: $errorMsg"
                Log.e("RoboAndy", "Failed to load LLM model", e)
            }

            (context as? Activity)?.runOnUiThread {
                onStatusChanged(initializationStatus, isModelLoaded)
            }
        }
    }

    fun generateResponse(prompt: String): String {
        if (!isModelLoaded || llmInference == null) {
            return "AI model is still loading or failed to load. Check status banner above."
        }
        return try {
            llmInference?.generateResponse(prompt) ?: "Model returned an empty response."
        } catch (e: Exception) {
            Log.e("RoboAndy", "Error generating response", e)
            "Error generating response: ${e.message}"
        }
    }

    fun close() {
        llmInference = null
    }
}
MGR_EOF

echo "===================================================="
echo " STEP 5: Writing MainActivity.kt"
echo "===================================================="
cat << 'KT_EOF' > app/src/main/java/com/example/robo_andy/MainActivity.kt
package com.example.robo_andy

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import java.util.Locale

class MainActivity : AppCompatActivity(), TextToSpeech.OnInitListener {
    private var assistantManager: AssistantManager? = null
    private var speechRecognizer: SpeechRecognizer? = null
    private var textToSpeech: TextToSpeech? = null
    
    private lateinit var responseTextView: TextView
    private lateinit var promptEditText: EditText
    private lateinit var statusTextView: TextView

    private val permissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val micGranted = permissions[Manifest.permission.RECORD_AUDIO] ?: false
        val camGranted = permissions[Manifest.permission.CAMERA] ?: false
        if (!micGranted || !camGranted) {
            Toast.makeText(this, "Microphone and Camera permissions are recommended.", Toast.LENGTH_SHORT).show()
        }
    }

    private val cameraLauncher = registerForActivityResult(
        ActivityResultContracts.TakePicturePreview()
    ) { bitmap: Bitmap? ->
        if (bitmap != null) {
            val msg = "Camera frame captured (${bitmap.width}x${bitmap.height} px)."
            responseTextView.text = msg
            speakOut(msg)
        } else {
            responseTextView.text = "Camera capture cancelled."
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        statusTextView = findViewById(R.id.statusTextView)
        responseTextView = findViewById(R.id.responseTextView)
        promptEditText = findViewById(R.id.promptEditText)
        val sendButton = findViewById<Button>(R.id.sendButton)
        val voiceButton = findViewById<Button>(R.id.voiceButton)
        val visionButton = findViewById<Button>(R.id.visionButton)

        statusTextView.text = "Initializing background loader..."
        statusTextView.setTextColor(android.graphics.Color.parseColor("#E65100"))

        assistantManager = AssistantManager(this) { status, loaded ->
            statusTextView.text = status
            if (loaded) {
                statusTextView.setTextColor(android.graphics.Color.parseColor("#388E3C"))
                responseTextView.text = "TinyLlama is ready! Type a prompt, tap Voice, or snap a Photo."
            } else {
                statusTextView.setTextColor(android.graphics.Color.parseColor("#D32F2F"))
            }
        }

        try {
            textToSpeech = TextToSpeech(this, this)
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        } catch (e: Exception) {
            responseTextView.text = "Audio Engine Error: ${e.localizedMessage}"
        }

        val speechIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
        }

        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                responseTextView.text = "Listening... Speak your command."
            }
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {
                responseTextView.text = "Processing speech..."
            }
            override fun onError(error: Int) {
                responseTextView.text = "Speech error code: $error"
            }
            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (!matches.isNullOrEmpty()) {
                    val spokenText = matches[0]
                    promptEditText.setText(spokenText)
                    responseTextView.text = "Heard: \"$spokenText\"\nThinking..."
                    
                    val response = assistantManager?.generateResponse(spokenText) ?: "AI not initialized."
                    responseTextView.text = response
                    speakOut(response)
                }
            }
            override fun onPartialResults(partialResults: Bundle?) {}
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })

        permissionLauncher.launch(arrayOf(Manifest.permission.RECORD_AUDIO, Manifest.permission.CAMERA))

        sendButton.setOnClickListener {
            val prompt = promptEditText.text.toString().trim()
            if (prompt.isNotEmpty()) {
                responseTextView.text = "Thinking..."
                val response = assistantManager?.generateResponse(prompt) ?: "AI model not ready."
                responseTextView.text = response
                speakOut(response)
            } else {
                Toast.makeText(this, "Please enter a prompt", Toast.LENGTH_SHORT).show()
            }
        }

        voiceButton.setOnClickListener {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
                speechRecognizer?.startListening(speechIntent)
            } else {
                permissionLauncher.launch(arrayOf(Manifest.permission.RECORD_AUDIO))
            }
        }

        visionButton.setOnClickListener {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
                cameraLauncher.launch(null)
            } else {
                permissionLauncher.launch(arrayOf(Manifest.permission.CAMERA))
            }
        }
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            textToSpeech?.language = Locale.getDefault()
        }
    }

    private fun speakOut(text: String) {
        textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, null)
    }

    override fun onDestroy() {
        super.onDestroy()
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        speechRecognizer?.destroy()
        assistantManager?.close()
    }
}
KT_EOF

echo "===================================================="
echo " STEP 6: Building & Installing APK with Java 21"
echo "===================================================="
if ! adb get-state 1>/dev/null 2>&1; then
    echo "ERROR: No Android device detected via ADB."
    exit 1
fi

./gradlew clean
./gradlew assembleDebug

echo "Uninstalling old APK..."
adb uninstall com.example.robo_andy || true

echo "Installing fresh APK..."
adb install app/build/outputs/apk/debug/app-debug.apk

echo "===================================================="
echo " STEP 7: Ensuring Model Staging & Launch"
echo "===================================================="
TASK_FILE=$(find ~/.cache/huggingface/hub -name "*.task" -o -name "*.litertlm" | head -n 1)
if [ -n "$TASK_FILE" ]; then
    echo "Pushing model to device staging folder..."
    adb shell mkdir -p /sdcard/Android/data/com.example.robo_andy/files/
    adb push "$TASK_FILE" /sdcard/Android/data/com.example.robo_andy/files/model.task
fi

adb shell am start -n com.example.robo_andy/.MainActivity
echo "===================================================="
echo " SUCCESS: Built with Java 21 and deployed!"
echo "===================================================="
