import Foundation
import NaturalLanguage

class ProfileEmbedder {
    private let embeddingDimension = 768
    private let textEmbedder = NLEmbedding.wordEmbedding(for: .english)
    
    func generateEmbeddings(for profile: InstagramProfile) async -> [Float] {
        var textComponents: [String] = []
        
        if let bio = profile.bio {
            textComponents.append(bio)
        }
        
        for post in profile.posts {
            if let caption = post.caption {
                textComponents.append(caption)
            }
        }
        
        textComponents.append(contentsOf: profile.interests)
        
        if let personality = profile.extractedPersonality {
            textComponents.append(contentsOf: personality.dominantTraits)
            textComponents.append(personality.communicationStyle)
            textComponents.append(personality.socialStyle)
        }
        
        let embeddings = textComponents.map { generateTextEmbedding($0) }
        return averageEmbeddings(embeddings)
    }
    
    func generateEmbeddings(for analysis: AnalysisResult) -> [Float] {
        var textComponents: [String] = []
        
        for element in analysis.elements {
            switch element.type {
            case .scene(let scene):
                textComponents.append("Scene: \(scene)")
            case .object(let obj, _):
                textComponents.append("Object: \(obj)")
            case .text(let text):
                textComponents.append("Text: \(text)")
            case .activity(let activity):
                textComponents.append("Activity: \(activity)")
            case .aesthetic(let aspect, let details):
                textComponents.append("\(aspect): \(details.joined(separator: ", "))")
            default:
                break
            }
        }
        
        let embeddings = textComponents.map { generateTextEmbedding($0) }
        return averageEmbeddings(embeddings)
    }
    
    func findMatchingElements(profile: InstagramProfile, analysis: AnalysisResult) -> [ElementMatch] {
        var matches: [ElementMatch] = []
        
        let profileEmbedding = Task { await generateEmbeddings(for: profile) }
        let analysisEmbedding = generateEmbeddings(for: analysis)
        
        return matches
    }
    
    private func generateTextEmbedding(_ text: String) -> [Float] {
        guard let embedding = textEmbedder else {
            return Array(repeating: 0.0, count: embeddingDimension)
        }
        
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        var vectors: [[Float]] = []
        
        for word in words {
            if let vector = embedding.vector(for: word) {
                vectors.append(vector)
            }
        }
        
        return averageEmbeddings(vectors)
    }
    
    private func averageEmbeddings(_ embeddings: [[Float]]) -> [Float] {
        guard !embeddings.isEmpty else {
            return Array(repeating: 0.0, count: embeddingDimension)
        }
        
        var result = Array(repeating: Float(0.0), count: embeddingDimension)
        
        for embedding in embeddings {
            for (index, value) in embedding.enumerated() where index < embeddingDimension {
                result[index] += value
            }
        }
        
        let count = Float(embeddings.count)
        return result.map { $0 / count }
    }
}

struct ElementMatch {
    let profileElement: String
    let analysisElement: String
    let similarity: Float
}