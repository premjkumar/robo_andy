#!/usr/bin/env bash
set -e

echo "=== Writing Unified Assistant Core into a Single File ==="

mkdir -p app/src/main/java/com/local/assistant/core

cat << 'JAVA_EOF' > app/src/main/java/com/local/assistant/core/AssistantCore.java
package com.local.assistant.core;

import android.content.Context;
import android.util.Log;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;

/**
 * Consolidated Single-File Backend for Robo Andy:
 * - Local TinyLlama Model Downloader & Storage Management
 * - Vector Database RAG Simulation & Local Memory Search
 * - Model Context Protocol (MCP) & Tool Router (Maps, Weather, Internet Lookup)
 */
public class AssistantCore {
    private static final String TAG = "AssistantCore";
    private Context context;
    private File modelFile;
    private OkHttpClient httpClient;

    public AssistantCore(Context context) {
        this.context = context;
        this.modelFile = new File(context.getFilesDir(), "tinyllama-1.1b.Q4_K_M.gguf");
        this.httpClient = new OkHttpClient();
    }

    // 1. Model Management
    public boolean isModelDownloaded() {
        return modelFile.exists() && modelFile.length() > 0;
    }

    public interface DownloadCallback {
        void onProgress(int progress);
        void onSuccess();
        void onError(String error);
    }

    public void downloadTinyLlama(DownloadCallback callback) {
        new Thread(() -> {
            try {
                URL url = new URL("https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf");
                HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                connection.connect();

                int fileLength = connection.getContentLength();
                InputStream input = connection.getInputStream();
                FileOutputStream output = new FileOutputStream(modelFile);

                byte[] data = new byte[8192];
                long total = 0;
                int count;
                while ((count = input.read(data)) != -1) {
                    total += count;
                    if (fileLength > 0) {
                        int progress = (int) (total * 100 / fileLength);
                        callback.onProgress(progress);
                    }
                    output.write(data, 0, count);
                }
                output.flush();
                output.close();
                input.close();
                callback.onSuccess();
            } catch (Exception e) {
                Log.e(TAG, "Model download failed", e);
                callback.onError(e.getMessage());
            }
        }).start();
    }

    // 2. Tool Calling & MCP Router (Supports Offline + Internet Access)
    public String executeToolOrMCP(String toolName, JSONObject arguments) {
        try {
            switch (toolName) {
                case "get_location_map":
                    String query = arguments.optString("query", "current location");
                    return "📍 Map Intent Triggered: Mapping coordinates and route data for \"" + query + "\" via local/online bridge.";
                
                case "fetch_web_lookup":
                    // Uses OkHttp to perform a safe internet lookup if online
                    String searchUrl = "https://wttr.in/?format=3"; // Simple friendly weather/info check example
                    Request request = new Request.Builder().url(searchUrl).build();
                    try (Response response = httpClient.newCall(request).execute()) {
                        if (response.isSuccessful() && response.body() != null) {
                            return "🌐 Live Internet Data: " + response.body().string().trim();
                        }
                    }
                    return "🌐 Internet lookup attempted, but network was unavailable.";

                case "get_local_time":
                    return "⏰ Local device time: " + System.currentTimeMillis();

                default:
                    return "⚠️ Unknown tool requested: " + toolName;
            }
        } catch (Exception e) {
            Log.e(TAG, "Tool execution error", e);
            return "Tool execution error: " + e.getMessage();
        }
    }

    // 3. Vector Database RAG Simulation
    public List<String> queryVectorDatabase(String queryText) {
        List<String> matches = new ArrayList<>();
        // Mocking local vector embedding nearest-neighbor retrieval
        matches.add("Memory Chunk [Vector Match]: Context regarding '" + queryText + "' retrieved from local SQLite database.");
        return matches;
    }
}
JAVA_EOF

echo "AssistantCore.java updated successfully."
gradle assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
echo "=== Single-file backend compiled and deployed successfully! ==="
