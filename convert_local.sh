#!/bin/bash
# Local Core ML conversion script (requires macOS)

echo "Installing dependencies..."
pip3 install torch transformers coremltools sentencepiece accelerate

echo "Downloading models..."
git clone https://huggingface.co/liuhaotian/llava-v1.5-7b llava_weights
git clone https://huggingface.co/microsoft/phi-3-mini-4k-instruct phi3_weights

echo "Converting LLaVA..."
python3 - <<'EOF'
import coremltools as ct
import torch
from transformers import LlavaForConditionalGeneration

print("Loading LLaVA model...")
model = LlavaForConditionalGeneration.from_pretrained("llava_weights", torch_dtype=torch.float16)

print("Converting vision tower to Core ML...")
ml_model = ct.convert(
    model.model.vision_tower,
    inputs=[ct.ImageType(shape=(1, 3, 224, 224), scale=1/255.0)],
    convert_to="mlprogram",
    compute_units=ct.ComputeUnit.ALL
)

print("Saving LLaVA_4b.mlmodelc...")
ml_model.save("Models/LLaVA_4b.mlmodelc")
EOF

echo "Converting Phi-3..."
python3 - <<'EOF'
import coremltools as ct
import torch
from transformers import AutoModelForCausalLM

print("Loading Phi-3 model...")
model = AutoModelForCausalLM.from_pretrained("phi3_weights", torch_dtype=torch.float16)

print("Converting to Core ML...")
ml_model = ct.convert(
    model,
    inputs=[ct.TensorType(shape=(1, 2048), dtype=ct.int32)],
    convert_to="mlprogram",
    compute_units=ct.ComputeUnit.ALL
)

print("Quantizing to 4-bit...")
ml_model = ct.models.neural_network.quantization_utils.quantize_weights(
    ml_model, nbits=4, quantization_mode="linear_symmetric"
)

print("Saving AppleFM_3b.mlmodelc...")
ml_model.save("Models/AppleFM_3b.mlmodelc")
EOF

echo "✅ Conversion complete!"