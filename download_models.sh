#!/bin/bash
############################################
#  Simple Core ML Model Downloader         #
############################################

set -e
echo "▶︎ Creating Models/ directory"
mkdir -p Models
cd Models

echo "▶︎ Downloading models from Apple's GitHub releases..."

# Download BERT model as a substitute for MiniLM
echo "Downloading BERT for embeddings..."
curl -L -o bert.zip "https://github.com/apple/ml-ferret/releases/download/coreml-bert-base-uncased/BERT.mlmodelc.zip" || true

# Download MobileNetV2 as placeholder for vision model
echo "Downloading MobileNetV2..."
curl -L -o mobilenet.mlmodelc "https://docs-assets.developer.apple.com/coreml/models/Image/ImageClassification/MobileNetV2/MobileNetV2.mlmodel" || true

# Create placeholder directories for the models we need
echo "▶︎ Creating model placeholders..."
mkdir -p LLaVA_4b.mlmodelc
mkdir -p AppleFM_3b.mlmodelc 
mkdir -p MiniLM_encoder.mlmodelc

# Create info files
echo "LLaVA placeholder model" > LLaVA_4b.mlmodelc/info.txt
echo "Phi-3 placeholder model" > AppleFM_3b.mlmodelc/info.txt
echo "MiniLM placeholder model" > MiniLM_encoder.mlmodelc/info.txt

echo "✅ Model directories created"
echo "   Contents:"
ls -la

cd ..
echo ""
echo "⚠️  NOTE: These are placeholder models. For the app to function properly,"
echo "   you need to obtain the actual Core ML models:"
echo "   - LLaVA vision-language model (.mlmodelc)"
echo "   - Phi-3 or similar text generation model (.mlmodelc)"
echo "   - MiniLM embedding model (.mlmodelc)"
echo ""
echo "   You can convert models using coremltools or find pre-converted ones."