package com.example.robo_andy

import android.content.Context
import android.util.Log
import com.google.ai.edge.litertlm.Engine
import com.google.ai.edge.litertlm.EngineConfig
import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.Conversation
import java.io.File

class AssistantManager(
    private val context: Context,
    private val callback: ((status: String, loaded: Boolean) -> Unit)? = null
) {
    private var engine: Engine? = null
    private var conversation: Conversation? = null
    var isInitialized: Boolean = false
        private set

    fun initializeModel(modelPath: String) {
        try {
            callback?.invoke("Initializing LiteRT-LM model...", false)
            val file = File(modelPath)
            if (!file.exists()) {
                val errorMsg = "Model file not found at: $modelPath"
                Log.e("AssistantManager", errorMsg)
                callback?.invoke(errorMsg, false)
                isInitialized = false
                return
            }

            // Configure LiteRT-LM engine with CPU backend
            val config = EngineConfig(
                modelPath = file.absolutePath,
                backend = Backend.CPU()
            )
            
            engine = Engine(config)
            engine?.initialize()
            conversation = engine?.createConversation()
            
            isInitialized = true
            Log.d("AssistantManager", "LiteRT-LM model initialized successfully.")
            callback?.invoke("Model initialized successfully.", true)
        } catch (e: Exception) {
            isInitialized = false
            Log.e("AssistantManager", "Failed to initialize LiteRT-LM engine", e)
            callback?.invoke("Initialization failed: ${e.message}", false)
        }
    }

    fun generateResponse(prompt: String): String {
        if (!isInitialized || conversation == null) {
            return "LiteRT-LM model is not initialized yet."
        }
        return try {
            val responseMessage = conversation?.sendMessage(prompt)
            responseMessage?.toString() ?: "Model returned an empty response."
        } catch (e: Exception) {
            Log.e("AssistantManager", "Error during LiteRT-LM inference", e)
            "Error generating response: ${e.message}"
        }
    }

    fun close() {
        try {
            conversation?.close()
            engine?.close()
        } catch (e: Exception) {
            Log.e("AssistantManager", "Error closing LiteRT-LM resources", e)
        } finally {
            conversation = null
            engine = null
            isInitialized = false
        }
    }
}