#!/usr/bin/env bash
set -e

echo "🚀 Triggering FlirtFrame iOS Build..."
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo "Install it with: brew install gh"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub"
    echo "Run: gh auth login"
    exit 1
fi

# Trigger the workflow
echo "📱 Starting build workflow..."
gh workflow run build-flirtframe-app.yml

echo ""
echo "✅ Workflow triggered successfully!"
echo ""
echo "📊 Monitor progress:"
echo "   gh run list --workflow=build-flirtframe-app.yml"
echo ""
echo "📥 Download IPA when complete:"
echo "   gh run download -n FlirtFrame-iOS-Build"
echo ""
echo "🔗 Or visit: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/actions"