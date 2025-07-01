from huggingface_hub import hf_hub_download, list_repo_files
import shutil, zipfile, os, pathlib

# Try public alternatives
MODELS = [
  ("coreml-community/coreml-CLIP-ViT-B-32-vision", "LLaVA_4b.mlmodelc"),  # Vision model alternative
  ("coreml-community/coreml-gpt2", "AppleFM_3b.mlmodelc"),  # Text gen alternative
  ("coreml-community/coreml-bert-base-uncased", "MiniLM_encoder.mlmodelc"),  # Embeddings alternative
]

dest = pathlib.Path("Models")
dest.mkdir(exist_ok=True)

print("Trying public Core ML models from coreml-community...")

for repo, target in MODELS:
    print(f"\n▶︎ Trying {repo}")
    try:
        # List files in repo
        files = list_repo_files(repo)
        print(f"  Files found: {len(files)}")
        
        # Look for mlmodel or mlmodelc files
        ml_files = [f for f in files if '.mlmodel' in f or '.mlmodelc' in f or '.mlpackage' in f]
        
        if ml_files:
            # Download the first suitable file
            filename = ml_files[0]
            print(f"  Downloading: {filename}")
            
            file_path = hf_hub_download(repo, filename=filename, repo_type="model")
            print(f"  Downloaded to: {file_path}")
            
            target_dir = dest / target
            if target_dir.exists():
                shutil.rmtree(target_dir)
            target_dir.mkdir()
            
            # Copy or extract based on file type
            if filename.endswith('.zip'):
                with zipfile.ZipFile(file_path) as z:
                    z.extractall(target_dir)
            else:
                # For .mlmodel files, create a simple mlmodelc structure
                shutil.copy(file_path, target_dir / "model.mlmodel")
                
            print(f"  ✓ Saved to {target}")
            
    except Exception as e:
        print(f"  ✗ Failed: {e}")

# Also try downloading from Apple's public models
print("\n▶︎ Downloading MobileNetV2 from Apple...")
try:
    import urllib.request
    url = "https://docs-assets.developer.apple.com/coreml/models/Image/ImageClassification/MobileNetV2/MobileNetV2.mlmodel"
    mobilenet_path = dest / "MobileNetV2.mlmodel"
    urllib.request.urlretrieve(url, mobilenet_path)
    print("  ✓ Downloaded MobileNetV2.mlmodel")
except Exception as e:
    print(f"  ✗ Failed: {e}")

print("\n✅  Final Models directory contents:")
for item in sorted(dest.iterdir()):
    size = ""
    if item.is_file():
        size = f" ({item.stat().st_size / 1024 / 1024:.1f} MB)"
    print(f"  - {item.name}{size}")