//
//  GameCategory.swift
//  Party Games
//
//  Created by Mohamed Abdelmagid on 8/8/25.
//

import Foundation
import SwiftData

@Model
final class GameCategory {
    /// Unique identifier for the category
    @Attribute(.unique) var id: UUID
    
    /// Display name of the category (e.g., "Truth or Dare", "Would You Rather")
    var name: String
    
    /// Icon name for UI display
    var iconName: String
    
    /// Total number of cards in this category
    var cardCount: Int
    
    /// Creation date for sorting purposes
    var createdAt: Date
    
    /// Whether this category is currently active/available
    var isActive: Bool
    
    /// Whether this category requires premium subscription
    var isPremium: Bool
    
    /// Relationship to game cards
    @Relationship(deleteRule: .cascade, inverse: \GameCard.category)
    var cards: [GameCard] = []
    
    /// Relationship to game sessions
    @Relationship(deleteRule: .cascade, inverse: \GameSession.category)
    var sessions: [GameSession] = []
    
    init(name: String, iconName: String, cardCount: Int = 0, isPremium: Bool = false) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.cardCount = cardCount
        self.createdAt = Date()
        self.isActive = true
        self.isPremium = isPremium
    }
    
    /// Computed property to get actual card count from relationship
    var actualCardCount: Int {
        cards.count
    }
    
    /// Computed property to get active sessions count
    var activeSessionsCount: Int {
        sessions.filter { $0.isActive }.count
    }
    
    /// Get the icon name based on category name if not explicitly set
    static func defaultIconName(for categoryName: String) -> String {
        switch categoryName.lowercased() {
        case "would you rather":
            return "would_you_rather"
        case "truth or dare":
            return "truth_or_dare"
        case "this or that":
            return "this_or_that"
        case "never have i ever":
            return "never_have_i_ever"
        case "who's most likely to":
            return "most_likely_to"
        case "how well do you know me":
            return "how_well_do_you_know_me"
        case "impersonation":
            return "impersonation"
        case "memory match":
            return "memory_match"
        case "story time":
            return "story_time"
        case "bucket list":
            return "bucket_list"
        default:
            return "questionmark.circle"
        }
    }
}

// MARK: - Validation Extensions
extension GameCategory {
    /// Validates category data integrity
    var isValid: Bool {
        !name.isEmpty && !iconName.isEmpty && cardCount >= 0
    }
    
    /// Returns validation errors if any
    var validationErrors: [String] {
        var errors: [String] = []
        
        if name.isEmpty {
            errors.append("Category name cannot be empty")
        }
        
        if iconName.isEmpty {
            errors.append("Icon name cannot be empty")
        }
        
        if cardCount < 0 {
            errors.append("Card count cannot be negative")
        }
        
        if cardCount != actualCardCount {
            errors.append("Card count mismatch: expected \(cardCount), actual \(actualCardCount)")
        }
        
        return errors
    }
}

// MARK: - Premium Category Configuration
extension GameCategory {
    /// Categories that require premium subscription
    static let premiumCategoryNames: Set<String> = [
        "Truth or Dare",
        "This or That",
        "Who's Most Likely To",
        "Impersonation", 
        "Bucket List"
    ]
    
    /// Check if a category name should be premium
    static func shouldBePremium(_ categoryName: String) -> Bool {
        return premiumCategoryNames.contains(categoryName)
    }
    
    /// Update premium status based on category name
    func updatePremiumStatus() {
        self.isPremium = GameCategory.shouldBePremium(self.name)
    }
}