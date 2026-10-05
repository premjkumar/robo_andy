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

    private lateinit var assistantManager: AssistantManager
    private lateinit var promptEditText: EditText
    private lateinit var sendButton: Button
    private lateinit var responseTextView: TextView
    private lateinit var statusTextView: TextView
    private var textToSpeech: TextToSpeech? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        promptEditText = findViewById(R.id.promptEditText)
        sendButton = findViewById(R.id.sendButton)
        responseTextView = findViewById(R.id.responseTextView)
        statusTextView = findViewById(R.id.statusTextView)

        textToSpeech = TextToSpeech(this, this)

        assistantManager = AssistantManager(this) { status, loaded ->
            runOnUiThread {
                statusTextView.text = status
                if (loaded) {
                    responseTextView.text = "Model ready. Enter a prompt below."
                }
            }
        }

        lifecycleScope.launch {
            // Must match the filename placed inside app/src/main/assets/
            val fileName = "model.litertlm"
            assistantManager.initializeModelFromAssets(fileName)
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
            responseTextView.text = "Thinking..."
            val response = assistantManager.generateResponse(prompt)
            responseTextView.text = response
            speakOut(response)
        }
    }

    private fun speakOut(text: String) {
        textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "")
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            textToSpeech?.language = Locale.US
        }
    }

    override fun onDestroy() {
        assistantManager.close()
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        super.onDestroy()
    }
}