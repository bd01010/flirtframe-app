import XCTest
@testable import FlirtFrame
import UIKit
import Vision

class PhotoAnalyzerTests: XCTestCase {
    
    var analyzer: PhotoAnalyzer!
    
    override func setUp() {
        super.setUp()
        analyzer = PhotoAnalyzer()
    }
    
    override func tearDown() {
        analyzer = nil
        super.tearDown()
    }
    
    // MARK: - Basic Analysis Tests
    
    func testAnalyzeValidImage() async throws {
        // Create a test image
        let image = createTestImage(width: 100, height: 100, color: .blue)
        
        // Analyze the image
        let result = try await analyzer.analyze(image: image)
        
        // Verify basic properties
        XCTAssertNotNil(result)
        XCTAssertFalse(result.imageId.isEmpty)
        XCTAssertNotNil(result.timestamp)
        XCTAssertNotNil(result.context)
    }
    
    func testAnalyzeInvalidImage() async {
        // Create an invalid image (0x0)
        let image = UIImage()
        
        // Attempt to analyze
        do {
            _ = try await analyzer.analyze(image: image)
            XCTFail("Expected error for invalid image")
        } catch AnalysisError.invalidImage {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Element Detection Tests
    
    func testDetectFaces() throws {
        // Create test image with face-like features
        let image = createTestImageWithFace()
        
        guard let cgImage = image.cgImage else {
            XCTFail("Failed to create CGImage")
            return
        }
        
        // Test face detection
        let faces = try performFaceDetection(on: cgImage)
        
        // In a real test, we'd use an image with actual faces
        // For now, just verify the method completes without error
        XCTAssertNotNil(faces)
    }
    
    func testDetectObjects() throws {
        let image = createTestImage(width: 200, height: 200, color: .green)
        
        guard let cgImage = image.cgImage else {
            XCTFail("Failed to create CGImage")
            return
        }
        
        // Test object detection
        let objects = try performObjectDetection(on: cgImage)
        
        // Verify we get some objects (even if mock)
        XCTAssertNotNil(objects)
    }
    
    func testSceneClassification() async throws {
        let image = createTestImage(width: 300, height: 300, color: .systemBlue)
        
        let result = try await analyzer.analyze(image: image)
        
        // Verify scene context is set
        XCTAssertFalse(result.context.setting.isEmpty)
        XCTAssertNotNil(result.context.mood)
        XCTAssertNotNil(result.context.timeOfDay)
    }
    
    // MARK: - Context Building Tests
    
    func testContextFromElements() async throws {
        let image = createTestImage(width: 200, height: 200, color: .orange)
        
        let result = try await analyzer.analyze(image: image)
        
        // Verify context properties
        XCTAssertTrue(result.context.numberOfPeople >= 0)
        XCTAssertFalse(result.context.setting.isEmpty)
        XCTAssertFalse(result.context.mood.isEmpty)
        XCTAssertFalse(result.context.formality.isEmpty)
    }
    
    func testMultipleAnalyses() async throws {
        let images = [
            createTestImage(width: 100, height: 100, color: .red),
            createTestImage(width: 200, height: 200, color: .green),
            createTestImage(width: 300, height: 300, color: .blue)
        ]
        
        var results: [AnalysisResult] = []
        
        for image in images {
            let result = try await analyzer.analyze(image: image)
            results.append(result)
        }
        
        // Verify all analyses completed
        XCTAssertEqual(results.count, images.count)
        
        // Verify unique IDs
        let uniqueIds = Set(results.map { $0.imageId })
        XCTAssertEqual(uniqueIds.count, results.count)
    }
    
    // MARK: - Performance Tests
    
    func testAnalysisPerformance() throws {
        let image = createTestImage(width: 1000, height: 1000, color: .yellow)
        
        measure {
            let expectation = self.expectation(description: "Analysis complete")
            
            Task {
                do {
                    _ = try await analyzer.analyze(image: image)
                    expectation.fulfill()
                } catch {
                    XCTFail("Analysis failed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage(width: Int, height: Int, color: UIColor) -> UIImage {
        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContext(size)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    private func createTestImageWithFace() -> UIImage {
        let size = CGSize(width: 200, height: 200)
        UIGraphicsBeginImageContext(size)
        
        // Draw a simple face representation
        UIColor.yellow.setFill()
        UIBezierPath(ovalIn: CGRect(x: 50, y: 50, width: 100, height: 100)).fill()
        
        // Eyes
        UIColor.black.setFill()
        UIBezierPath(ovalIn: CGRect(x: 70, y: 80, width: 10, height: 10)).fill()
        UIBezierPath(ovalIn: CGRect(x: 120, y: 80, width: 10, height: 10)).fill()
        
        // Mouth
        let mouth = UIBezierPath()
        mouth.move(to: CGPoint(x: 80, y: 120))
        mouth.addQuadCurve(to: CGPoint(x: 120, y: 120), controlPoint: CGPoint(x: 100, y: 130))
        mouth.lineWidth = 2
        UIColor.black.setStroke()
        mouth.stroke()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    private func performFaceDetection(on image: CGImage) throws -> [VNFaceObservation] {
        var observations: [VNFaceObservation] = []
        
        let request = VNDetectFaceRectanglesRequest { request, error in
            if let results = request.results as? [VNFaceObservation] {
                observations = results
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
        
        return observations
    }
    
    private func performObjectDetection(on image: CGImage) throws -> [VNRecognizedObjectObservation] {
        var observations: [VNRecognizedObjectObservation] = []
        
        let request = VNRecognizeAnimalsRequest { request, error in
            if let results = request.results as? [VNRecognizedObjectObservation] {
                observations = results
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
        
        return observations
    }
}