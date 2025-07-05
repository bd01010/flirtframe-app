import Foundation
import SwiftUI
import Firebase

extension PhotoAnalyzer {
    func analyzeWithFirebaseTracking(_ image: UIImage) async throws -> PhotoAnalysis {
        let photoId = UUID().uuidString
        let startTime = Date()
        
        let analysis = try await analyze(image)
        
        let analysisTime = Date().timeIntervalSince(startTime)
        let features = analysis.extractFeatures()
        
        FirebaseManager.shared.trackPhotoAnalysis(
            photoId: photoId,
            analysisTime: analysisTime,
            features: features
        )
        
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            Task {
                try? await FirebaseManager.shared.uploadAnalyzedPhoto(imageData, photoId: photoId)
            }
        }
        
        return analysis
    }
}

extension OpenerEngine {
    func generateWithFirebaseTracking(from analysis: PhotoAnalysis, style: OpenerStyle) async throws -> [String] {
        let photoId = UUID().uuidString
        let startTime = Date()
        
        let openers = try await generate(from: analysis, style: style)
        
        let generationTime = Date().timeIntervalSince(startTime)
        
        FirebaseManager.shared.trackOpenerGeneration(
            photoId: photoId,
            count: openers.count,
            generationTime: generationTime,
            style: style.rawValue
        )
        
        let history = GenerationHistory(
            id: UUID().uuidString,
            photoId: photoId,
            openers: openers,
            style: style.rawValue,
            timestamp: Date()
        )
        
        Task {
            try? await FirebaseManager.shared.saveGenerationHistory(history)
        }
        
        return openers
    }
}

extension PhotoAnalysis {
    func extractFeatures() -> [String] {
        var features: [String] = []
        
        if hasPeople {
            features.append("people")
        }
        
        features.append(contentsOf: objects.map { $0.label })
        features.append(contentsOf: scenes.map { $0.label })
        
        if !text.isEmpty {
            features.append("text")
        }
        
        return features
    }
}

struct FirebaseEnvironmentKey: EnvironmentKey {
    static let defaultValue = FirebaseManager.shared
}

extension EnvironmentValues {
    var firebaseManager: FirebaseManager {
        get { self[FirebaseEnvironmentKey.self] }
        set { self[FirebaseEnvironmentKey.self] = newValue }
    }
}

struct FirebaseAnalyticsModifier: ViewModifier {
    let screenName: String
    let screenClass: String?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                FirebaseManager.shared.logEvent("screen_view", parameters: [
                    "screen_name": screenName,
                    "screen_class": screenClass ?? String(describing: type(of: content))
                ])
            }
    }
}

extension View {
    func trackScreen(_ name: String, class screenClass: String? = nil) -> some View {
        modifier(FirebaseAnalyticsModifier(screenName: name, screenClass: screenClass))
    }
    
    func trackEvent(_ eventName: String, parameters: [String: Any]? = nil) {
        FirebaseManager.shared.logEvent(eventName, parameters: parameters)
    }
}

extension OpenerStyle {
    var firebaseValue: String {
        switch self {
        case .witty:
            return "witty"
        case .romantic:
            return "romantic"
        case .funny:
            return "funny"
        case .thoughtful:
            return "thoughtful"
        default:
            return "other"
        }
    }
}