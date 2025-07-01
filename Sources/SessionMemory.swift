import Foundation

class SessionMemory {
    private var analysisHistory: [AnalysisRecord] = []
    private var openerHistory: [OpenerRecord] = []
    private var userPreferences: UserPreferences = UserPreferences()
    private let maxHistorySize = 50
    
    private let queue = DispatchQueue(label: "com.flirtframe.sessionmemory", attributes: .concurrent)
    
    struct AnalysisRecord {
        let analysis: AnalysisResult
        let timestamp: Date
        let photoHash: String
    }
    
    struct OpenerRecord {
        let analysisId: String
        let openers: [Opener]
        let timestamp: Date
        let profile: InstagramProfile?
        let userRating: Int?
    }
    
    struct UserPreferences {
        var preferredStyles: [OpenerStyle] = []
        var avoidedTopics: [String] = []
        var successfulOpeners: [String] = []
        var tone: TonePreference = .balanced
    }
    
    enum TonePreference {
        case professional
        case casual
        case flirty
        case funny
        case balanced
    }
    
    // MARK: - Storage Methods
    
    func store(analysis: AnalysisResult, result: OpenerResult) {
        queue.async(flags: .barrier) {
            // Store analysis
            let photoHash = self.generatePhotoHash(from: analysis)
            let analysisRecord = AnalysisRecord(
                analysis: analysis,
                timestamp: Date(),
                photoHash: photoHash
            )
            self.analysisHistory.append(analysisRecord)
            
            // Store openers
            let openerRecord = OpenerRecord(
                analysisId: analysis.imageId,
                openers: result.openers,
                timestamp: Date(),
                profile: nil,
                userRating: nil
            )
            self.openerHistory.append(openerRecord)
            
            // Maintain size limit
            self.pruneHistoryIfNeeded()
        }
    }
    
    // MARK: - Retrieval Methods
    
    func getRecentContext() -> SessionContext {
        queue.sync {
            let recentAnalyses = Array(analysisHistory.suffix(5))
            let recentOpeners = Array(openerHistory.suffix(10))
            
            return SessionContext(
                recentAnalyses: recentAnalyses.map { $0.analysis },
                recentOpeners: recentOpeners.flatMap { $0.openers },
                preferences: userPreferences,
                patterns: extractPatterns()
            )
        }
    }
    
    func findSimilarAnalyses(to analysis: AnalysisResult) -> [AnalysisResult] {
        queue.sync {
            let targetElements = Set(analysis.elements.map { elementKey(for: $0) })
            
            return analysisHistory
                .map { record in
                    let recordElements = Set(record.analysis.elements.map { elementKey(for: $0) })
                    let similarity = jacardSimilarity(targetElements, recordElements)
                    return (record.analysis, similarity)
                }
                .filter { $0.1 > 0.5 }
                .sorted { $0.1 > $1.1 }
                .prefix(3)
                .map { $0.0 }
        }
    }
    
    func getSuccessfulOpeners(for style: OpenerStyle? = nil) -> [Opener] {
        queue.sync {
            openerHistory
                .filter { $0.userRating ?? 0 >= 4 }
                .flatMap { $0.openers }
                .filter { opener in
                    style == nil || opener.style == style
                }
                .prefix(10)
                .map { $0 }
        }
    }
    
    // MARK: - User Feedback
    
    func rateOpener(_ openerId: String, rating: Int) {
        queue.async(flags: .barrier) {
            for (index, record) in self.openerHistory.enumerated() {
                if record.openers.contains(where: { $0.id == openerId }) {
                    var updatedRecord = record
                    updatedRecord.userRating = rating
                    self.openerHistory[index] = updatedRecord
                    
                    // Update preferences based on rating
                    if rating >= 4 {
                        if let opener = record.openers.first(where: { $0.id == openerId }) {
                            self.userPreferences.successfulOpeners.append(opener.text)
                            if !self.userPreferences.preferredStyles.contains(opener.style) {
                                self.userPreferences.preferredStyles.append(opener.style)
                            }
                        }
                    }
                    break
                }
            }
        }
    }
    
