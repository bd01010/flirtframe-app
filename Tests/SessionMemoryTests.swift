import XCTest
@testable import FlirtFrame

class SessionMemoryTests: XCTestCase {
    
    var sessionMemory: SessionMemory!
    
    override func setUp() {
        super.setUp()
        sessionMemory = SessionMemory()
    }
    
    override func tearDown() {
        sessionMemory = nil
        super.tearDown()
    }
    
    // MARK: - Storage Tests
    
    func testStoreAnalysisAndResult() {
        // Create test data
        let analysis = createTestAnalysis()
        let result = createTestOpenerResult(analysisId: analysis.imageId)
        
        // Store the data
        sessionMemory.store(analysis: analysis, result: result)
        
        // Verify it's stored in context
        let context = sessionMemory.getRecentContext()
        
        XCTAssertFalse(context.recentAnalyses.isEmpty)
        XCTAssertFalse(context.recentOpeners.isEmpty)
        XCTAssertEqual(context.recentAnalyses.first?.imageId, analysis.imageId)
    }
    
    func testHistorySizeLimit() {
        // Store more than max history size
        for i in 0..<60 {
            let analysis = createTestAnalysis(id: "analysis_\(i)")
            let result = createTestOpenerResult(analysisId: analysis.imageId)
            sessionMemory.store(analysis: analysis, result: result)
        }
        
        // Verify size is limited
        let context = sessionMemory.getRecentContext()
        XCTAssertLessThanOrEqual(context.recentAnalyses.count, 5)
        XCTAssertLessThanOrEqual(context.recentOpeners.count, 50) // 10 records * 5 openers each
    }
    
    // MARK: - Retrieval Tests
    
    func testGetRecentContext() {
        // Store multiple analyses
        for i in 0..<10 {
            let analysis = createTestAnalysis(id: "analysis_\(i)")
            let result = createTestOpenerResult(analysisId: analysis.imageId)
            sessionMemory.store(analysis: analysis, result: result)
        }
        
        let context = sessionMemory.getRecentContext()
        
        // Verify we get the most recent items
        XCTAssertEqual(context.recentAnalyses.count, 5)
        XCTAssertTrue(context.recentAnalyses.first?.imageId.contains("analysis_9") ?? false)
        XCTAssertNotNil(context.preferences)
        XCTAssertNotNil(context.patterns)
    }
    
    func testFindSimilarAnalyses() {
        // Create analyses with similar elements
        let baseElements = [
            createTestElement(type: .scene("beach")),
            createTestElement(type: .object("surfboard")),
            createTestElement(type: .activity("surfing"))
        ]
        
        let similarAnalysis1 = createTestAnalysis(
            id: "similar_1",
            elements: baseElements
        )
        
        let similarAnalysis2 = createTestAnalysis(
            id: "similar_2",
            elements: baseElements + [createTestElement(type: .object("dog"))]
        )
        
        let differentAnalysis = createTestAnalysis(
            id: "different",
            elements: [
                createTestElement(type: .scene("mountain")),
                createTestElement(type: .activity("hiking"))
            ]
        )
        
        // Store analyses
        for analysis in [similarAnalysis1, similarAnalysis2, differentAnalysis] {
            let result = createTestOpenerResult(analysisId: analysis.imageId)
            sessionMemory.store(analysis: analysis, result: result)
        }
        
        // Find similar to base elements analysis
        let targetAnalysis = createTestAnalysis(elements: baseElements)
        let similar = sessionMemory.findSimilarAnalyses(to: targetAnalysis)
        
        XCTAssertTrue(similar.count >= 2)
        XCTAssertTrue(similar.contains { $0.imageId == "similar_1" })
        XCTAssertTrue(similar.contains { $0.imageId == "similar_2" })
    }
    
    func testGetSuccessfulOpeners() {
        // Store openers with different ratings
        let goodOpener = createTestOpener(id: "good_1", style: .witty)
        let badOpener = createTestOpener(id: "bad_1", style: .witty)
        
        let analysis = createTestAnalysis()
        let result = OpenerResult(
            openers: [goodOpener, badOpener],
            analysisId: analysis.imageId
        )
        
        sessionMemory.store(analysis: analysis, result: result)
        
        // Rate the openers
        sessionMemory.rateOpener("good_1", rating: 5)
        sessionMemory.rateOpener("bad_1", rating: 2)
        
        // Get successful openers
        let successful = sessionMemory.getSuccessfulOpeners()
        
        XCTAssertTrue(successful.contains { $0.id == "good_1" })
        XCTAssertFalse(successful.contains { $0.id == "bad_1" })
    }
    
