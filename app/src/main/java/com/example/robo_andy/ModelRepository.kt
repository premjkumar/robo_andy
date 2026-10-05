package com.example.robo_andy

import android.content.Context
import android.util.Log
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.io.FileOutputStream
import java.util.zip.ZipFile

class ModelRepository(private val context: Context) {
    private val client = OkHttpClient()
    private var llmInference: LlmInference? = null
    var isInitialized: Boolean = false
        private set

    companion object {
        private const val TAG = "ModelRepository"
        // Expected minimum size for Gemma 3 270M task file (~160MB)
        private const val MIN_MODEL_SIZE_BYTES = 100_000_000L 
    }

    suspend fun initializeModel(url: String, fileName: String, temperature: Float, onProgress: (Int) -> Unit): Boolean = withContext(Dispatchers.IO) {
        try {
            val modelFile = File(context.filesDir, fileName)
            
            // 1. Download if missing, empty, or corrupted/too small
            if (!modelFile.exists() || modelFile.length() < MIN_MODEL_SIZE_BYTES) {
                if (modelFile.exists()) modelFile.delete()
                
                Log.i(TAG, "Downloading model from $url...")
                val request = Request.Builder().url(url).build()
                client.newCall(request).execute().use { response ->
                    if (!response.isSuccessful) {
                        Log.e(TAG, "Download failed with HTTP code: ${response.code}")
                        return@withContext false
                    }

                    val body = response.body ?: return@withContext false
                    val contentLength = body.contentLength()
                    
                    body.byteStream().use { input ->
                        FileOutputStream(modelFile).use { output ->
                            val buffer = ByteArray(8192)
                            var bytesCopied: Long = 0
                            var bytes: Int
                            while (input.read(buffer).also { bytes = it } >= 0) {
                                output.write(buffer, 0, bytes)
                                bytesCopied += bytes
                                if (contentLength > 0) {
                                    val progress = ((bytesCopied * 100) / contentLength).toInt()
                                    onProgress(progress)
                                }
                            }
                            output.flush()
                        }
                    }
                }
                
                // Validate final file size after download
                if (modelFile.length() < MIN_MODEL_SIZE_BYTES) {
                    Log.e(TAG, "Downloaded file is incomplete (${modelFile.length()} bytes). Deleting.")
                    modelFile.delete()
                    return@withContext false
                }
                
                Log.i(TAG, "Model download complete. File size: ${modelFile.length()} bytes")
            } else {
                Log.i(TAG, "Using existing model file: ${modelFile.absolutePath} (${modelFile.length()} bytes)")
            }

            // 2. Validate zip structure before passing to MediaPipe
            if (!isValidZip(modelFile)) {
                Log.e(TAG, "Model file is not a valid zip archive. Deleting corrupted file.")
                modelFile.delete()
                return@withContext false
            }

            // 3. Initialize MediaPipe LlmInference options
            Log.i(TAG, "Initializing LlmInference from path: ${modelFile.absolutePath}")
            val options = LlmInference.LlmInferenceOptions.builder()
                .setModelPath(modelFile.absolutePath)
                .setMaxTokens(512)
                .setTemperature(temperature)
                .build()

            llmInference = LlmInference.createFromOptions(context, options)
            isInitialized = true
            Log.i(TAG, "LlmInference initialized successfully!")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize model: ${e.message}", e)
            isInitialized = false
            false
        }
    }

    private fun isValidZip(file: File): Boolean {
        return try {
            ZipFile(file).use { true }
        } catch (e: Exception) {
            false
        }
    }

    suspend fun generateResponse(prompt: String): String = withContext(Dispatchers.IO) {
        try {
            val inference = llmInference ?: return@withContext "Local model not initialized yet."
            return@withContext inference.generateResponse(prompt) ?: "No response generated"
        } catch (e: Exception) {
            Log.e(TAG, "Inference error: ${e.message}", e)
            return@withContext "Inference error: ${e.localizedMessage}"
        }
    }
}