# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FlirtFrame is an iOS application that generates AI-powered conversation openers from photos for dating apps. It uses computer vision to analyze photos and natural language processing to create personalized conversation starters.

## Development Commands

### Building & Running
```bash
# Open project in Xcode
open FlirtFrame.xcodeproj

# Build from command line
xcodebuild -scheme FlirtFrame -configuration Debug

# Run tests
xcodebuild test -scheme FlirtFrame -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test
xcodebuild test -scheme FlirtFrame -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:FlirtFrameTests/PhotoAnalyzerTests
```

### Fastlane Commands
```bash
# Install dependencies
bundle install

# Run tests
bundle exec fastlane test

# Deploy beta to TestFlight
bundle exec fastlane beta

# Deploy to App Store
bundle exec fastlane release

# Generate screenshots
bundle exec fastlane screenshots

# Sync certificates
bundle exec fastlane certs

# Bump version (patch/minor/major)
bundle exec fastlane bump type:patch
```

### MLX Model Management
```bash
# Models are pre-downloaded and stored in:
# Models/text-generation/gemma-3n-E4B-it-lm-4bit/    # 4-bit quantized Gemma for text generation
# Models/vision-language/gemma-3n-E4B-it-bf16/       # BF16 Gemma for vision-language tasks

# Setup MCP servers and environment
./setup2.sh
```

## Architecture Overview

### Key Components

1. **PhotoAnalyzer** (`Sources/PhotoAnalyzer.swift`)
   - Integrates with Vision framework for image analysis
   - Detects people, objects, scenes, and text in photos
   - Returns structured analysis data for opener generation

2. **OpenerEngine** (`Sources/OpenerEngine.swift`)
   - Core AI logic for generating conversation starters
   - Integrates with OpenAI API for text generation
   - Applies style preferences and safety filtering

3. **SafetyFilter** (`Sources/SafetyFilter.swift`)
   - Content moderation system ensuring appropriate messages
   - Filters out harassment, explicit content, and platform violations

4. **Instagram Integration**
   - Optional profile import for personalization
   - Handled through InstagramProfileImporter

### Data Flow

1. User captures/selects photo → CameraScreen
2. Photo analyzed via PhotoAnalyzer using Vision framework
3. Analysis + user preferences sent to OpenerEngine
4. OpenerEngine generates openers via OpenAI API
5. SafetyFilter validates content
6. Results displayed in OpenerResultView
7. User can save favorites to History (Core Data)

### Configuration Requirements

- **OpenAI API Key**: Must be set in `Config.xcconfig` as `OPENAI_API_KEY`
- **Firebase**: Requires `GoogleService-Info.plist` for analytics
- **App Store Connect**: Configured via Fastlane Match for certificates

### Testing Strategy

- Unit tests for core components (PhotoAnalyzer, OpenerEngine, SafetyFilter)
- UI tests for critical user flows
- Integration tests for API interactions
- All tests must pass before deployment

### CI/CD Pipeline

- GitHub Actions workflow for Core ML model building
- Fastlane for automated TestFlight and App Store deployments
- Automatic version bumping and git tagging on release
- Slack notifications for build status

### Model Architecture

The app uses Google's Gemma models in MLX format (Apple's machine learning framework):
- **gemma-3n-E4B-it-lm-4bit**: 4-bit quantized Gemma model for text generation
  - Located in `Models/text-generation/`
  - Uses mlx-lm library for inference
- **gemma-3n-E4B-it-bf16**: BF16 precision Gemma model for vision-language tasks
  - Located in `Models/vision-language/`
  - Supports image-text-to-text pipeline
  - Uses mlx-vlm library for inference

These models are from the mlx-community on Hugging Face, optimized for Apple Silicon. The shift from Core ML to MLX provides better performance and more modern capabilities for both text generation and vision understanding tasks.