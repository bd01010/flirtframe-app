import XCTest
@testable import FlirtFrame

class SafetyFilterTests: XCTestCase {
    
    var safetyFilter: SafetyFilter!
    
    override func setUp() {
        super.setUp()
        safetyFilter = SafetyFilter()
    }
    
    override func tearDown() {
        safetyFilter = nil
        super.tearDown()
    }
    
    // MARK: - Basic Filtering Tests
    
    func testAppropriateContent() {
        let appropriateMessages = [
            "Love the hiking photo! What trail is that?",
            "Your dog is adorable! What breed?",
            "That sunset view is incredible. Where was this taken?",
            "I see you're into rock climbing. How long have you been climbing?",
            "Great taste in coffee shops! Is that the place on Main Street?"
        ]
        
        for message in appropriateMessages {
            XCTAssertTrue(
                safetyFilter.isAppropriate(message),
                "Message should be appropriate: \(message)"
            )
        }
    }
    
    func testInappropriateContent() {
        let inappropriateMessages = [
            "You look so sexy in that outfit",
            "Hey beautiful, want to hook up?",
            "What's your phone number?",
            "Can I get your address?",
            "You're so hot 🔥"
        ]
        
        for message in inappropriateMessages {
            XCTAssertFalse(
                safetyFilter.isAppropriate(message),
                "Message should be inappropriate: \(message)"
            )
        }
    }
    
    // MARK: - Category Detection Tests
    
    func testOffensiveDetection() {
        let result = safetyFilter.checkSafety("You look stupid in that photo")
        
        XCTAssertFalse(result.isAppropriate)
        XCTAssertEqual(result.category, .offensive)
    }
    
    func testSexualContentDetection() {
        let result = safetyFilter.checkSafety("You have a sexy smile")
        
        XCTAssertFalse(result.isAppropriate)
        XCTAssertEqual(result.category, .sexual)
    }
    
    func testHarassmentDetection() {
        let result = safetyFilter.checkSafety("I'll follow you home")
        
        XCTAssertFalse(result.isAppropriate)
        XCTAssertEqual(result.category, .harassment)
    }
    
    func testPersonalInfoDetection() {
        let result = safetyFilter.checkSafety("What's your phone number?")
        
        XCTAssertFalse(result.isAppropriate)
        XCTAssertEqual(result.category, .personal)
    }
    
    func testSpamDetection() {
        let result = safetyFilter.checkSafety("Click this link to see more!")
        
        XCTAssertFalse(result.isAppropriate)
        XCTAssertEqual(result.category, .spam)
    }
    
    // MARK: - Context Override Tests
    
    func testPositiveContextOverride() {
        let messages = [
            "That hot chocolate looks delicious!",
            "Love the sexy car in the background",
            "Your body language in this photo shows confidence"
        ]
        
        for message in messages {
            XCTAssertTrue(
                safetyFilter.isAppropriate(message),
                "Context should make message appropriate: \(message)"
            )
        }
    }
    
    // MARK: - Edge Cases
    
    func testExcessiveCapitals() {
        let message = "HELLO THERE NICE PHOTO!!!!"
        let result = safetyFilter.checkSafety(message)
        
        XCTAssertFalse(result.isAppropriate)
        XCTAssertEqual(result.category, .spam)
    }
    
    func testExcessiveEmojis() {
        let message = "Hey 😍😍😍😍😍😍😍😍"
        let result = safetyFilter.checkSafety(message)
        
        XCTAssertFalse(result.isAppropriate)
        XCTAssertEqual(result.category, .spam)
    }
    
    func testTooShortMessage() {
        let message = "Hi"
        let result = safetyFilter.checkSafety(message)
        
        XCTAssertFalse(result.isAppropriate)
        XCTAssertEqual(result.category, .spam)
    }
    
    func testTooLongMessage() {
        let message = String(repeating: "a", count: 301)
        let result = safetyFilter.checkSafety(message)
        
        XCTAssertFalse(result.isAppropriate)
        XCTAssertEqual(result.category, .spam)
    }
    
    // MARK: - Sanitization Tests
    
    func testSanitizeURLs() {
        let input = "Check out my profile at https://example.com/profile"
        let expected = "Check out my profile at [link]"
        
        XCTAssertEqual(safetyFilter.sanitize(input), expected)
    }
    
    func testSanitizeEmails() {
        let input = "Email me at test@example.com for more info"
        let expected = "Email me at [email] for more info"
        
        XCTAssertEqual(safetyFilter.sanitize(input), expected)
    }
    
    func testSanitizePhoneNumbers() {
        let inputs = [
            "Call me at 555-123-4567",
            "My number is 555.123.4567",
            "Text 5551234567"
        ]
        
        for input in inputs {
            let sanitized = safetyFilter.sanitize(input)
            XCTAssertTrue(
                sanitized.contains("[phone]"),
                "Phone number should be sanitized in: \(input)"
            )
        }
    }
    
    func testSanitizeWhitespace() {
        let input = "Hello    there     how    are    you?"
        let expected = "Hello there how are you?"
        
        XCTAssertEqual(safetyFilter.sanitize(input), expected)
    }
    
    // MARK: - Batch Processing Tests
    
    func testFilterMultipleOpeners() {
        let openers = [
            "Great hiking photo! What trail?",
            "You're so hot",
            "Love the scenery in this shot",
            "What's your number?",
            "That dog is adorable!"
        ]
        
        let filtered = safetyFilter.filterOpeners(openers)
        
        XCTAssertEqual(filtered.count, 3)
        XCTAssertTrue(filtered.contains("Great hiking photo! What trail?"))
        XCTAssertTrue(filtered.contains("Love the scenery in this shot"))
        XCTAssertTrue(filtered.contains("That dog is adorable!"))
    }
    
    // MARK: - Safety Score Tests
    
    func testSafetyScores() {
        let testCases: [(String, Float)] = [
            ("Nice photo!", 0.95),
            ("You look stupid", 0.15),
            ("What's your favorite hiking trail?", 0.95)
        ]
        
        for (message, expectedMinScore) in testCases {
            let score = safetyFilter.getSafetyScore(message)
            XCTAssertGreaterThanOrEqual(
                score,
                expectedMinScore - 0.1,
                "Safety score for '\(message)' should be around \(expectedMinScore)"
            )
        }
    }
    
    // MARK: - Performance Tests
    
    func testFilteringPerformance() {
        let testMessage = "This is a perfectly appropriate message about hiking"
        
        measure {
            for _ in 0..<1000 {
                _ = safetyFilter.isAppropriate(testMessage)
            }
        }
    }
}