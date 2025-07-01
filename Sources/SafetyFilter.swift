import Foundation

class SafetyFilter {
    
    // Categories of inappropriate content
    private let inappropriatePatterns: [SafetyCategory: [String]] = [
        .offensive: [
            "\\bhate\\b", "\\bstupid\\b", "\\bidiot\\b", "\\bugly\\b",
            "\\bloser\\b", "\\bdumb\\b", "\\bfat\\b", "\\bskinny\\b"
        ],
        .sexual: [
            "\\bsexy\\b", "\\bhot\\b", "\\bnaked\\b", "\\bbed\\b",
            "\\bstrip\\b", "\\bhook\\s*up\\b", "\\bbooty\\b", "\\bbody\\b"
        ],
        .harassment: [
            "\\bstalk\\b", "\\bcreep\\b", "\\bfollow\\b.*home",
            "\\balone\\b.*with\\s*me", "\\bget\\s*you\\b"
        ],
        .personal: [
            "\\bphone\\b", "\\bnumber\\b", "\\baddress\\b",
            "\\bwhere.*live\\b", "\\bmeet\\b.*now\\b"
        ],
        .spam: [
            "\\bclick\\b.*link", "\\bcheck\\s*out\\b.*profile",
            "\\bfollow\\s*me\\b", "\\bDM\\s*me\\b", "\\bsubscribe\\b"
        ]
    ]
    
    // Positive patterns that should be allowed
    private let positiveContexts: [String] = [
        "\\bhot\\s*(coffee|chocolate|tea|weather|summer)\\b",
        "\\bsexy\\s*(car|outfit|confidence)\\b",
        "\\bbody\\s*(language|positive|building)\\b",
        "\\bmeet\\s*(new\\s*people|friends|at\\s*the)\\b"
    ]
    
    enum SafetyCategory {
        case offensive
        case sexual
        case harassment
        case personal
        case spam
    }
    
    struct SafetyCheckResult {
        let isAppropriate: Bool
        let category: SafetyCategory?
        let confidence: Float
        let reason: String?
    }
    
    func isAppropriate(_ text: String) -> Bool {
        let result = checkSafety(text)
        return result.isAppropriate
    }
    
    func checkSafety(_ text: String) -> SafetyCheckResult {
        let lowercasedText = text.lowercased()
        
        // First check if it contains positive context that might override
        for pattern in positiveContexts {
            if lowercasedText.range(of: pattern, options: .regularExpression) != nil {
                return SafetyCheckResult(
                    isAppropriate: true,
                    category: nil,
                    confidence: 0.9,
                    reason: "Contains appropriate context"
                )
            }
        }
        
        // Check against inappropriate patterns
        for (category, patterns) in inappropriatePatterns {
            for pattern in patterns {
                if lowercasedText.range(of: pattern, options: .regularExpression) != nil {
                    return SafetyCheckResult(
                        isAppropriate: false,
                        category: category,
                        confidence: 0.85,
                        reason: "Contains potentially inappropriate content"
                    )
                }
            }
        }
        
        // Additional checks
        if containsExcessiveCapitals(text) {
            return SafetyCheckResult(
                isAppropriate: false,
                category: .spam,
                confidence: 0.7,
                reason: "Excessive use of capital letters"
            )
        }
        
        if containsExcessiveEmojis(text) {
            return SafetyCheckResult(
                isAppropriate: false,
                category: .spam,
                confidence: 0.6,
                reason: "Excessive use of emojis"
            )
        }
        
        if isTooShort(text) || isTooLong(text) {
            return SafetyCheckResult(
                isAppropriate: false,
                category: .spam,
                confidence: 0.65,
                reason: "Message length outside acceptable range"
            )
        }
        
        return SafetyCheckResult(
            isAppropriate: true,
            category: nil,
            confidence: 0.95,
            reason: nil
        )
    }
    
    func sanitize(_ text: String) -> String {
        var sanitized = text
        
        // Remove extra whitespace
        sanitized = sanitized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        sanitized = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove URLs
        sanitized = sanitized.replacingOccurrences(
            of: "(https?://[^\\s]+)",
            with: "[link]",
            options: .regularExpression
        )
        
        // Remove email addresses
        sanitized = sanitized.replacingOccurrences(
            of: "\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b",
            with: "[email]",
            options: .regularExpression
        )
        
        // Remove phone numbers
        sanitized = sanitized.replacingOccurrences(
            of: "\\b\\d{3}[-.]?\\d{3}[-.]?\\d{4}\\b",
            with: "[phone]",
            options: .regularExpression
        )
        
        return sanitized
    }
    
    private func containsExcessiveCapitals(_ text: String) -> Bool {
        let capitalCount = text.filter { $0.isUppercase }.count
        let totalLetters = text.filter { $0.isLetter }.count
        
        guard totalLetters > 0 else { return false }
        
        let capitalRatio = Float(capitalCount) / Float(totalLetters)
        return capitalRatio > 0.5 && totalLetters > 10
    }
    
    private func containsExcessiveEmojis(_ text: String) -> Bool {
        let emojiCount = text.filter { $0.isEmoji }.count
        let totalChars = text.count
        
        guard totalChars > 0 else { return false }
        
        let emojiRatio = Float(emojiCount) / Float(totalChars)
        return emojiRatio > 0.3 || emojiCount > 5
    }
    
    private func isTooShort(_ text: String) -> Bool {
        return text.count < 10
    }
    
    private func isTooLong(_ text: String) -> Bool {
        return text.count > 300
    }
    
    // Batch checking for multiple openers
    func filterOpeners(_ openers: [String]) -> [String] {
        return openers.filter { isAppropriate($0) }
    }
    
    // Get safety score for analytics
    func getSafetyScore(_ text: String) -> Float {
        let result = checkSafety(text)
        return result.isAppropriate ? result.confidence : 1.0 - result.confidence
    }
}