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
        
        prompt += buildPhotoContext(from: analysis)
        
        if let profile = profile {
            prompt += buildProfileContext(from: profile, analysis: analysis)
        }
        
        if let style = style {
            prompt += buildStyleGuidelines(for: style)
        } else {
            prompt += """
            
            Create openers in various styles including witty, playful, observational, and question-based approaches.
            """
        }
        
        prompt += buildSessionContext(from: sessionContext)
        
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
        
        context += "\(analysis.detailedDescription)\n\n"
        
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
        var context = "\n\nUSER PROFILE:\n"
        
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
        
        sessionInfo += "Preferred tone: \(context.preferences.tone)\n"
        
        if !context.preferences.avoidedTopics.isEmpty {
            sessionInfo += "Topics to avoid: \(context.preferences.avoidedTopics.joined(separator: ", "))\n"
        }
        
        return sessionInfo
    }
}

// SessionContext and UserSessionPreferences are defined in Models.swift