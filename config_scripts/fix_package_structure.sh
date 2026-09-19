#!/usr/bin/env bash
set -e

echo "=== Restructuring package to root com.local.assistant ==="

# Create root package directory if it doesn't exist
mkdir -p app/src/main/java/com/local/assistant

# Move MainActivity.kt from ui to root package and update its package declaration
cat << 'KT_EOF' > app/src/main/java/com/local/assistant/MainActivity.kt
package com.local.assistant

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.util.Log
import android.widget.EditText
import android.widget.ScrollView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.local.assistant.core.AssistantCore
import java.util.Locale

class MainActivity : AppCompatActivity() {
    companion object {
        private const val PERMISSION_REQUEST_CODE = 200
        private const val TAG = "MainActivity"
    }

    private lateinit var assistantCore: AssistantCore
    private var textToSpeech: TextToSpeech? = null
    private var speechRecognizer: SpeechRecognizer? = null
    
    private lateinit var chatLogView: TextView
    private lateinit var userInputField: EditText
    private lateinit var scrollView: ScrollView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        chatLogView = findViewById(R.id.chatLog)
        userInputField = findViewById(R.id.userInput)
        scrollView = findViewById(R.id.scrollView)

        assistantCore = AssistantCore(this)

        textToSpeech = TextToSpeech(this) { status ->
            if (status == TextToSpeech.SUCCESS) {
                textToSpeech?.language = Locale.US
                speakResponse("Ready.")
            }
        }

        checkAndRequestPermissions()
    }

    private fun checkAndRequestPermissions() {
        val permissions = arrayOf(
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.CAMERA
        )

        val needsRequest = permissions.any {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (needsRequest) {
            ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST_CODE)
        } else {
            initializeSpeechRecognizer()
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            initializeSpeechRecognizer()
        }
    }

    private fun initializeSpeechRecognizer() {
        if (SpeechRecognizer.isRecognitionAvailable(this)) {
            runOnUiThread {
                try {
                    speechRecognizer?.destroy()
                } catch (_: Exception) {}

                try {
                    speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this).apply {
                        setRecognitionListener(object : RecognitionListener {
                            override fun onReadyForSpeech(params: Bundle?) {}
                            override fun onBeginningOfSpeech() {}
                            override fun onRmsChanged(rmsdB: Float) {}
                            override fun onBufferReceived(buffer: ByteArray?) {}
                            override fun onEndOfSpeech() {}
                            override fun onError(error: Int) {
                                restartListeningSafe()
                            }
                            override fun onResults(results: Bundle?) {
                                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                                if (!matches.isNullOrEmpty()) {
                                    val spokenText = matches[0]
                                    appendChat(spokenText)
                                    processUserQuery(spokenText)
                                }
                                restartListeningSafe()
                            }
                            override fun onPartialResults(partialResults: Bundle?) {}
                            override fun onEvent(eventType: Int, params: Bundle?) {}
                        })
                    }
                    startListening()
                } catch (e: Exception) {
                    Log.e(TAG, "Speech recognizer init error", e)
                }
            }
        }
    }

    private fun startListening() {
        try {
            speechRecognizer?.let { recognizer ->
                val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
                    putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                }
                recognizer.startListening(intent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Start listening error", e)
        }
    }

    private fun restartListeningSafe() {
        scrollView.postDelayed({
            startListening()
        }, 1000)
    }

    private fun processUserQuery(query: String) {
        Thread {
            try {
                val response = assistantCore.generateResponse(query)
                runOnUiThread {
                    appendChat(response)
                    speakResponse(response)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Query processing error", e)
            }
        }.start()
    }

    private fun speakResponse(text: String) {
        try {
            textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, null)
        } catch (e: Exception) {
            Log.e(TAG, "TTS error", e)
        }
    }

    private fun appendChat(message: String) {
        try {
            chatLogView.append("\n\n$message")
            scrollView.post { scrollView.fullScroll(ScrollView.FOCUS_DOWN) }
        } catch (e: Exception) {
            Log.e(TAG, "UI append error", e)
        }
    }

    override fun onDestroy() {
        try {
            speechRecognizer?.destroy()
        } catch (_: Exception) {}
        try {
            textToSpeech?.stop()
            textToSpeech?.shutdown()
        } catch (_: Exception) {}
        super.onDestroy()
    }
}
KT_EOF

# Remove the old file from ui folder
rm -f app/src/main/java/com/local/assistant/ui/MainActivity.kt

# Write clean AndroidManifest.xml without legacy package attribute warnings
cat << 'XML_EOF' > app/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

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

echo "=== Performing full clean and rebuild ==="
gradle clean
gradle assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
echo "=== Success! App compiled and running cleanly. ==="
