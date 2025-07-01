import Foundation
import NaturalLanguage

class ProfileEmbedder {
    private let embeddingDimension = 768
    private let textEmbedder = NLEmbedding.wordEmbedding(for: .english)
    
    func generateEmbeddings(for profile: InstagramProfile) async -> [Float] {
        // Combine all text data from profile
        var textComponents: [String] = []
        
        // Add bio
        if let bio = profile.bio {
            textComponents.append(bio)
        }
        
        // Add captions
        for post in profile.posts {
            if let caption = post.caption {
                textComponents.append(caption)
            }
        }
        
        // Add interests
        textComponents.append(contentsOf: profile.interests)
        
        // Add personality traits
        if let personality = profile.extractedPersonality {
            textComponents.append(contentsOf: personality.dominantTraits)
            textComponents.append(personality.communicationStyle)
            textComponents.append(personality.socialStyle)
        }
        
        // Generate embeddings for each component
        let embeddings = textComponents.map { generateTextEmbedding($0) }
        
        // Average the embeddings
        return averageEmbeddings(embeddings)
    }
    
    func generateEmbeddings(for analysis: AnalysisResult) -> [Float] {
        var textComponents: [String] = []
        
        // Extract text from detected elements
        for element in analysis.elements {
            switch element.type {
            case .scene(let scene):
                textComponents.append("Scene: \(scene)")
            case .object(let obj):
                textComponents.append("Object: \(obj)")
            case .activity(let activity):
                textComponents.append("Activity: \(activity)")
            case .text(let text):
                textComponents.append("Text: \(text)")
            case .clothing(let clothing):
                textComponents.append("Clothing: \(clothing)")
            case .emotion(let emotion):
                textComponents.append("Emotion: \(emotion)")
            default:
                break
            }
        }
        
        // Add context information
        textComponents.append("Setting: \(analysis.context.setting)")
        textComponents.append("Mood: \(analysis.context.mood)")
        textComponents.append("Formality: \(analysis.context.formality)")
        
        // Generate embeddings
        let embeddings = textComponents.map { generateTextEmbedding($0) }
        
        return averageEmbeddings(embeddings)
    }
    
    func calculateSimilarity(profileEmbeddings: [Float], analysisEmbeddings: [Float]) -> Float {
        // Cosine similarity between two embedding vectors
        guard profileEmbeddings.count == analysisEmbeddings.count else { return 0 }
        
        var dotProduct: Float = 0
        var normA: Float = 0
        var normB: Float = 0
        
        for i in 0..<profileEmbeddings.count {
            dotProduct += profileEmbeddings[i] * analysisEmbeddings[i]
            normA += profileEmbeddings[i] * profileEmbeddings[i]
            normB += analysisEmbeddings[i] * analysisEmbeddings[i]
        }
        
        let denominator = sqrt(normA) * sqrt(normB)
        return denominator > 0 ? dotProduct / denominator : 0
    }
    
    func findMatchingElements(profile: InstagramProfile, analysis: AnalysisResult) -> [MatchingElement] {
        var matches: [MatchingElement] = []
        
        // Match interests with detected elements
        for interest in profile.interests {
            for element in analysis.elements {
                if let similarity = calculateElementSimilarity(interest: interest, element: element),
                   similarity > 0.6 {
                    matches.append(MatchingElement(
                        profileElement: interest,
                        analysisElement: elementDescription(element),
                        similarity: similarity,
                        type: .interest
                    ))
                }
            }
        }
        
        // Match personality traits with context
        if let personality = profile.extractedPersonality {
            // Match activity level
            if personality.activityLevel == "High" && 
               (analysis.context.setting.contains("gym") || 
                analysis.context.setting.contains("outdoor") ||
                analysis.context.setting.contains("sport")) {
                matches.append(MatchingElement(
                    profileElement: "Active lifestyle",
                    analysisElement: analysis.context.setting,
                    similarity: 0.8,
                    type: .personality
                ))
            }
            
            // Match social style
            if personality.socialStyle == "Outgoing" && analysis.context.numberOfPeople > 2 {
                matches.append(MatchingElement(
                    profileElement: "Social personality",
                    analysisElement: "Group setting",
                    similarity: 0.75,
                    type: .personality
                ))
            }
        }
        
        return matches.sorted { $0.similarity > $1.similarity }
    }
    
    private func generateTextEmbedding(_ text: String) -> [Float] {
        // Use NLEmbedding for basic word embeddings
        // In production, would use a more sophisticated model
        
        var embedding = Array(repeating: Float(0), count: embeddingDimension)
        
        if let textEmbedder = textEmbedder {
            let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
            var validWords = 0
            
            for word in words {
                if let wordVector = textEmbedder.vector(for: word) {
                    for (i, value) in wordVector.enumerated() {
                        if i < embeddingDimension {
                            embedding[i] += Float(value)
                        }
                    }
                    validWords += 1
                }
            }
            
            // Average the embeddings
            if validWords > 0 {
                for i in 0..<embedding.count {
                    embedding[i] /= Float(validWords)
                }
            }
        }
        
        // Add some randomness for demo purposes
        for i in 0..<embedding.count {
            embedding[i] += Float.random(in: -0.1...0.1)
        }
        
        return embedding
    }
    
    private func averageEmbeddings(_ embeddings: [[Float]]) -> [Float] {
        guard !embeddings.isEmpty else {
            return Array(repeating: 0, count: embeddingDimension)
        }
        
        var result = Array(repeating: Float(0), count: embeddingDimension)
        
        for embedding in embeddings {
            for i in 0..<min(embedding.count, embeddingDimension) {
                result[i] += embedding[i]
            }
        }
        
        let count = Float(embeddings.count)
        for i in 0..<result.count {
            result[i] /= count
        }
        
        return result
    }
    
    private func calculateElementSimilarity(interest: String, element: DetectedElement) -> Float? {
        let elementText = elementDescription(element).lowercased()
        let interestLower = interest.lowercased()
        
        // Simple similarity based on keyword matching
        // In production, would use more sophisticated NLP
        
        if elementText.contains(interestLower) || interestLower.contains(elementText) {
            return 0.9
        }
        
        // Check for related terms
        let relatedTerms: [String: [String]] = [
            "travel": ["beach", "mountain", "city", "adventure", "explore"],
            "fitness": ["gym", "running", "yoga", "sport", "active"],
            "food": ["restaurant", "cooking", "dining", "meal", "chef"],
            "music": ["concert", "instrument", "singing", "festival"],
            "nature": ["outdoor", "hiking", "forest", "park", "wildlife"]
        ]
        
        for (key, terms) in relatedTerms {
            if interestLower.contains(key) {
                for term in terms {
                    if elementText.contains(term) {
                        return 0.7
                    }
                }
            }
        }
        
        return nil
    }
    
    private func elementDescription(_ element: DetectedElement) -> String {
        switch element.type {
        case .scene(let scene):
            return scene
        case .object(let obj):
            return obj
        case .activity(let activity):
            return activity
        case .clothing(let clothing):
            return clothing
        case .text(let text):
            return text
        case .emotion(let emotion):
            return emotion
        case .person:
            return "person"
        }
    }
}

struct MatchingElement {
    let profileElement: String
    let analysisElement: String
    let similarity: Float
    let type: MatchingType
    
    enum MatchingType {
        case interest
        case personality
        case activity
        case style
    }
}