package com.local.assistant

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.withContext
import org.codeshipping.llamakotlin.LlamaModel
import java.io.File
import com.google.api.services.drive.Drive
import com.google.api.client.http.FileContent

class AssistantManager(private val context: Context) {
    private var model: LlamaModel? = null

    suspend fun initializeModel(modelPath: String) {
        withContext(Dispatchers.IO) {
            model = LlamaModel.load(modelPath) {
                contextSize = 2048
                threads = 4
                temperature = 0.6f
            }
        }
    }

    fun chatStream(prompt: String): Flow<String>? {
        val systemPrompt = "System: You are an offline mobile assistant. Answer directly.\nUser: $prompt\nAssistant:"
        return model?.generateStream(systemPrompt)
    }

    suspend fun backupLogsToDrive(driveService: Drive, logFile: File) {
        withContext(Dispatchers.IO) {
            val fileMetadata = com.google.api.services.drive.model.File().apply {
                name = "assistant_growth_logs.txt"
            }
            val mediaContent = FileContent("text/plain", logFile)
            driveService.files().create(fileMetadata, mediaContent).execute()
        }
    }

    fun close() {
        model?.close()
    }
}
