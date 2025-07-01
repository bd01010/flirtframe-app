import Foundation

class SessionMemory {
    private var recentAnalyses: [(analysis: AnalysisResult, result: OpenerResult)] = []
    private let maxMemorySize = 10
    
    func store(analysis: AnalysisResult, result: OpenerResult) {
        recentAnalyses.append((analysis, result))
        
        if recentAnalyses.count > maxMemorySize {
            recentAnalyses.removeFirst()
        }
    }
    
    func getRecentContext() -> SessionContext {
        let recentOpeners = recentAnalyses.flatMap { $0.result.openers }
        
        return SessionContext(
            preferences: UserSessionPreferences(
                tone: "friendly",
                avoidedTopics: [],
                successfulOpeners: []
            ),
            recentOpeners: Array(recentOpeners.suffix(20))
        )
    }
    
    func findSimilarAnalyses(to analysis: AnalysisResult) -> [AnalysisResult] {
        return recentAnalyses
            .map { $0.analysis }
            .filter { isSimilar($0, to: analysis) }
    }
    
    private func isSimilar(_ analysis1: AnalysisResult, to analysis2: AnalysisResult) -> Bool {
        return analysis1.context.setting == analysis2.context.setting &&
               analysis1.context.mood == analysis2.context.mood
    }
}