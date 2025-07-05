# GitHub Actions Build Setup for FlirtFrame

## Quick Setup (5 minutes)

### 1. Create GitHub Repository
If you haven't already:
```bash
gh repo create flirtframe --private
```

Or manually at: https://github.com/new

### 2. Add Required Secrets
Go to your repository settings:
`https://github.com/YOUR_USERNAME/flirtframe/settings/secrets/actions`

Click "New repository secret" and add:

**Secret 1: GOOGLE_SERVICE_INFO_BASE64**
- Name: `GOOGLE_SERVICE_INFO_BASE64`
- Value: Copy the entire contents of `google_service_info_base64.txt`

**Secret 2: OPENAI_API_KEY**
- Name: `OPENAI_API_KEY`
- Value: Your OpenAI API key from Config.xcconfig

### 3. Push Code to GitHub
```bash
# Add all Firebase files
git add .

# Commit
git commit -m "Add Firebase integration and GitHub Actions workflow"

# Push to GitHub
git push origin main
```

### 4. Watch the Build
1. Go to: `https://github.com/YOUR_USERNAME/flirtframe/actions`
2. You'll see the workflow running
3. Click on it to see live logs
4. Build takes about 10-15 minutes

## What GitHub Actions Will Do:
- ✅ Set up macOS environment
- ✅ Install Xcode
- ✅ Download Firebase SDK packages
- ✅ Build the iOS app
- ✅ Run tests
- ✅ Upload build artifacts

## Build Artifacts
After successful build, you can:
1. Download the built app
2. See test results
3. Check build logs

## Troubleshooting

### If build fails:
1. Check the logs in Actions tab
2. Most common issues:
   - Missing secrets
   - Package resolution timeout (re-run the job)
   - Syntax errors in Swift files

### To re-run:
Click "Re-run all jobs" in the failed workflow

## Next Steps
Once the build succeeds, you can:
1. Add TestFlight deployment
2. Add App Store deployment
3. Add more tests
4. Set up branch protection

Your iOS app will be built automatically on every push!