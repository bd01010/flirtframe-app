import XCTest
@testable import FlirtFrame

class PromptBuilderTests: XCTestCase {
    
    var promptBuilder: PromptBuilder!
    
    override func setUp() {
        super.setUp()
        promptBuilder = PromptBuilder()
    }
    
    override func tearDown() {
        promptBuilder = nil
        super.tearDown()
    }
    
    // MARK: - Basic Prompt Building Tests
    
    func testBuildBasicPrompt() {
        let analysis = createTestAnalysis()
        let sessionContext = createEmptySessionContext()
        
        let prompt = promptBuilder.buildPrompt(
            analysis: analysis,
            profile: nil,
            style: nil,
            sessionContext: sessionContext
        )
        
        // Verify prompt contains essential elements
        XCTAssertTrue(prompt.contains("PHOTO ANALYSIS"))
        XCTAssertTrue(prompt.contains("beach"))
        XCTAssertTrue(prompt.contains("casual"))
        XCTAssertTrue(prompt.contains("Generate 5 unique conversation openers"))
    }
    
    func testPromptWithStyle() {
        let analysis = createTestAnalysis()
        let sessionContext = createEmptySessionContext()
        
        let prompt = promptBuilder.buildPrompt(
            analysis: analysis,
            profile: nil,
            style: .witty,
            sessionContext: sessionContext
        )
        
        // Verify style guidelines are included
        XCTAssertTrue(prompt.contains("STYLE GUIDELINES"))
        XCTAssertTrue(prompt.contains("clever"))
        XCTAssertTrue(prompt.contains("humorous"))
        XCTAssertTrue(prompt.contains("wordplay"))
    }
    
    func testPromptWithProfile() {
        let analysis = createTestAnalysis()
        let profile = createTestProfile()
        let sessionContext = createEmptySessionContext()
        
        let prompt = promptBuilder.buildPrompt(
            analysis: analysis,
            profile: profile,
            style: nil,
            sessionContext: sessionContext
        )
        
        // Verify profile information is included
        XCTAssertTrue(prompt.contains("INSTAGRAM PROFILE"))
        XCTAssertTrue(prompt.contains("@testuser"))
        XCTAssertTrue(prompt.contains("Travel enthusiast"))
        XCTAssertTrue(prompt.contains("Interests:"))
    }
    
    // MARK: - Context Building Tests
    
    func testPhotoContextInclusion() {
        let elements = [
            DetectedElement(
                type: .scene("restaurant"),
                confidence: 0.9,
                boundingBox: nil,
                attributes: [:]
            ),
            DetectedElement(
                type: .object("wine glass"),
                confidence: 0.85,
                boundingBox: nil,
                attributes: [:]
            ),
            DetectedElement(
                type: .text("Date Night"),
                confidence: 0.8,
                boundingBox: nil,
                attributes: [:]
            )
        ]
        
        let analysis = AnalysisResult(
            elements: elements,
            context: PhotoContext(
                setting: "restaurant",
                timeOfDay: "evening",
                formality: "formal",
                mood: "romantic",
                numberOfPeople: 2
            )
        )
        
        let prompt = promptBuilder.buildPrompt(
            analysis: analysis,
            profile: nil,
            style: nil,
            sessionContext: createEmptySessionContext()
        )
        
        // Verify all elements are included
        XCTAssertTrue(prompt.contains("restaurant"))
        XCTAssertTrue(prompt.contains("wine glass"))
        XCTAssertTrue(prompt.contains("Date Night"))
        XCTAssertTrue(prompt.contains("romantic"))
        XCTAssertTrue(prompt.contains("2 person(s)"))
    }
    
    func testProfileConnectionsIdentified() {
        // Create analysis with hiking elements
        let analysis = AnalysisResult(
            elements: [
                DetectedElement(
                    type: .scene("mountain"),
                    confidence: 0.9,
                    boundingBox: nil,
                    attributes: [:]
                ),
                DetectedElement(
                    type: .activity("hiking"),
                    confidence: 0.85,
                    boundingBox: nil,
                    attributes: [:]
                )
            ],
            context: PhotoContext(
                setting: "outdoors",
                timeOfDay: "morning",
                formality: "casual",
                mood: "adventurous",
                numberOfPeople: 1
            )
        )
        
        // Create profile with hiking interest
        let profile = InstagramProfile(
            username: "hikingfan",
            bio: "Mountain lover | Trail runner | Weekend adventurer",
            posts: [],
            profilePictureURL: nil,
            followersCount: 1000,
            interests: ["Hiking", "Mountains", "Nature"],
            extractedPersonality: PersonalityTraits(
                dominantTraits: ["Adventurous", "Active"],
                interests: ["Hiking", "Outdoors"],
                communicationStyle: "Enthusiastic",
                activityLevel: "High",
                socialStyle: "Outgoing"
            )
        )
        
        let prompt = promptBuilder.buildPrompt(
            analysis: analysis,
            profile: profile,
            style: nil,
            sessionContext: createEmptySessionContext()
        )
        
        // Verify connections are identified
        XCTAssertTrue(prompt.contains("Connections found"))
        XCTAssertTrue(prompt.contains("Activity level: High"))
    }
    
    // MARK: - Style Guidelines Tests
    
