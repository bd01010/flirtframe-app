import Foundation
import UIKit
import Vision

struct AnalysisResult {
    let elements: [DetectedElement]
    let context: PhotoContext
    let detailedDescription: String
    let timestamp: Date = Date()
    let imageId: String = UUID().uuidString
}

struct DetectedElement {
    let type: ElementType
    let confidence: Float
    let boundingBox: CGRect?
    let attributes: [String: Any]
}

enum ElementType {
    case person(age: Int?, gender: String?, details: [String])
    case object(String, details: [String])
    case text(String)
    case scene(String)
    case activity(String)
    case clothing(String, details: [String])
    case emotion(String)
    case aesthetic(String, details: [String]) // lighting, decor, atmosphere
    case cultural(String, details: [String]) // art, symbols, references
}

struct PhotoContext {
    let setting: String // beach, restaurant, gym, etc.
    let timeOfDay: String // morning, afternoon, evening
    let formality: String // casual, formal, sporty
    let mood: String // fun, romantic, adventurous
    let numberOfPeople: Int
    let uniqueDetails: [String] // specific, interesting observations
    let atmosphere: String // energetic, intimate, bustling, etc.
    let notableFeatures: [String] // architectural details, decorations, etc.
}

class PhotoAnalyzer {
    private let visionQueue = DispatchQueue(label: "com.flirtframe.vision", qos: .userInitiated)
    
