import Foundation

struct OpenerResult {
    let openers: [Opener]
    let analysisId: String
    let generatedAt: Date = Date()
}

struct Opener {
    let id: String = UUID().uuidString
    let text: String
    let style: OpenerStyle
    let confidence: Float
    let explanation: String?
    let tags: [String]
}

enum OpenerStyle: String, CaseIterable {
    case witty = "Witty"
    case playful = "Playful"
    case compliment = "Compliment"
    case question = "Question"
    case observation = "Observation"
    case challenge = "Challenge"
    case callback = "Callback"
    case contextual = "Contextual"
}

class OpenerEngine {
    private let promptBuilder = PromptBuilder()
    private let safetyFilter = SafetyFilter()
    private let sessionMemory = SessionMemory()
    private let apiClient: OpenAIClient
    
    init(apiKey: String) {
        self.apiClient = OpenAIClient(apiKey: apiKey)
    }
    
    func generateOpeners(
        from analysis: AnalysisResult,
        profile: InstagramProfile? = nil,
        style: OpenerStyle? = nil,
        count: Int = 5
    ) async throws -> OpenerResult {
        
        // Build prompt from analysis and profile
        let prompt = promptBuilder.buildPrompt(
            analysis: analysis,
            profile: profile,
            style: style,
            sessionContext: sessionMemory.getRecentContext()
        )
        
        // Generate openers using AI
        let response = try await apiClient.generateCompletion(
            prompt: prompt,
            maxTokens: 500,
            temperature: 0.8
        )
        
        // Parse response into openers
        var openers = parseOpeners(from: response)
        
        // Apply safety filters
        openers = openers.compactMap { opener in
            if safetyFilter.isAppropriate(opener.text) {
                return opener
            }
            return nil
        }
        
        // Ensure we have enough openers
        while openers.count < count {
            let additionalResponse = try await apiClient.generateCompletion(
                prompt: "Generate one more unique opener in the same style.",
                maxTokens: 100,
                temperature: 0.9
            )
            
            if let newOpener = parseOpeners(from: additionalResponse).first,
               safetyFilter.isAppropriate(newOpener.text) {
                openers.append(newOpener)
            }
        }
        
        // Store in session memory
        let result = OpenerResult(
            openers: Array(openers.prefix(count)),
            analysisId: analysis.imageId
        )
        
        sessionMemory.store(analysis: analysis, result: result)
        
        return result
    }
    
    private func parseOpeners(from response: String) -> [Opener] {
        // Parse AI response into structured openers
        // This is a simplified version - real implementation would be more robust
        
        let lines = response.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return lines.compactMap { line in
            // Remove numbering if present
            let text = line
                .replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
            
            guard !text.isEmpty else { return nil }
            
            // Determine style based on content
            let style = detectStyle(from: text)
            
            // Generate explanation
            let explanation = generateExplanation(for: text, style: style)
            
            // Extract tags
            let tags = extractTags(from: text)
            
            return Opener(
                text: text,
                style: style,
                confidence: 0.85, // Mock confidence
                explanation: explanation,
                tags: tags
            )
        }
    }
    
    private func detectStyle(from text: String) -> OpenerStyle {
        let lowercased = text.lowercased()
        
        if lowercased.contains("?") {
            return .question
        } else if lowercased.contains("bet") || lowercased.contains("challenge") {
            return .challenge
        } else if lowercased.contains("noticed") || lowercased.contains("see") {
            return .observation
        } else if lowercased.contains("cute") || lowercased.contains("beautiful") || lowercased.contains("nice") {
            return .compliment
        } else if lowercased.contains("😂") || lowercased.contains("😏") || lowercased.contains("joke") {
            return .playful
        } else {
            return .witty
        }
    }
    
    private func generateExplanation(for text: String, style: OpenerStyle) -> String {
        switch style {
        case .witty:
            return "This opener uses humor and wordplay to create an engaging first message"
        case .playful:
            return "A light-hearted approach that invites fun banter"
        case .compliment:
            return "A genuine compliment that stands out from generic messages"
        case .question:
            return "An open-ended question that encourages a response"
        case .observation:
            return "Shows you paid attention to details in their photo"
        case .challenge:
            return "A playful challenge that creates immediate engagement"
        case .callback:
            return "References something specific from their profile for personalization"
        case .contextual:
            return "Relates to the specific context or setting of the photo"
        }
    }
    
    private func extractTags(from text: String) -> [String] {
        var tags: [String] = []
        
        // Extract activity/context tags
        let activities = ["surfing", "hiking", "traveling", "cooking", "reading", "fitness", "music", "art"]
        for activity in activities {
            if text.lowercased().contains(activity) {
                tags.append(activity)
            }
        }
        
        // Add emoji tag if present
        if text.contains(where: { $0.isEmoji }) {
            tags.append("emoji")
        }
        
        // Add length tag
        if text.count < 50 {
            tags.append("short")
        } else if text.count > 100 {
            tags.append("long")
        } else {
            tags.append("medium")
        }
        
        return tags
    }
}

// OpenAI API Client
class OpenAIClient {
    private let apiKey: String
    private let session = URLSession.shared
    private let baseURL = "https://api.openai.com/v1"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateCompletion(
        prompt: String,
        maxTokens: Int = 150,
        temperature: Double = 0.7
    ) async throws -> String {
        
        let url = URL(string: "\(baseURL)/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo-instruct",
            "prompt": prompt,
            "max_tokens": maxTokens,
            "temperature": temperature
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await session.data(for: request)
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let text = firstChoice["text"] as? String {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        throw OpenerEngineError.apiError("Failed to generate completion")
    }
}

enum OpenerEngineError: Error {
    case apiError(String)
    case parsingError
    case noOpenersGenerated
}

// Emoji detection extension
extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }
}