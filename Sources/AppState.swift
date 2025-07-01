import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var analysisCount = 0
    @Published var isPremium = false
    @Published var userPreferences = UserPreferences()
    @Published var sessionHistory: [SessionData] = []
    @Published var hasCompletedOnboarding = false
    
    let openerEngine: OpenerEngine
    private var feedbackHistory: [String: Bool] = [:] // openerId: isPositive
    
    init() {
        self.openerEngine = OpenerEngine(apiKey: Configuration.openAIAPIKey)
        loadUserPreferences()
        loadSessionHistory()
        loadOnboardingStatus()
    }
    
    func trackAnalysis() {
        analysisCount += 1
    }
    
    func canAnalyze() -> Bool {
        return isPremium || analysisCount < 3
    }
    
    func recordFeedback(openerId: String, isPositive: Bool) {
        feedbackHistory[openerId] = isPositive
        
        // Update user preferences based on feedback
        // This helps the AI learn what styles the user prefers
        saveUserPreferences()
    }
    
    private func loadUserPreferences() {
        // Load from UserDefaults for now
        if let data = UserDefaults.standard.data(forKey: "userPreferences"),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            self.userPreferences = preferences
        }
    }
    
    private func saveUserPreferences() {
        if let data = try? JSONEncoder().encode(userPreferences) {
            UserDefaults.standard.set(data, forKey: "userPreferences")
        }
    }
    
    // Session History Management
    func addSession(_ session: SessionData) {
        sessionHistory.insert(session, at: 0)
        // Keep only last 50 sessions
        if sessionHistory.count > 50 {
            sessionHistory.removeLast()
        }
        saveSessionHistory()
    }
    
    func deleteSession(at offsets: IndexSet) {
        sessionHistory.remove(atOffsets: offsets)
        saveSessionHistory()
    }
    
    private func saveSessionHistory() {
        // TODO: Implement persistence when SessionData is made Codable
        // For now, session history is only kept in memory
    }
    
    private func loadSessionHistory() {
        // TODO: Implement persistence when SessionData is made Codable
        // For now, session history is only kept in memory
    }
    
    // Onboarding Management
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    private func loadOnboardingStatus() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}

struct UserPreferences: Codable {
    var preferredStyles: [OpenerStyle] = OpenerStyle.allCases
    var communicationStyle: String = "balanced" // witty, sincere, bold, etc.
    var interests: [String] = []
    var avoidTopics: [String] = []
}