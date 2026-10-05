package com.example.robo_andy

import android.content.Context
import android.util.Log
import com.google.ai.edge.litertlm.Engine
import com.google.ai.edge.litertlm.EngineConfig
import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.Conversation
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

class AssistantManager(
    private val context: Context,
    private val callback: ((status: String, loaded: Boolean) -> Unit)? = null
) {
    private var engine: Engine? = null
    private var conversation: Conversation? = null
    var isInitialized: Boolean = false
        private set

    companion object {
        private const val TAG = "AssistantManager"
    }

    suspend fun initializeModelFromAssets(fileName: String) = withContext(Dispatchers.IO) {
        try {
            callback?.invoke("Loading model from assets...", false)
            
            // Copy asset to internal files directory for LiteRT access
            val outFile = File(context.filesDir, fileName)
            if (!outFile.exists()) {
                context.assets.open(fileName).use { input ->
                    outFile.outputStream().use { output ->
                        input.copyTo(output)
                    }
                }
            }

            if (!outFile.exists() || outFile.length() == 0L) {
                val err = "Model asset not found or empty: $fileName"
                Log.e(TAG, err)
                callback?.invoke(err, false)
                return@withContext
            }

            callback?.invoke("Initializing LiteRT-LM engine...", false)
            val config = EngineConfig(
                modelPath = outFile.absolutePath,
                backend = Backend.CPU()
            )
            
            engine = Engine(config)
            engine?.initialize()
            conversation = engine?.createConversation()
            
            isInitialized = true
            Log.d(TAG, "LiteRT-LM model initialized successfully from assets.")
            callback?.invoke("Model ready.", true)
        } catch (e: Exception) {
            isInitialized = false
            Log.e(TAG, "Failed to initialize LiteRT-LM from assets", e)
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
            Log.e(TAG, "Error during LiteRT-LM inference", e)
            "Error generating response: ${e.message}"
        }
    }

    fun close() {
        try {
            conversation?.close()
            engine?.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error closing LiteRT-LM resources", e)
        } finally {
            conversation = null
            engine = null
            isInitialized = false
        }
    }
}