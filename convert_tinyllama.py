import os
from mediapipe.tasks.python.genai import converter

config = converter.ConversionConfig(
    input_ckpt="TinyLlama/TinyLlama_v1.1",
    ckpt_format="safetensors",
    model_type="LLAMA",
    backend="cpu",
    output_dir="./tinyllama_output",
    combine_file_only=False,
    vocab_model_file=""
)

print("Downloading TinyLlama from Hugging Face and converting to MediaPipe task format...")
converter.convert_checkpoint(config)
print("Conversion complete!")
