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
import android.util.Log
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import java.util.Locale

class MainActivity : AppCompatActivity(), TextToSpeech.OnInitListener {
    private var modelRepository: ModelRepository? = null
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

        statusTextView.text = "Initializing repository..."
        statusTextView.setTextColor(android.graphics.Color.parseColor("#E65100"))

        modelRepository = ModelRepository(this)
        
        // Define user temperature setting here (e.g., from an EditText slider or preference)
        val userTemperature = 0.7f 
        setupAndDownloadModel(userTemperature)

        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        textToSpeech = TextToSpeech(this, this)

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
                    callLocalModel(spokenText)
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
                callLocalModel(prompt)
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

    private fun setupAndDownloadModel(temperature: Float) {
        val fileName = "model.task"
        val modelUrl = "https://huggingface.co/litert-community/TinyLlama-1.1B-Chat-v1.0/resolve/main/TinyLlama-1.1B-Chat-v1.0_multi-prefill-seq_q8_ekv1280.task"

        lifecycleScope.launch {
            statusTextView.text = "Checking/Downloading model..."
            val success = modelRepository?.initializeModel(modelUrl, fileName, temperature) { progress ->
                runOnUiThread {
                    statusTextView.text = "Downloading model: $progress%"
                }
            } ?: false

            if (success) {
                statusTextView.text = "Local AI Model Ready (Temp: $temperature)!"
                statusTextView.setTextColor(android.graphics.Color.parseColor("#388E3C"))
            } else {
                statusTextView.text = "Model setup failed."
                statusTextView.setTextColor(android.graphics.Color.parseColor("#D32F2F"))
            }
        }
    }

    private fun callLocalModel(prompt: String) {
        lifecycleScope.launch {
            try {
                val response = modelRepository?.generateResponse("local", prompt) ?: "Model uninitialized."
                responseTextView.text = response
                speakOut(response)
            } catch (e: Exception) {
                val errorMsg = "Error: ${e.localizedMessage}"
                responseTextView.text = errorMsg
                Log.e("LocalModel", errorMsg, e)
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
    }
}
