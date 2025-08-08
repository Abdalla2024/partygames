//
//  GameCard.swift
//  Party Games
//
//  Created by Mohamed Abdelmagid on 8/8/25.
//

import Foundation
import SwiftData

@Model
final class GameCard {
    /// Unique identifier for the card
    @Attribute(.unique) var id: UUID
    
    /// Card number within the category (1-52)
    var number: Int
    
    /// The prompt/question text for this card
    var prompt: String
    
    /// Whether this card has been completed/shown in current session
    var isCompleted: Bool
    
    /// Number of times this card has been used across all sessions
    var usageCount: Int
    
    /// Creation date for sorting purposes
    var createdAt: Date
    
    /// Last time this card was used
    var lastUsedAt: Date?
    
    /// Whether this card is marked as favorite by user
    var isFavorite: Bool
    
    /// Difficulty level (1-5) - can be used for filtering
    var difficultyLevel: Int
    
    /// Relationship to category
    var category: GameCategory?
    
    init(number: Int, prompt: String, category: GameCategory? = nil, difficultyLevel: Int = 1) {
        self.id = UUID()
        self.number = number
        self.prompt = prompt
        self.isCompleted = false
        self.usageCount = 0
        self.createdAt = Date()
        self.isFavorite = false
        self.difficultyLevel = max(1, min(5, difficultyLevel)) // Ensure 1-5 range
        self.category = category
    }
    
    /// Mark card as used/completed
    func markAsUsed() {
        isCompleted = true
        usageCount += 1
        lastUsedAt = Date()
    }
    
    /// Reset card completion status (for new sessions)
    func resetCompletion() {
        isCompleted = false
    }
    
    /// Toggle favorite status
    func toggleFavorite() {
        isFavorite.toggle()
    }
    
    /// Computed property for display purposes
    var displayTitle: String {
        "Card \(number)"
    }
    
    /// Computed property to get category name safely
    var categoryName: String {
        category?.name ?? "Unknown"
    }
    
    /// Check if card is recently used (within last 24 hours)
    var isRecentlyUsed: Bool {
        guard let lastUsed = lastUsedAt else { return false }
        return Date().timeIntervalSince(lastUsed) < 24 * 60 * 60 // 24 hours
    }
}

// MARK: - Validation Extensions
extension GameCard {
    /// Validates card data integrity
    var isValid: Bool {
        number > 0 && 
        number <= 52 && 
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        difficultyLevel >= 1 && 
        difficultyLevel <= 5
    }
    
    /// Returns validation errors if any
    var validationErrors: [String] {
        var errors: [String] = []
        
        if number <= 0 {
            errors.append("Card number must be greater than 0")
        }
        
        if number > 52 {
            errors.append("Card number must be 52 or less")
        }
        
        if prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Card prompt cannot be empty")
        }
        
        if difficultyLevel < 1 || difficultyLevel > 5 {
            errors.append("Difficulty level must be between 1 and 5")
        }
        
        if category == nil {
            errors.append("Card must belong to a category")
        }
        
        return errors
    }
}

// MARK: - Comparable Conformance
extension GameCard: Comparable {
    static func < (lhs: GameCard, rhs: GameCard) -> Bool {
        if lhs.categoryName != rhs.categoryName {
            return lhs.categoryName < rhs.categoryName
        }
        return lhs.number < rhs.number
    }
    
    static func == (lhs: GameCard, rhs: GameCard) -> Bool {
        lhs.id == rhs.id
    }
}