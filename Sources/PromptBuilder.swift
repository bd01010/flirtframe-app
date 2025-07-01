import Foundation

class PromptBuilder {
    
    func buildPrompt(
        analysis: AnalysisResult,
        profile: InstagramProfile?,
        style: OpenerStyle?,
        sessionContext: SessionContext
    ) -> String {
        
        var prompt = """
        You are an expert at creating witty, observational conversation starters for real-world social situations. 
        Your goal is to help people start engaging conversations based on what they observe around them.
        These are for SPOKEN conversations, not text messages.
        
        """
        
        // Add photo analysis context
        prompt += buildPhotoContext(from: analysis)
        
        // Add Instagram profile context if available
        if let profile = profile {
            prompt += buildProfileContext(from: profile, analysis: analysis)
        }
        
        // Add style preferences
        if let style = style {
            prompt += buildStyleGuidelines(for: style)
        } else {
            prompt += """
            
            Create openers in various styles including witty, playful, observational, and question-based approaches.
            """
        }
        
        // Add session context for personalization
        prompt += buildSessionContext(from: sessionContext)
        
        // Add generation instructions
        prompt += """
        
        Generate 5 unique conversation starters based on the detailed observations above. Each opener should:
        1. Reference SPECIFIC visual details from the scene (not generic observations)
        2. Be witty, clever, or insightful - show personality
        3. Feel natural to say out loud in person
        4. Invite engagement without being pushy
        5. Avoid clichés like "nice weather" or "come here often"
        
        Focus on:
        - Unique architectural or design elements
        - Interesting juxtapositions or contrasts
        - Cultural references or artistic details
        - Unusual objects or arrangements
        - The story behind visible elements
        
        Make observations that show you notice details others might miss.
        
        Format each opener on a new line, numbered 1-5.
        """
        
        return prompt
    }
    
    private func buildPhotoContext(from analysis: AnalysisResult) -> String {
        var context = "\nDETAILED SCENE OBSERVATION:\n"
        
        // Use the rich detailed description
        context += "\(analysis.detailedDescription)\n\n"
        
        // Add specific interesting details
        context += "Notable visual elements:\n"
        
        for element in analysis.elements {
            switch element.type {
            case .object(let name, let details):
                if !details.isEmpty {
                    context += "- \(name): \(details.joined(separator: ", "))\n"
                }
            case .aesthetic(let aspect, let details):
                context += "- \(aspect): \(details.joined(separator: ", "))\n"
            case .cultural(let reference, let details):
                context += "- Cultural element: \(reference) with \(details.joined(separator: ", "))\n"
            case .text(let text):
                context += "- Visible text: \"\(text)\"\n"
            default:
                break
            }
        }
        
        // Add atmosphere and unique features
        context += "\nAtmosphere: \(analysis.context.atmosphere)\n"
        if !analysis.context.uniqueDetails.isEmpty {
            context += "Unique details: \(analysis.context.uniqueDetails.joined(separator: ", "))\n"
        }
        if !analysis.context.notableFeatures.isEmpty {
            context += "Notable features: \(analysis.context.notableFeatures.joined(separator: ", "))\n"
        }
        
        return context
    }
    
    private func buildProfileContext(from profile: InstagramProfile, analysis: AnalysisResult) -> String {
        var context = "\n\nINSTAGRAM PROFILE:\n"
        
        context += "Username: @\(profile.username)\n"
        
        if let bio = profile.bio {
            context += "Bio: \(bio)\n"
        }
        
        if !profile.interests.isEmpty {
            context += "Interests: \(profile.interests.joined(separator: ", "))\n"
        }
        
        if let personality = profile.extractedPersonality {
            context += "Personality traits: \(personality.dominantTraits.joined(separator: ", "))\n"
            context += "Communication style: \(personality.communicationStyle)\n"
            context += "Activity level: \(personality.activityLevel)\n"
        }
        
        // Find connections between profile and photo
        let embedder = ProfileEmbedder()
        let matches = embedder.findMatchingElements(profile: profile, analysis: analysis)
        
        if !matches.isEmpty {
            context += "\nConnections found between profile and photo:\n"
            for match in matches.prefix(3) {
                context += "- \(match.profileElement) relates to \(match.analysisElement)\n"
            }
        }
        
        // Add recent post themes
        if !profile.posts.isEmpty {
            let recentThemes = extractThemes(from: profile.posts)
            if !recentThemes.isEmpty {
                context += "\nRecent post themes: \(recentThemes.joined(separator: ", "))\n"
            }
        }
        
        return context
    }
    
