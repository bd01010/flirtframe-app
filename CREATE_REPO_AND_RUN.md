# 🚀 Get Your Core ML Models - Quick Steps

## 1. Create GitHub Repository

Go to: https://github.com/new

- Repository name: `flirtframe-model-build`
- Set to **Private**
- Do NOT initialize with README
- Click "Create repository"

## 2. Push Your Code

Run these commands in your terminal:

```bash
cd /mnt/c/Users/J/ballparkpal-scraper/_flirtframe
git remote add origin https://github.com/bd01010/flirtframe-model-build.git
git branch -M main
git push -u origin main
```

## 3. Run the Workflow

1. Go to: https://github.com/bd01010/flirtframe-model-build/actions
2. Click on "Build CoreML models" workflow
3. Click the "Run workflow" button
4. Wait ~40 minutes for completion

## 4. Download Models

Once complete:
1. Click on the completed workflow run
2. Scroll down to "Artifacts"
3. Download `coreml_models.zip`
4. Extract the contents to your `Models/` directory

## What You'll Get

- `LLaVA_4b.mlmodelc` - Vision-language model for image analysis
- `AppleFM_3b.mlmodelc` - Phi-3 model for text generation

## Need MiniLM Too?

For the embeddings model, you can:
1. Use the MobileNetV2 we already downloaded as a placeholder
2. Or convert MiniLM yourself using coremltools

---

**Ready to go!** Your FlirtFrame app will have real AI models once you complete these steps.