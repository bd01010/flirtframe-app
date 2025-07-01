import Foundation
import UIKit

// MARK: - Session Data for History
struct SessionData: Identifiable {
    let id = UUID()
    let timestamp: Date
    let openers: [Opener]
    let photoData: Data?
    let context: PhotoContext?
    
    init(timestamp: Date = Date(), openers: [Opener], photoData: Data? = nil, context: PhotoContext? = nil) {
        self.timestamp = timestamp
        self.openers = openers
        self.photoData = photoData
        self.context = context
    }
}

// MARK: - Photo Analysis Types
// Note: AnalysisResult, DetectedElement, ElementType, and PhotoContext are defined in PhotoAnalyzer.swift

// MARK: - Instagram Integration
struct InstagramProfile {
    let username: String
    let bio: String?
    let interests: [String]
    let embeddings: [Float]?
    let posts: [InstagramPost]
}

struct InstagramPost {
    let imageUrl: String?
    let caption: String?
    let likes: Int
    let timestamp: Date
}

// MARK: - Session Context
struct SessionContext {
    let preferences: UserSessionPreferences
    let recentOpeners: [Opener]
}

struct UserSessionPreferences {
    let tone: String
    let avoidedTopics: [String]
    let successfulOpeners: [String]
}

// MARK: - Extensions for Identifiable
extension Opener: Identifiable {}