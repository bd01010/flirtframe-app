import Foundation

struct Configuration {
    static let openAIAPIKey: String = {
        // Try to get from environment variable first (for CI/CD)
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // Try to get from Info.plist (for local development)
        if let infoPlistKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String, !infoPlistKey.isEmpty {
            return infoPlistKey
        }
        
        // Return placeholder for build verification
        return "YOUR_OPENAI_API_KEY_HERE"
    }()
    
    // Add other API keys here as needed
    // static let firebaseAPIKey = "your-firebase-key"
}