    func testAllStyleGuidelines() {
        let analysis = createTestAnalysis()
        let sessionContext = createEmptySessionContext()
        
        for style in OpenerStyle.allCases {
            let prompt = promptBuilder.buildPrompt(
                analysis: analysis,
                profile: nil,
                style: style,
                sessionContext: sessionContext
            )
            
            XCTAssertTrue(
                prompt.contains("STYLE GUIDELINES"),
                "Style guidelines missing for \(style)"
            )
            
            // Verify style-specific content
            switch style {
            case .witty:
                XCTAssertTrue(prompt.contains("clever"))
            case .playful:
                XCTAssertTrue(prompt.contains("fun"))
            case .compliment:
                XCTAssertTrue(prompt.contains("genuine"))
            case .question:
                XCTAssertTrue(prompt.contains("open-ended"))
            case .observation:
                XCTAssertTrue(prompt.contains("insightful"))
            case .challenge:
                XCTAssertTrue(prompt.contains("friendly challenges"))
            case .callback:
                XCTAssertTrue(prompt.contains("reference"))
            case .contextual:
                XCTAssertTrue(prompt.contains("relate"))
            }
        }
    }
    
    // MARK: - Session Context Tests
    
    func testSessionPreferencesIncluded() {
        let analysis = createTestAnalysis()
        
        var preferences = SessionMemory.UserPreferences()
        preferences.tone = .flirty
        preferences.avoidedTopics = ["politics", "religion"]
        preferences.successfulOpeners = ["Great hiking photo!"]
        
        let sessionContext = SessionContext(
            recentAnalyses: [],
            recentOpeners: [],
            preferences: preferences,
            patterns: [:]
        )
        
        let prompt = promptBuilder.buildPrompt(
            analysis: analysis,
            profile: nil,
            style: nil,
            sessionContext: sessionContext
        )
        
        XCTAssertTrue(prompt.contains("USER PREFERENCES"))
        XCTAssertTrue(prompt.contains("Preferred tone: flirty"))
        XCTAssertTrue(prompt.contains("Topics to avoid: politics, religion"))
    }
    
    func testRecentThemesForVariety() {
        let analysis = createTestAnalysis()
        
        let recentOpeners = [
            Opener(
                text: "Beach vibes!",
                style: .observation,
                confidence: 0.8,
                explanation: nil,
                tags: ["beach", "summer"]
            ),
            Opener(
                text: "Surfing looks fun!",
                style: .question,
                confidence: 0.8,
                explanation: nil,
                tags: ["surfing", "sport"]
            )
        ]
        
        let sessionContext = SessionContext(
            recentAnalyses: [],
            recentOpeners: recentOpeners,
            preferences: SessionMemory.UserPreferences(),
            patterns: [:]
        )
        
        let prompt = promptBuilder.buildPrompt(
            analysis: analysis,
            profile: nil,
            style: nil,
            sessionContext: sessionContext
        )
        
        XCTAssertTrue(prompt.contains("Recent themes used (vary from these)"))
    }
    
    // MARK: - Edge Cases
    
    func testEmptyAnalysis() {
        let analysis = AnalysisResult(
            elements: [],
            context: PhotoContext(
                setting: "unknown",
                timeOfDay: "unknown",
                formality: "casual",
                mood: "neutral",
                numberOfPeople: 0
            )
        )
        
        let prompt = promptBuilder.buildPrompt(
            analysis: analysis,
            profile: nil,
            style: nil,
            sessionContext: createEmptySessionContext()
        )
        
        // Should still generate a valid prompt
        XCTAssertTrue(prompt.contains("PHOTO ANALYSIS"))
        XCTAssertTrue(prompt.contains("Generate 5 unique"))
    }
    
    func testVeryLongBio() {
        let longBio = String(repeating: "Travel ", count: 100)
        let profile = InstagramProfile(
            username: "testuser",
            bio: longBio,
            posts: [],
            profilePictureURL: nil,
            followersCount: 1000,
            interests: [],
            extractedPersonality: nil
        )
        
        let prompt = promptBuilder.buildPrompt(
            analysis: createTestAnalysis(),
            profile: profile,
            style: nil,
            sessionContext: createEmptySessionContext()
        )
        
        // Should include bio but maintain reasonable prompt length
        XCTAssertTrue(prompt.contains("Bio:"))
        XCTAssertLessThan(prompt.count, 10000)
    }
    
    // MARK: - Helper Methods
    
    private func createTestAnalysis() -> AnalysisResult {
        return AnalysisResult(
            elements: [
                DetectedElement(
                    type: .scene("beach"),
                    confidence: 0.9,
                    boundingBox: nil,
                    attributes: [:]
                ),
                DetectedElement(
                    type: .object("surfboard"),
                    confidence: 0.85,
                    boundingBox: nil,
                    attributes: [:]
                )
            ],
            context: PhotoContext(
                setting: "beach",
                timeOfDay: "afternoon",
                formality: "casual",
                mood: "fun",
                numberOfPeople: 1
            )
        )
    }
    
    private func createTestProfile() -> InstagramProfile {
        return InstagramProfile(
            username: "testuser",
            bio: "Travel enthusiast | Coffee lover | Dog parent 🐕",
            posts: [
                InstagramPost(
                    imageURL: URL(string: "https://example.com/post1.jpg")!,
                    caption: "Beach day! #summer #beach",
                    likes: 100,
                    timestamp: Date(),
                    hashtags: ["#summer", "#beach"]
                )
            ],
            profilePictureURL: URL(string: "https://example.com/profile.jpg"),
            followersCount: 1000,
            interests: ["Travel", "Coffee", "Dogs"],
            extractedPersonality: PersonalityTraits(
                dominantTraits: ["Adventurous", "Social"],
                interests: ["Travel", "Coffee"],
                communicationStyle: "Casual",
                activityLevel: "Moderate",
                socialStyle: "Outgoing"
            )
        )
    }
    
    private func createEmptySessionContext() -> SessionContext {
        return SessionContext(
            recentAnalyses: [],
            recentOpeners: [],
            preferences: SessionMemory.UserPreferences(),
            patterns: [:]
        )
    }
}