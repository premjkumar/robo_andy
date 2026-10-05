#!/bin/bash
set -e

echo "===================================================="
echo " STEP 1: Setting up Python Environment"
echo "===================================================="

if [ ! -d "mp_env" ]; then
    python3 -m venv mp_env
fi
source mp_env/bin/activate

echo "Installing Hugging Face Hub client..."
pip install --upgrade pip --quiet
pip install --quiet huggingface_hub

echo "===================================================="
echo " STEP 2: Downloading Pre-Converted TinyLlama Model"
echo "===================================================="

python3 - << 'PYTHON_SCRIPT'
from huggingface_hub import snapshot_download
import os

print("Fetching pre-converted TinyLlama MediaPipe task file...")
download_dir = snapshot_download(
    repo_id="litert-community/TinyLlama-1.1B-Chat-v1.0",
    allow_patterns=["*.task", "*.litertlm"]
)
print(f"Model downloaded to cache: {download_dir}")
PYTHON_SCRIPT

echo "===================================================="
echo " STEP 3: Pushing Model to Device via ADB"
echo "===================================================="

if ! adb get-state 1>/dev/null 2>&1; then
    echo "ERROR: No Android device detected via ADB. Check your USB connection."
    exit 1
fi

# Locate the downloaded .task or .litertlm file from HF cache
TASK_FILE=$(find ~/.cache/huggingface/hub -name "*.task" -o -name "*.litertlm" | head -n 1)

if [ -z "$TASK_FILE" ]; then
    echo "ERROR: Could not find downloaded task file in cache."
    exit 1
fi

echo "Found model file: $TASK_FILE"
echo "Pushing model to device storage (/data/local/tmp/llm/model.task)..."

adb shell mkdir -p /data/local/tmp/llm/
adb push "$TASK_FILE" /data/local/tmp/llm/model.task

echo "===================================================="
echo " SUCCESS: TinyLlama is live on your Samsung device!"
echo "===================================================="