    func updatePreferences(_ update: (inout UserPreferences) -> Void) {
        queue.async(flags: .barrier) {
            update(&self.userPreferences)
        }
    }
    
    // MARK: - Analytics
    
    func getSessionStats() -> SessionStats {
        queue.sync {
            let totalAnalyses = analysisHistory.count
            let totalOpeners = openerHistory.flatMap { $0.openers }.count
            let averageRating = calculateAverageRating()
            let popularStyles = calculatePopularStyles()
            let commonElements = calculateCommonElements()
            
            return SessionStats(
                totalAnalyses: totalAnalyses,
                totalOpeners: totalOpeners,
                averageRating: averageRating,
                popularStyles: popularStyles,
                commonElements: commonElements
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func generatePhotoHash(from analysis: AnalysisResult) -> String {
        let elementStrings = analysis.elements.map { elementKey(for: $0) }.sorted()
        return elementStrings.joined(separator: "|").hash.description
    }
    
    private func elementKey(for element: DetectedElement) -> String {
        switch element.type {
        case .person(let age, let gender):
            return "person:\(age ?? 0):\(gender ?? "unknown")"
        case .object(let name):
            return "object:\(name)"
        case .scene(let name):
            return "scene:\(name)"
        case .text(let content):
            return "text:\(content.prefix(20))"
        case .activity(let name):
            return "activity:\(name)"
        case .clothing(let name):
            return "clothing:\(name)"
        case .emotion(let name):
            return "emotion:\(name)"
        }
    }
    
    private func jacardSimilarity<T: Hashable>(_ set1: Set<T>, _ set2: Set<T>) -> Double {
        let intersection = set1.intersection(set2).count
        let union = set1.union(set2).count
        return union > 0 ? Double(intersection) / Double(union) : 0.0
    }
    
    private func extractPatterns() -> [String: Any] {
        var patterns: [String: Any] = [:]
        
        // Extract common themes
        let allElements = analysisHistory.flatMap { $0.analysis.elements }
        let elementTypes = allElements.map { elementKey(for: $0) }
        
        let frequency = Dictionary(elementTypes.map { ($0, 1) }, uniquingKeysWith: +)
        patterns["commonElements"] = frequency.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
        
        // Extract successful patterns
        let successfulOpeners = openerHistory
            .filter { ($0.userRating ?? 0) >= 4 }
            .flatMap { $0.openers }
        
        patterns["successfulStyles"] = Dictionary(
            successfulOpeners.map { ($0.style.rawValue, 1) },
            uniquingKeysWith: +
        )
        
        return patterns
    }
    
    private func pruneHistoryIfNeeded() {
        if analysisHistory.count > maxHistorySize {
            analysisHistory.removeFirst(analysisHistory.count - maxHistorySize)
        }
        if openerHistory.count > maxHistorySize {
            openerHistory.removeFirst(openerHistory.count - maxHistorySize)
        }
    }
    
    private func calculateAverageRating() -> Double {
        let ratings = openerHistory.compactMap { $0.userRating }
        guard !ratings.isEmpty else { return 0 }
        return Double(ratings.reduce(0, +)) / Double(ratings.count)
    }
    
    private func calculatePopularStyles() -> [OpenerStyle] {
        let allOpeners = openerHistory.flatMap { $0.openers }
        let styleCounts = Dictionary(allOpeners.map { ($0.style, 1) }, uniquingKeysWith: +)
        return styleCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
    }
    
    private func calculateCommonElements() -> [String] {
        let allElements = analysisHistory.flatMap { $0.analysis.elements }
        let elementCounts = Dictionary(allElements.map { (elementKey(for: $0), 1) }, uniquingKeysWith: +)
        return elementCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
    }
}

// MARK: - Supporting Types

struct SessionContext {
    let recentAnalyses: [AnalysisResult]
    let recentOpeners: [Opener]
    let preferences: SessionMemory.UserPreferences
    let patterns: [String: Any]
}

struct SessionStats {
    let totalAnalyses: Int
    let totalOpeners: Int
    let averageRating: Double
    let popularStyles: [OpenerStyle]
    let commonElements: [String]
}