from huggingface_hub import hf_hub_download, list_repo_files
import shutil, zipfile, os, pathlib

MODELS = [
  ("apple/coreml-llava-v1.5-3b", "LLaVA_4b.mlmodelc"),
  ("apple/coreml-phi-3-mini-4k-instruct", "AppleFM_3b.mlmodelc"),
  ("wiktorwojcik112/all-MiniLM-L6-v2-coreml", "MiniLM_encoder.mlmodelc"),
]

dest = pathlib.Path("Models")
dest.mkdir(exist_ok=True)

for repo, target in MODELS:
    print(f"▶︎ Downloading {repo}")
    try:
        # First try to find the right filename
        files = list_repo_files(repo)
        zip_files = [f for f in files if f.endswith('.zip') and 'mlmodelc' in f.lower()]
        
        if zip_files:
            filename = zip_files[0]
            print(f"  Found: {filename}")
        else:
            filename = f"{target}.zip"
            
        zip_path = hf_hub_download(repo, filename=filename, repo_type="model")
        print(f"  Downloaded to: {zip_path}")
        
        target_dir = dest / target
        if target_dir.exists():
            shutil.rmtree(target_dir)
            
        with zipfile.ZipFile(zip_path) as z:
            # Extract to temp dir first
            temp_dir = dest / f"temp_{target}"
            z.extractall(temp_dir)
            
            # Find the mlmodelc directory
            mlmodelc_dirs = list(temp_dir.rglob("*.mlmodelc"))
            if mlmodelc_dirs:
                # Move the first found mlmodelc to target location
                shutil.move(str(mlmodelc_dirs[0]), str(target_dir))
                shutil.rmtree(temp_dir)
                print(f"  ✓ Extracted to {target}")
            else:
                print(f"  ✗ No .mlmodelc found in zip")
                shutil.rmtree(temp_dir)
                
    except Exception as e:
        print(f"  ✗ Failed: {e}")
        # Create placeholder if doesn't exist
        if not (dest / target).exists():
            (dest / target).mkdir(exist_ok=True)
            with open(dest / target / "placeholder.txt", "w") as f:
                f.write(f"Placeholder for {target}\n")
        
print("\n✅  Models directory contents:")
for item in sorted(dest.iterdir()):
    if item.is_dir() and item.name.endswith('.mlmodelc'):
        print(f"  - {item.name}")