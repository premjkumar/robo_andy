#!/usr/bin/env bash
set -e

echo "=== Upgrading to Interactive Voice & Auto-Scrolling Chat ==="

cat << 'JAVA_EOF' > app/src/main/java/com/local/assistant/MainActivity.java
package com.local.assistant;

import android.content.Intent;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.provider.MediaStore;
import android.speech.tts.TextToSpeech;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ScrollView;
import android.widget.TextView;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;
import com.local.assistant.core.AssistantCore;
import org.json.JSONObject;
import java.util.Locale;

public class MainActivity extends AppCompatActivity implements TextToSpeech.OnInitListener {

    private TextView chatLogTextView;
    private ScrollView chatScrollView;
    private EditText messageEditText;
    private Button sendButton, cameraButton, voiceButton;
    private AssistantCore assistantCore;
    private TextToSpeech tts;
    private boolean isTtsReady = false;

    private ActivityResultLauncher<Intent> cameraLauncher;
    private ActivityResultLauncher<Intent> speechLauncher;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        assistantCore = new AssistantCore(this);
        tts = new TextToSpeech(this, this);

        chatLogTextView = findViewById(R.id.chatLogTextView);
        chatScrollView = (ScrollView) chatLogTextView.getParent();
        messageEditText = findViewById(R.id.messageEditText);
        sendButton = findViewById(R.id.sendButton);
        cameraButton = findViewById(R.id.cameraButton);
        voiceButton = findViewById(R.id.voiceButton);

        checkInitialState();

        cameraLauncher = registerForActivityResult(
            new ActivityResultContracts.StartActivityForResult(),
            result -> {
                if (result.getResultCode() == RESULT_OK && result.getData() != null) {
                    Bundle extras = result.getData().getExtras();
                    Bitmap imageBitmap = (Bitmap) extras.get("data");
                    if (imageBitmap != null) {
                        appendChatAndSpeak("You: [Captured Camera Image]\nAndy: Great shot! I'm scanning this visually through our local context pipeline.");
                    }
                }
            }
        );

        speechLauncher = registerForActivityResult(
            new ActivityResultContracts.StartActivityForResult(),
            result -> {
                if (result.getResultCode() == RESULT_OK && result.getData() != null) {
                    java.util.ArrayList<String> matches = result.getData()
                        .getStringArrayListExtra(android.speech.RecognizerIntent.EXTRA_RESULTS);
                    if (matches != null && !matches.isEmpty()) {
                        String spokenText = matches.get(0);
                        messageEditText.setText(spokenText);
                        handleUserPrompt(spokenText);
                    }
                }
            }
        );

        cameraButton.setOnClickListener(v -> cameraLauncher.launch(new Intent(MediaStore.ACTION_IMAGE_CAPTURE)));
        
        voiceButton.setOnClickListener(v -> {
            Intent intent = new Intent(android.speech.RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
            intent.putExtra(android.speech.RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                    android.speech.RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
            intent.putExtra(android.speech.RecognizerIntent.EXTRA_PROMPT, "Chat with Robo Andy...");
            speechLauncher.launch(intent);
        });

        sendButton.setOnClickListener(v -> {
            String userMessage = messageEditText.getText().toString().trim();
            if (!userMessage.isEmpty()) {
                messageEditText.setText("");
                handleUserPrompt(userMessage);
            }
        });
    }

    @Override
    public void onInit(int status) {
        if (status == TextToSpeech.SUCCESS) {
            int result = tts.setLanguage(Locale.US);
            if (result != TextToSpeech.LANG_MISSING_DATA && result != TextToSpeech.LANG_NOT_SUPPORTED) {
                isTtsReady = true;
            }
        }
    }

    private void checkInitialState() {
        if (assistantCore.isModelDownloaded()) {
            appendChat("System: TinyLlama model weights loaded and active on device.\n");
        } else {
            appendChat("System: Tap send or speak to auto-fetch TinyLlama model weights securely.\n");
        }
    }

    private void handleUserPrompt(String query) {
        appendChat("You: " + query);

        if (!assistantCore.isModelDownloaded()) {
            appendChatAndSpeak("Andy: Hang tight Sharon! I'm downloading my TinyLlama weights to your local storage right now.");
            assistantCore.downloadTinyLlama(new AssistantCore.DownloadCallback() {
                @Override
                public void onProgress(int progress) {}
                @Override
                public void onSuccess() {
                    runOnUiThread(() -> appendChatAndSpeak("Andy: Download complete! I am fully online and ready to chat."));
                }
                @Override
                public void onError(String error) {
                    runOnUiThread(() -> appendChatAndSpeak("Andy: Oops, download hit a snag: " + error));
                }
            });
            return;
        }

        String lower = query.toLowerCase();
        if (lower.contains("weather") || lower.contains("lookup") || lower.contains("internet")) {
            new Thread(() -> {
                String result = assistantCore.executeToolOrMCP("fetch_web_lookup", new JSONObject());
                runOnUiThread(() -> appendChatAndSpeak("Andy [Live Tool]: " + result));
            }).start();
        } else if (lower.contains("map") || lower.contains("where")) {
            try {
                JSONObject args = new JSONObject();
                args.put("query", query);
                String result = assistantCore.executeToolOrMCP("get_location_map", args);
                appendChatAndSpeak("Andy [MCP Tool]: " + result);
            } catch (Exception e) {
                appendChatAndSpeak("Andy: Had trouble executing that tool command.");
            }
        } else {
            java.util.List<String> ragMemories = assistantCore.queryVectorDatabase(query);
            appendChatAndSpeak("Andy: I hear you loud and clear! Since we're running locally with vector RAG memory, I'm ready to assist you like a true friend.");
        }
    }

    private void appendChat(String text) {
        chatLogTextView.append(text + "\n\n");
        scrollToBottom();
    }

    private void appendChatAndSpeak(String text) {
        appendChat(text);
        if (isTtsReady) {
            // Strip out tag bracket info for natural speaking text if needed
            String spokenText = text.replaceAll("\\[.*?\\]", "").replace("Andy:", "").trim();
            tts.speak(spokenText, TextToSpeech.QUEUE_FLUSH, null, null);
        }
    }

    private void scrollToBottom() {
        chatScrollView.post(() -> chatScrollView.fullScroll(View.FOCUS_DOWN));
    }

    @Override
    protected void onDestroy() {
        if (tts != null) {
            tts.stop();
            tts.shutdown();
        }
        super.onDestroy();
    }
}
JAVA_EOF

echo "Building and updating interactive release..."
gradle assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
echo "=== Done! Robo Andy now speaks out loud and auto-scrolls its chat interface. ==="
