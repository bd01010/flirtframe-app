import Foundation
import UIKit

struct InstagramProfile {
    let username: String
    let bio: String?
    let posts: [InstagramPost]
    let profilePictureURL: URL?
    let followersCount: Int?
    let interests: [String]
    let extractedPersonality: PersonalityTraits?
}

struct InstagramPost {
    let imageURL: URL
    let caption: String?
    let likes: Int
    let timestamp: Date
    let hashtags: [String]
}

struct PersonalityTraits {
    let dominantTraits: [String]
    let interests: [String]
    let communicationStyle: String
    let activityLevel: String
    let socialStyle: String
}

class InstagramManager {
    private let profileEmbedder = ProfileEmbedder()
    private let session = URLSession.shared
    
    // Mock implementation for demo
    // In production, this would use Instagram's Basic Display API
    
    func fetchProfile(username: String) async throws -> InstagramProfile {
        // For demo purposes, return mock data
        // In production, this would make API calls to Instagram
        
        let mockBio = generateMockBio(for: username)
        let mockPosts = generateMockPosts(for: username)
        let interests = extractInterests(from: mockBio, posts: mockPosts)
        let personality = analyzePersonality(bio: mockBio, posts: mockPosts)
        
        return InstagramProfile(
            username: username,
            bio: mockBio,
            posts: mockPosts,
            profilePictureURL: URL(string: "https://example.com/profile/\(username).jpg"),
            followersCount: Int.random(in: 100...10000),
            interests: interests,
            extractedPersonality: personality
        )
    }
    
    func importFromUsername(_ username: String) async throws -> InstagramProfile {
        // Validate username
        guard isValidUsername(username) else {
            throw InstagramError.invalidUsername
        }
        
        // Fetch profile data
        let profile = try await fetchProfile(username: username)
        
        // Generate embeddings for better matching
        let embeddings = await profileEmbedder.generateEmbeddings(for: profile)
        
        // Store in cache for quick access
        cacheProfile(profile, embeddings: embeddings)
        
        return profile
    }
    
    func importFromURL(_ urlString: String) async throws -> InstagramProfile {
        guard let username = extractUsername(from: urlString) else {
            throw InstagramError.invalidURL
        }
        
        return try await importFromUsername(username)
    }
    
    private func generateMockBio(for username: String) -> String {
        let bios = [
            "Travel enthusiast ✈️ | Coffee addict ☕ | Dog lover 🐕",
            "Fitness junkie 💪 | Foodie 🍕 | Adventure seeker 🏔️",
            "Artist 🎨 | Music lover 🎵 | Beach bum 🏖️",
            "Bookworm 📚 | Wine enthusiast 🍷 | Yoga practitioner 🧘‍♀️",
            "Photographer 📸 | Nature lover 🌿 | Weekend warrior 🏃‍♂️"
        ]
        return bios.randomElement() ?? "Living my best life ✨"
    }
    
    private func generateMockPosts(for username: String) -> [InstagramPost] {
        let captions = [
            "Perfect day at the beach 🌊 #beachlife #summer",
            "Coffee and contemplation ☕ #morningvibes #coffeelover",
            "Hiking adventures in the mountains 🏔️ #nature #hiking",
            "Sunset views from my favorite spot 🌅 #goldenhour",
            "Weekend brunch vibes 🥞 #foodie #brunchtime",
            "Exploring new places 🗺️ #travel #wanderlust"
        ]
        
        return (0..<6).map { index in
            InstagramPost(
                imageURL: URL(string: "https://example.com/post/\(username)/\(index).jpg")!,
                caption: captions.randomElement(),
                likes: Int.random(in: 50...5000),
                timestamp: Date().addingTimeInterval(TimeInterval(-index * 86400)),
                hashtags: extractHashtags(from: captions.randomElement() ?? "")
            )
        }
    }
    
    private func extractHashtags(from text: String) -> [String] {
        let pattern = "#\\w+"
        let regex = try? NSRegularExpression(pattern: pattern)
        let matches = regex?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? []
        
        return matches.compactMap {
            Range($0.range, in: text).map { String(text[$0]) }
        }
    }
    
    private func extractInterests(from bio: String?, posts: [InstagramPost]) -> [String] {
        var interests = Set<String>()
        
        // Extract from bio
        if let bio = bio?.lowercased() {
            let interestKeywords = [
                "travel", "fitness", "food", "music", "art", "photography",
                "nature", "beach", "hiking", "yoga", "coffee", "wine",
                "reading", "cooking", "fashion", "sports", "gaming", "tech"
            ]
            
            for keyword in interestKeywords {
                if bio.contains(keyword) {
                    interests.insert(keyword.capitalized)
                }
            }
        }
        
        // Extract from hashtags
        for post in posts {
            for hashtag in post.hashtags {
                let cleaned = hashtag.replacingOccurrences(of: "#", with: "").capitalized
                interests.insert(cleaned)
            }
        }
        
        return Array(interests).prefix(5).map { $0 }
    }
    
    private func analyzePersonality(bio: String?, posts: [InstagramPost]) -> PersonalityTraits {
        // Simplified personality analysis based on content
        var traits: [String] = []
        var activityLevel = "Moderate"
        var socialStyle = "Balanced"
        var communicationStyle = "Casual"
        
        if let bio = bio?.lowercased() {
            if bio.contains("adventure") || bio.contains("travel") {
                traits.append("Adventurous")
                activityLevel = "High"
            }
            if bio.contains("fitness") || bio.contains("gym") {
                traits.append("Active")
                activityLevel = "High"
            }
            if bio.contains("art") || bio.contains("creative") {
                traits.append("Creative")
            }
            if bio.contains("foodie") || bio.contains("chef") {
                traits.append("Culinary Enthusiast")
            }
        }
        
        // Analyze posting frequency
        if posts.count > 5 {
            socialStyle = "Outgoing"
        }
        
        // Analyze caption style
        let avgCaptionLength = posts.compactMap { $0.caption?.count }.reduce(0, +) / max(posts.count, 1)
        if avgCaptionLength > 50 {
            communicationStyle = "Expressive"
        } else if avgCaptionLength < 20 {
            communicationStyle = "Minimalist"
        }
        
        if traits.isEmpty {
            traits = ["Friendly", "Social"]
        }
        
        return PersonalityTraits(
            dominantTraits: traits,
            interests: extractInterests(from: bio, posts: posts),
            communicationStyle: communicationStyle,
            activityLevel: activityLevel,
            socialStyle: socialStyle
        )
    }
    
    private func isValidUsername(_ username: String) -> Bool {
        let pattern = "^[a-zA-Z0-9_.]+$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: username.utf16.count)
        return regex?.firstMatch(in: username, options: [], range: range) != nil
    }
    
    private func extractUsername(from urlString: String) -> String? {
        // Extract username from Instagram URL
        // Formats: instagram.com/username or instagram.com/p/postid
        
        guard let url = URL(string: urlString) else { return nil }
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        if pathComponents.count > 0 && pathComponents[0] != "p" {
            return pathComponents[0]
        }
        
        return nil
    }
    
    private func cacheProfile(_ profile: InstagramProfile, embeddings: [Float]) {
        // Cache implementation
        // Store in UserDefaults or local database for quick access
    }
}

enum InstagramError: Error {
    case invalidUsername
    case invalidURL
    case networkError
    case apiError(String)
    case rateLimited
}