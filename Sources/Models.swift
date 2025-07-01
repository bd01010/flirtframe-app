import Foundation
import UIKit

// MARK: - Session Data for History
struct SessionData: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let openers: [Opener]
    let photoData: Data?
    let context: AnalysisContext?
    
    init(timestamp: Date = Date(), openers: [Opener], photoData: Data? = nil, context: AnalysisContext? = nil) {
        self.timestamp = timestamp
        self.openers = openers
        self.photoData = photoData
        self.context = context
    }
}

// MARK: - Photo Analysis Types
struct AnalysisResult {
    let imageId: String
    let elements: [Element]
    let context: AnalysisContext
    let colors: [UIColor]
    let composition: CompositionAnalysis
    let metadata: AnalysisMetadata
}

struct AnalysisContext {
    let setting: String
    let mood: String
    let timeOfDay: String
    let activity: String?
    let peopleCount: Int
    let objects: [String]
}

struct CompositionAnalysis {
    let rule: String
    let balance: String
    let focusPoints: [CGPoint]
}

struct AnalysisMetadata {
    let timestamp: Date
    let processingTime: TimeInterval
    let confidence: Float
}

struct Element {
    let type: ElementType
    let description: String
    let confidence: Float
    let bounds: CGRect?
}

enum ElementType {
    case person(age: String?, gender: String?, attributes: [String])
    case object(category: String, details: [String])
    case text(content: String, language: String?)
    case aesthetic(String, details: [String])
    case cultural(String, details: [String])
    case emotion(String, intensity: Float)
    case activity(String, participants: Int)
    case brand(name: String, confidence: Float)
    case landmark(name: String, location: String?)
}

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