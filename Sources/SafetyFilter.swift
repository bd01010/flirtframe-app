import Foundation

class SafetyFilter {
    
    private let inappropriatePatterns = [
        "explicit", "nsfw", "adult", "nude"
    ]
    
    private let harassmentPatterns = [
        "hate", "threat", "violence", "discriminat"
    ]
    
    func isAppropriate(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        
        for pattern in inappropriatePatterns {
            if lowercased.contains(pattern) {
                return false
            }
        }
        
        for pattern in harassmentPatterns {
            if lowercased.contains(pattern) {
                return false
            }
        }
        
        return true
    }
    
    func filterOpeners(_ openers: [Opener]) -> [Opener] {
        return openers.filter { isAppropriate($0.text) }
    }
}