    func testGetSuccessfulOpenersForStyle() {
        // Store openers with different styles
        let wittyOpener = createTestOpener(id: "witty_1", style: .witty)
        let playfulOpener = createTestOpener(id: "playful_1", style: .playful)
        
        let analysis = createTestAnalysis()
        let result = OpenerResult(
            openers: [wittyOpener, playfulOpener],
            analysisId: analysis.imageId
        )
        
        sessionMemory.store(analysis: analysis, result: result)
        
        // Rate both highly
        sessionMemory.rateOpener("witty_1", rating: 5)
        sessionMemory.rateOpener("playful_1", rating: 4)
        
        // Get successful openers for specific style
        let wittySuccessful = sessionMemory.getSuccessfulOpeners(for: .witty)
        
        XCTAssertTrue(wittySuccessful.contains { $0.id == "witty_1" })
        XCTAssertFalse(wittySuccessful.contains { $0.id == "playful_1" })
    }
    
    // MARK: - User Feedback Tests
    
    func testRateOpener() {
        let opener = createTestOpener(id: "test_opener", style: .question)
        let analysis = createTestAnalysis()
        let result = OpenerResult(openers: [opener], analysisId: analysis.imageId)
        
        sessionMemory.store(analysis: analysis, result: result)
        sessionMemory.rateOpener("test_opener", rating: 4)
        
        // Verify preferences are updated
        let context = sessionMemory.getRecentContext()
        XCTAssertTrue(context.preferences.preferredStyles.contains(.question))
        XCTAssertTrue(context.preferences.successfulOpeners.contains(opener.text))
    }
    
    func testUpdatePreferences() {
        sessionMemory.updatePreferences { preferences in
            preferences.tone = .flirty
            preferences.avoidedTopics = ["politics", "religion"]
            preferences.preferredStyles = [.witty, .playful]
        }
        
        let context = sessionMemory.getRecentContext()
        
        XCTAssertEqual(context.preferences.tone, .flirty)
        XCTAssertEqual(context.preferences.avoidedTopics, ["politics", "religion"])
        XCTAssertEqual(context.preferences.preferredStyles, [.witty, .playful])
    }
    
    // MARK: - Analytics Tests
    
    func testGetSessionStats() {
        // Store some test data
        for i in 0..<5 {
            let analysis = createTestAnalysis(id: "analysis_\(i)")
            let openers = (0..<3).map { j in
                createTestOpener(id: "opener_\(i)_\(j)", style: OpenerStyle.allCases.randomElement()!)
            }
            let result = OpenerResult(openers: openers, analysisId: analysis.imageId)
            
            sessionMemory.store(analysis: analysis, result: result)
            
            // Rate some openers
            if i % 2 == 0 {
                sessionMemory.rateOpener(openers[0].id, rating: 4)
            }
        }
        
        let stats = sessionMemory.getSessionStats()
        
        XCTAssertEqual(stats.totalAnalyses, 5)
        XCTAssertEqual(stats.totalOpeners, 15)
        XCTAssertGreaterThan(stats.averageRating, 0)
        XCTAssertFalse(stats.popularStyles.isEmpty)
        XCTAssertFalse(stats.commonElements.isEmpty)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentAccess() {
        let expectation = self.expectation(description: "Concurrent operations complete")
        expectation.expectedFulfillmentCount = 100
        
        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
        
        for i in 0..<100 {
            queue.async {
                if i % 2 == 0 {
                    // Write operation
                    let analysis = self.createTestAnalysis(id: "concurrent_\(i)")
                    let result = self.createTestOpenerResult(analysisId: analysis.imageId)
                    self.sessionMemory.store(analysis: analysis, result: result)
                } else {
                    // Read operation
                    _ = self.sessionMemory.getRecentContext()
                }
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestAnalysis(
        id: String = UUID().uuidString,
        elements: [DetectedElement]? = nil
    ) -> AnalysisResult {
        let defaultElements = [
            createTestElement(type: .scene("beach")),
            createTestElement(type: .object("surfboard"))
        ]
        
        return AnalysisResult(
            elements: elements ?? defaultElements,
            context: PhotoContext(
                setting: "beach",
                timeOfDay: "afternoon",
                formality: "casual",
                mood: "fun",
                numberOfPeople: 1
            )
        )
    }
    
    private func createTestElement(type: ElementType) -> DetectedElement {
        return DetectedElement(
            type: type,
            confidence: 0.85,
            boundingBox: nil,
            attributes: [:]
        )
    }
    
    private func createTestOpener(
        id: String = UUID().uuidString,
        style: OpenerStyle = .witty
    ) -> Opener {
        return Opener(
            id: id,
            text: "Test opener \(id)",
            style: style,
            confidence: 0.8,
            explanation: "Test explanation",
            tags: ["test"]
        )
    }
    
    private func createTestOpenerResult(analysisId: String) -> OpenerResult {
        let openers = (0..<5).map { i in
            createTestOpener(id: "\(analysisId)_opener_\(i)")
        }
        
        return OpenerResult(
            openers: openers,
            analysisId: analysisId
        )
    }
}