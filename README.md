# FlirtFrame

AI-powered conversation openers from photos - Turn any photo into engaging conversation starters for dating apps.

## Overview

FlirtFrame uses advanced computer vision and natural language processing to analyze photos and generate personalized, contextual conversation openers. Perfect for breaking the ice on dating apps with creative, relevant messages.

## Features

- **Smart Photo Analysis**: Advanced AI analyzes photos to understand context, activities, and settings
- **Personalized Openers**: Generate 5-8 unique conversation starters tailored to each photo
- **Multiple Styles**: Choose from witty, playful, complimentary, or question-based approaches  
- **Instagram Integration**: Import profiles for even more personalized openers
- **Safety First**: Built-in content filtering ensures appropriate and respectful messages
- **History & Favorites**: Save your best openers and track what works

## Technical Stack

- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Minimum iOS**: 16.0
- **AI/ML**: Vision framework, Core ML, Natural Language
- **Backend**: OpenAI API for text generation
- **Analytics**: Firebase Analytics
- **Payments**: StoreKit 2

## Project Structure

```
FlirtFrame/
├── Sources/
│   ├── FlirtFrameApp.swift          # App entry point
│   ├── ContentView.swift            # Main navigation
│   ├── OnboardingView.swift         # First-time user experience
│   ├── CameraScreen.swift           # Camera capture interface
│   ├── PhotoAnalyzer.swift          # Vision framework integration
│   ├── OpenerEngine.swift           # AI opener generation
│   ├── OpenerResultView.swift       # Results display
│   ├── HistoryView.swift            # Saved openers
│   ├── SafetyFilter.swift           # Content moderation
│   ├── Models/                      # Data models
│   └── ...
├── Resources/
│   ├── Assets.xcassets              # Images and colors
│   └── TinyDemoLines.json           # Demo content
├── Tests/
│   ├── PhotoAnalyzerTests.swift
│   ├── OpenerEngineTests.swift
│   └── ...
└── FlirtFrame.xcodeproj/
```

## Setup Instructions

1. Clone the repository
2. Open `FlirtFrame.xcodeproj` in Xcode 15+
3. Add your OpenAI API key to `Config.xcconfig`:
   ```
   OPENAI_API_KEY = your_api_key_here
   ```
4. Configure Firebase by adding `GoogleService-Info.plist`
5. Build and run on iOS 16+ device or simulator

## Key Components

### PhotoAnalyzer
Processes images using Vision framework to detect:
- People and faces
- Objects and activities  
- Scene classification
- Text recognition
- Contextual elements

### OpenerEngine
Generates conversation starters by:
- Building context from photo analysis
- Incorporating Instagram profile data
- Applying style preferences
- Ensuring safety and appropriateness

### SafetyFilter
Ensures all generated content is:
- Respectful and appropriate
- Free from harassment or explicit content
- Compliant with platform guidelines

## Testing

Run the test suite:
```bash
xcodebuild test -scheme FlirtFrame -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Privacy & Security

- Photos are processed on-device when possible
- No permanent storage of user photos
- End-to-end encryption for cloud features
- Minimal data collection
- Full privacy controls

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

Copyright © 2024 FlirtFrame. All rights reserved.

This is proprietary software. Unauthorized copying, modification, or distribution is strictly prohibited.