# Setting Up GitHub Secrets for FlirtFrame

## Steps to Add Your OpenAI API Key

1. Go to your repository: https://github.com/bd01010/flirtframe-app

2. Click on **Settings** (in the repository navigation)

3. In the left sidebar, click **Secrets and variables** → **Actions**

4. Click **New repository secret**

5. Add the following secret:
   - **Name**: `OPENAI_API_KEY`
   - **Value**: Your actual OpenAI API key (starts with `sk-proj-...`)

6. Click **Add secret**

## Verifying the Build

After adding the secret:

1. Go to the **Actions** tab in your repository
2. You should see the "iOS Build" workflow
3. It will run automatically when you push code
4. Check if the build succeeds

## What This Does

- Keeps your API key secure (never exposed in code)
- Allows GitHub Actions to build your app
- Injects the API key only during the build process
- The key is never stored in your repository

## Next Steps

Once the build succeeds, you'll be ready to:
1. Get an Apple Developer account ($99/year)
2. Add code signing certificates
3. Deploy to TestFlight

For now, the free GitHub Actions build proves your app works!