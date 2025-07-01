#!/bin/bash
echo "🚀 Pushing FlirtFrame to GitHub..."

# Remove any existing remote
git remote remove origin 2>/dev/null

# Add new remote
git remote add origin https://github.com/bd01010/flirtframe-model-build.git

# Push
git branch -M main
git push -u origin main

echo "✅ Code pushed successfully!"
echo ""
echo "📍 Next: Go to https://github.com/bd01010/flirtframe-model-build/actions"