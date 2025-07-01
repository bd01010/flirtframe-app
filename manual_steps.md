# 🔧 Manual Steps to Get Core ML Models

Since your GitHub token doesn't have repo creation permissions, here's the fastest way:

## Option 1: Use GitHub Web Interface (2 minutes)

1. **Open GitHub**: https://github.com/new
2. **Create repo**:
   - Name: `flirtframe-model-build`
   - Private: ✓
   - Click "Create repository"

3. **Copy these commands** and run them:
```bash
cd /mnt/c/Users/J/ballparkpal-scraper/_flirtframe
git remote add origin https://github.com/bd01010/flirtframe-model-build.git
git branch -M main
git push -u origin main
```

4. **Run the workflow**:
   - Go to: https://github.com/bd01010/flirtframe-model-build/actions
   - Click "Build CoreML models"
   - Click "Run workflow"

## Option 2: Download Pre-built Models (Faster)

I can help you download pre-converted Core ML models from other sources:

```bash
# Download ResNet50 as vision model placeholder
curl -L -o Models/vision_model.mlmodel \
  "https://docs-assets.developer.apple.com/coreml/models/Image/ImageClassification/ResNet50/ResNet50.mlmodel"

# Download BERT as text model placeholder  
curl -L -o Models/text_model.mlmodel \
  "https://docs-assets.developer.apple.com/coreml/models/Text/QuestionAnswering/BERT-SQuAD/BERT-SQuAD.mlmodel"
```

## Which option do you prefer?

1. Create repo and build real models (40 min but gets LLaVA + Phi-3)
2. Use placeholder models (instant but not the exact models)

Just type 1 or 2 and I'll help you complete it.