    private func buildStyleGuidelines(for style: OpenerStyle) -> String {
        var guidelines = "\n\nSTYLE GUIDELINES:\n"
        
        switch style {
        case .witty:
            guidelines += """
            Create clever, humorous openers that show intelligence and creativity.
            Use wordplay, puns, or unexpected observations.
            Keep it light and avoid being too serious.
            """
            
        case .playful:
            guidelines += """
            Create fun, energetic openers that invite playful banter.
            Use emojis sparingly but effectively.
            Include light teasing or friendly challenges.
            """
            
        case .compliment:
            guidelines += """
            Create genuine, specific compliments that go beyond physical appearance.
            Notice unique details or choices they've made.
            Explain why you find it interesting or admirable.
            """
            
        case .question:
            guidelines += """
            Create open-ended questions that spark curiosity.
            Ask about experiences, opinions, or stories related to the photo.
            Make questions specific and engaging, not generic.
            """
            
        case .observation:
            guidelines += """
            Make specific, insightful observations about the photo or profile.
            Show that you've paid attention to details.
            Connect observations to potential shared interests or experiences.
            """
            
        case .challenge:
            guidelines += """
            Create friendly challenges or playful dares.
            Make it fun and achievable, not intimidating.
            Relate challenges to their apparent interests or skills.
            """
            
        case .callback:
            guidelines += """
            Reference specific details from their profile or photos.
            Create connections between multiple elements you've noticed.
            Show you've taken time to understand their personality.
            """
            
        case .contextual:
            guidelines += """
            Create openers that directly relate to the setting or activity in the photo.
            Imagine yourself in that situation and what you might say.
            Be relevant to the moment captured in the image.
            """
        }
        
        return guidelines
    }
    
    private func buildSessionContext(from context: SessionContext) -> String {
        var sessionInfo = "\n\nUSER PREFERENCES:\n"
        
        // Add successful opener patterns
        if !context.preferences.successfulOpeners.isEmpty {
            sessionInfo += "Previously successful opener styles:\n"
            let patterns = analyzePatterns(from: context.preferences.successfulOpeners)
            for pattern in patterns {
                sessionInfo += "- \(pattern)\n"
            }
        }
        
        // Add tone preference
        sessionInfo += "Preferred tone: \(context.preferences.tone)\n"
        
        // Add topics to avoid
        if !context.preferences.avoidedTopics.isEmpty {
            sessionInfo += "Topics to avoid: \(context.preferences.avoidedTopics.joined(separator: ", "))\n"
        }
        
        // Add recent themes to ensure variety
        if !context.recentOpeners.isEmpty {
            let recentThemes = extractThemes(from: context.recentOpeners)
            sessionInfo += "Recent themes used (vary from these): \(recentThemes.joined(separator: ", "))\n"
        }
        
        return sessionInfo
    }
    
    private func describeElement(_ element: DetectedElement) -> String {
        switch element.type {
        case .person(let age, let gender, let details):
            var description = "Person"
            if let age = age {
                description += " (appears \(age))"
            }
            if let gender = gender {
                description += " \(gender)"
            }
            if !details.isEmpty {
                description += " - \(details.joined(separator: ", "))"
            }
            return description
            
        case .object(let name, let details):
            if details.isEmpty {
                return "\(name) (object)"
            }
            return "\(name) with \(details.joined(separator: ", "))"
            
        case .scene(let name):
            return "\(name) setting"
            
        case .activity(let name):
            return "\(name) activity"
            
        case .text(let content):
            return "Text: \"\(content)\""
            
        case .clothing(let item, let details):
            if details.isEmpty {
                return "\(item) (clothing)"
            }
            return "\(item) - \(details.joined(separator: ", "))"
            
        case .emotion(let emotion):
            return "\(emotion) expression"
            
        case .aesthetic(let aspect, let details):
            return "\(aspect): \(details.joined(separator: ", "))"
            
        case .cultural(let reference, let details):
            return "\(reference) with \(details.joined(separator: ", "))"
        }
    }
    
    private func extractThemes(from posts: [InstagramPost]) -> [String] {
        var themes = Set<String>()
        
        for post in posts.prefix(5) {
            if let caption = post.caption?.lowercased() {
                // Extract themes based on keywords
                let themeKeywords: [String: String] = [
                    "travel": "travel",
                    "adventure": "adventure",
                    "food": "foodie",
                    "fitness": "fitness",
                    "nature": "nature",
                    "music": "music",
                    "art": "art",
                    "coffee": "coffee",
                    "wine": "wine",
                    "beach": "beach",
                    "mountain": "outdoors"
                ]
                
                for (keyword, theme) in themeKeywords {
                    if caption.contains(keyword) {
                        themes.insert(theme)
                    }
                }
            }
        }
        
        return Array(themes).prefix(3).map { $0 }
    }
    
    private func extractThemes(from openers: [Opener]) -> [String] {
        var themes = Set<String>()
        
        for opener in openers {
            themes.formUnion(opener.tags)
        }
        
        return Array(themes).prefix(5).map { $0 }
    }
    
    private func analyzePatterns(from successfulOpeners: [String]) -> [String] {
        var patterns: [String] = []
        
        // Analyze length
        let avgLength = successfulOpeners.map { $0.count }.reduce(0, +) / max(successfulOpeners.count, 1)
        if avgLength < 50 {
            patterns.append("Short and punchy (under 50 characters)")
        } else if avgLength > 100 {
            patterns.append("Detailed and conversational")
        }
        
        // Analyze question usage
        let questionCount = successfulOpeners.filter { $0.contains("?") }.count
        if questionCount > successfulOpeners.count / 2 {
            patterns.append("Questions that encourage responses")
        }
        
        // Analyze emoji usage
        let emojiCount = successfulOpeners.filter { $0.contains(where: { $0.isEmoji }) }.count
        if emojiCount > successfulOpeners.count / 2 {
            patterns.append("Strategic emoji usage")
        }
        
        return patterns
    }
}