    func analyze(image: UIImage) async throws -> AnalysisResult {
        return try await withCheckedThrowingContinuation { continuation in
            visionQueue.async {
                do {
                    let result = try self.performAnalysis(on: image)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func performAnalysis(on image: UIImage) throws -> AnalysisResult {
        guard let cgImage = image.cgImage else {
            throw AnalysisError.invalidImage
        }
        
        var elements: [DetectedElement] = []
        
        // Face detection
        let faceElements = try detectFaces(in: cgImage)
        elements.append(contentsOf: faceElements)
        
        // Object detection
        let objectElements = try detectObjects(in: cgImage)
        elements.append(contentsOf: objectElements)
        
        // Scene classification
        let sceneElements = try classifyScene(in: cgImage)
        elements.append(contentsOf: sceneElements)
        
        // Text recognition
        let textElements = try recognizeText(in: cgImage)
        elements.append(contentsOf: textElements)
        
        // Add aesthetic and cultural analysis
        let aestheticElements = analyzeAesthetics(in: image)
        elements.append(contentsOf: aestheticElements)
        
        // Build context from detected elements
        let context = buildContext(from: elements)
        
        // Generate detailed description
        let detailedDescription = generateDetailedDescription(from: elements, context: context)
        
        return AnalysisResult(
            elements: elements,
            context: context,
            detailedDescription: detailedDescription
        )
    }
    
    private func detectFaces(in image: CGImage) throws -> [DetectedElement] {
        var elements: [DetectedElement] = []
        
        let request = VNDetectFaceRectanglesRequest { request, error in
            guard let observations = request.results as? [VNFaceObservation] else { return }
            
            for observation in observations {
                let element = DetectedElement(
                    type: .person(age: nil, gender: nil, details: []),
                    confidence: observation.confidence,
                    boundingBox: observation.boundingBox,
                    attributes: [:]
                )
                elements.append(element)
            }
        }
        
        try performVisionRequest(request, on: image)
        return elements
    }
    
    private func detectObjects(in image: CGImage) throws -> [DetectedElement] {
        var elements: [DetectedElement] = []
        
        // Using Vision framework's built-in object detection
        let request = VNRecognizeAnimalsRequest { request, error in
            guard let observations = request.results as? [VNRecognizedObjectObservation] else { return }
            
            for observation in observations {
                let topLabel = observation.labels.first?.identifier ?? "unknown"
                let element = DetectedElement(
                    type: .object(topLabel, details: []),
                    confidence: observation.confidence,
                    boundingBox: observation.boundingBox,
                    attributes: [:]
                )
                elements.append(element)
            }
        }
        
        try performVisionRequest(request, on: image)
        
        // Additional custom object detection would go here
        // For demo, adding some mock detected objects based on common scenarios
        elements.append(contentsOf: mockObjectDetection())
        
        return elements
    }
    
    private func classifyScene(in image: CGImage) throws -> [DetectedElement] {
        var elements: [DetectedElement] = []
        
        // For demo purposes, using mock scene classification
        // In production, would use a trained CoreML model
        let mockScenes = [
            ("beach", 0.85),
            ("restaurant", 0.72),
            ("gym", 0.68),
            ("outdoors", 0.91),
            ("party", 0.65)
        ]
        
        if let topScene = mockScenes.max(by: { $0.1 < $1.1 }) {
            let element = DetectedElement(
                type: .scene(topScene.0),
                confidence: Float(topScene.1),
                boundingBox: nil,
                attributes: [:]
            )
            elements.append(element)
        }
        
        return elements
    }
    
    private func recognizeText(in image: CGImage) throws -> [DetectedElement] {
        var elements: [DetectedElement] = []
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                
                let element = DetectedElement(
                    type: .text(topCandidate.string),
                    confidence: Float(topCandidate.confidence),
                    boundingBox: observation.boundingBox,
                    attributes: [:]
                )
                elements.append(element)
            }
        }
        
        request.recognitionLevel = .accurate
        try performVisionRequest(request, on: image)
        
        return elements
    }
    
    private func performVisionRequest(_ request: VNRequest, on image: CGImage) throws {
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
    }
    
    private func buildContext(from elements: [DetectedElement]) -> PhotoContext {
        // Analyze elements to determine context
        var setting = "casual"
        var timeOfDay = "day"
        var formality = "casual"
        var mood = "friendly"
        var numberOfPeople = 0
        
        for element in elements {
            switch element.type {
            case .scene(let scene):
                setting = scene
            case .person:
                numberOfPeople += 1
            case .object(let obj, _):
                // Adjust context based on objects
                if obj.contains("wine") || obj.contains("cocktail") {
                    mood = "romantic"
                    timeOfDay = "evening"
                }
            default:
                break
            }
        }
        
        return PhotoContext(
            setting: setting,
            timeOfDay: timeOfDay,
            formality: formality,
            mood: mood,
            numberOfPeople: numberOfPeople,
            uniqueDetails: [],
            atmosphere: mood,
            notableFeatures: []
        )
    }
    
    private func mockObjectDetection() -> [DetectedElement] {
        // Enhanced mock data with detailed observations
        return [
            DetectedElement(
                type: .object("vintage neon sign", details: ["cursive lettering", "pink and blue hues", "slight flicker"]),
                confidence: 0.92,
                boundingBox: CGRect(x: 0.3, y: 0.1, width: 0.4, height: 0.2),
                attributes: ["style": "1950s diner aesthetic"]
            ),
            DetectedElement(
                type: .object("exposed brick wall", details: ["painted layers visible", "industrial chic style"]),
                confidence: 0.88,
                boundingBox: nil,
                attributes: ["texture": "rough", "color": "rust and burgundy"]
            ),
            DetectedElement(
                type: .object("Edison bulb chandelier", details: ["brass fixtures", "varying heights", "warm amber glow"]),
                confidence: 0.85,
                boundingBox: CGRect(x: 0.4, y: 0.0, width: 0.2, height: 0.3),
                attributes: ["style": "industrial vintage"]
            ),
            DetectedElement(
                type: .aesthetic("moody lighting", details: ["dramatic shadows", "warm color temperature", "creates intimate atmosphere"]),
                confidence: 0.90,
                boundingBox: nil,
                attributes: [:]
            )
        ]
    }
    
    private func analyzeAesthetics(in image: UIImage) -> [DetectedElement] {
        // Analyze visual aesthetics and atmosphere
        var elements: [DetectedElement] = []
        
        // Analyze color palette
        if let dominantColors = extractDominantColors(from: image) {
            let colorDetails = dominantColors.map { describeColor($0) }
            elements.append(DetectedElement(
                type: .aesthetic("color palette", details: colorDetails),
                confidence: 0.85,
                boundingBox: nil,
                attributes: ["mood": inferMoodFromColors(dominantColors)]
            ))
        }
        
        // Analyze composition
        let compositionDetails = analyzeComposition(image)
        if !compositionDetails.isEmpty {
            elements.append(DetectedElement(
                type: .aesthetic("composition", details: compositionDetails),
                confidence: 0.80,
                boundingBox: nil,
                attributes: [:]
            ))
        }
        
        return elements
    }
    
    private func generateDetailedDescription(from elements: [DetectedElement], context: PhotoContext) -> String {
        var details: [String] = []
        
        // Collect all interesting details
        for element in elements {
            switch element.type {
            case .object(let name, let objectDetails):
                if !objectDetails.isEmpty {
                    details.append("\(name) with \(objectDetails.joined(separator: ", "))")
                } else {
                    details.append(name)
                }
                
            case .aesthetic(let aspect, let aestheticDetails):
                details.append("\(aspect): \(aestheticDetails.joined(separator: ", "))")
                
            case .cultural(let reference, let culturalDetails):
                details.append("\(reference) featuring \(culturalDetails.joined(separator: ", "))")
                
            case .text(let text):
                details.append("text reading '\(text)'")
                
            case .scene(let scene):
                details.append("\(scene) setting")
                
            default:
                break
            }
        }
        
        // Create a rich, detailed description
        let description = details.joined(separator: "; ")
        return "Scene contains: \(description). The \(context.setting) has a \(context.mood) atmosphere with \(context.formality) styling."
    }
    
    // Helper methods for color analysis
    private func extractDominantColors(from image: UIImage) -> [UIColor]? {
        // Simplified color extraction - in production would use more sophisticated algorithm
        return [
            UIColor(red: 0.8, green: 0.2, blue: 0.4, alpha: 1.0),
            UIColor(red: 0.2, green: 0.3, blue: 0.7, alpha: 1.0),
            UIColor(red: 0.9, green: 0.7, blue: 0.3, alpha: 1.0)
        ]
    }
    
    private func describeColor(_ color: UIColor) -> String {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: nil)
        
        if red > 0.7 && green < 0.3 { return "warm red tones" }
        if blue > 0.7 && red < 0.3 { return "cool blue hues" }
        if green > 0.6 { return "natural greens" }
        return "neutral tones"
    }
    
    private func inferMoodFromColors(_ colors: [UIColor]) -> String {
        // Simple mood inference from color palette
        return "vibrant and energetic"
    }
    
    private func analyzeComposition(_ image: UIImage) -> [String] {
        // Analyze image composition
        return ["asymmetric balance", "strong diagonal lines", "layered depth"]
    }
}

enum AnalysisError: Error {
    case invalidImage
    case visionError(String)
    case modelNotFound
}