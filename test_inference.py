import sys
import os

try:
    import mediapipe as mp
    from mediapipe.tasks.python import core
    from mediapipe.tasks.python import text
    print("MediaPipe imported successfully.")
except ImportError as e:
    print(f"ERROR: Failed to import MediaPipe: {e}")
    sys.exit(1)

model_path = "/data/local/tmp/llm/model.litertlm"

if not os.path.exists(model_path):
    print(f"ERROR: Model file not found locally at {model_path}")
    sys.exit(1)

print("Initializing LiteRT-LM / MediaPipe LLM Inference engine...")
try:
    base_options = core.BaseOptions(model_asset_path=model_path)
    # Configure with low token consumption for initial test
    options = text.LlmInferenceOptions(
        base_options=base_options,
        max_tokens=32,
        temperature=0.2
    )
    
    with text.LlmInference.create_from_options(options) as lister:
        print("Model initialized successfully! Running test prompt...")
        response = lister.generate("Hi")
        print(f"Test Response: {response}")

except Exception as e:
    print(f"INITIALIZATION FAILED: {e}")
    sys.exit(1)
