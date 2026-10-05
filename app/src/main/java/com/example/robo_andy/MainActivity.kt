package com.example.robo_andy

import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.util.Log
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch
import java.util.Locale

class MainActivity : AppCompatActivity(), TextToSpeech.OnInitListener {

    private lateinit var modelRepository: ModelRepository
    private lateinit var promptEditText: EditText
    private lateinit var sendButton: Button
    private lateinit var responseTextView: TextView
    private lateinit var statusTextView: TextView
    private var textToSpeech: TextToSpeech? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        modelRepository = ModelRepository(this)
        
        promptEditText = findViewById(R.id.promptEditText)
        sendButton = findViewById(R.id.sendButton)
        responseTextView = findViewById(R.id.responseTextView)
        statusTextView = findViewById(R.id.statusTextView)

        textToSpeech = TextToSpeech(this, this)

        lifecycleScope.launch {
            val modelUrl = "YOUR_MODEL_DOWNLOAD_URL_HERE"
            val fileName = "model.task"
            statusTextView.text = "Initializing model..."
            
            // Note: If you removed setTemperature from ModelRepository, make sure the initializeModel call matches its parameters
            val success = modelRepository.initializeModel(modelUrl, fileName, 0.7f) { progress ->
                runOnUiThread {
                    statusTextView.text = "Downloading model: $progress%"
                }
            }
            
            if (success) {
                statusTextView.text = "Model ready."
                responseTextView.text = "Model ready. Enter a prompt below."
            } else {
                statusTextView.text = "Initialization failed."
                responseTextView.text = "Failed to initialize model."
            }
        }

        sendButton.setOnClickListener {
            val prompt = promptEditText.text.toString().trim()
            if (prompt.isNotEmpty()) {
                callLocalModel(prompt)
            } else {
                Toast.makeText(this, "Please enter a prompt", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun callLocalModel(prompt: String) {
        lifecycleScope.launch {
            try {
                responseTextView.text = "Thinking..."
                val response = modelRepository.generateResponse(prompt)
                responseTextView.text = response
                speakOut(response)
            } catch (e: Exception) {
                val errorMsg = "Error: ${e.localizedMessage}"
                responseTextView.text = errorMsg
                Log.e("LocalModel", errorMsg, e)
            }
        }
    }

    private fun speakOut(text: String) {
        textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "")
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            val result = textToSpeech?.setLanguage(Locale.US)
            if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                Log.e("TTS", "The Language specified is not supported!")
            }
        } else {
            Log.e("TTS", "Initialization Failed!")
        }
    }

    override fun onDestroy() {
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        super.onDestroy()
    }
}