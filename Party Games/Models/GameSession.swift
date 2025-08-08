//
//  GameSession.swift
//  Party Games
//
//  Created by Mohamed Abdelmagid on 8/8/25.
//

import Foundation
import SwiftData

@Model
final class GameSession {
    /// Unique identifier for the session
    @Attribute(.unique) var id: UUID
    
    /// Session name/title for user reference
    var name: String
    
    /// Current card index in the deck
    var currentCardIndex: Int
    
    /// Array of completed card IDs to track progress
    var completedCardIds: [UUID]
    
    /// Session start date
    var startDate: Date
    
    /// Session end date (nil if still active)
    var endDate: Date?
    
    /// Whether this session is currently active
    var isActive: Bool
    
    /// Session duration in seconds (computed when ended)
    var durationInSeconds: TimeInterval
    
    /// Number of players participating
    var playerCount: Int
    
    /// Session notes or comments
    var notes: String
    
    /// Session difficulty preference (1-5)
    var preferredDifficulty: Int
    
    /// Whether to shuffle cards or play in order
    var isShuffled: Bool
    
    /// Custom card order if shuffled (array of card indices)
    var shuffledOrder: [Int]
    
    /// Relationship to category
    var category: GameCategory?
    
    init(name: String = "", category: GameCategory? = nil, playerCount: Int = 2) {
        self.id = UUID()
        self.name = name.isEmpty ? "Session \(Date().formatted(.dateTime.month().day().hour().minute()))" : name
        self.currentCardIndex = 0
        self.completedCardIds = []
        self.startDate = Date()
        self.endDate = nil
        self.isActive = true
        self.durationInSeconds = 0
        self.playerCount = max(1, playerCount)
        self.notes = ""
        self.preferredDifficulty = 1
        self.isShuffled = false
        self.shuffledOrder = []
        self.category = category
    }
    
    /// End the current session
    func endSession() {
        guard isActive else { return }
        
        endDate = Date()
        isActive = false
        durationInSeconds = endDate!.timeIntervalSince(startDate)
    }
    
    /// Resume a paused session
    func resumeSession() {
        guard !isActive, endDate != nil else { return }
        
        endDate = nil
        isActive = true
    }
    
    /// Mark a card as completed
    func markCardAsCompleted(_ cardId: UUID) {
        if !completedCardIds.contains(cardId) {
            completedCardIds.append(cardId)
        }
    }
    
    /// Move to next card
    func moveToNextCard() {
        let totalCards = category?.actualCardCount ?? 0
        if currentCardIndex < totalCards - 1 {
            currentCardIndex += 1
        }
    }
    
    /// Move to previous card
    func moveToPreviousCard() {
        if currentCardIndex > 0 {
            currentCardIndex -= 1
        }
    }
    
    /// Jump to specific card index
    func jumpToCard(at index: Int) {
        let totalCards = category?.actualCardCount ?? 0
        currentCardIndex = max(0, min(index, totalCards - 1))
    }
    
    /// Shuffle the card order
    func shuffleCards() {
        guard let category = category else { return }
        
        let cardCount = category.actualCardCount
        shuffledOrder = Array(0..<cardCount).shuffled()
        isShuffled = true
        currentCardIndex = 0
    }
    
    /// Reset shuffle and return to original order
    func resetShuffle() {
        shuffledOrder = []
        isShuffled = false
        currentCardIndex = 0
    }
    
    /// Get the actual card index considering shuffle
    func getActualCardIndex() -> Int {
        if isShuffled && currentCardIndex < shuffledOrder.count {
            return shuffledOrder[currentCardIndex]
        }
        return currentCardIndex
    }
    
    /// Reset session progress
    func resetProgress() {
        currentCardIndex = 0
        completedCardIds.removeAll()
        
        // Reset completion status for all cards in category
        category?.cards.forEach { card in
            card.resetCompletion()
        }
    }
}

// MARK: - Computed Properties
extension GameSession {
    /// Progress percentage (0.0 to 1.0)
    var progressPercentage: Double {
        guard let category = category, category.actualCardCount > 0 else { return 0.0 }
        return Double(completedCardIds.count) / Double(category.actualCardCount)
    }
    
    /// Number of cards completed
    var completedCardCount: Int {
        completedCardIds.count
    }
    
    /// Number of remaining cards
    var remainingCardCount: Int {
        let totalCards = category?.actualCardCount ?? 0
        return max(0, totalCards - completedCardIds.count)
    }
    
    /// Whether all cards have been completed
    var isCompleted: Bool {
        guard let category = category else { return false }
        return completedCardIds.count >= category.actualCardCount
    }
    
    /// Session duration as formatted string
    var formattedDuration: String {
        let duration = isActive ? Date().timeIntervalSince(startDate) : durationInSeconds
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    /// Category name for display
    var categoryName: String {
        category?.name ?? "Unknown Category"
    }
}

// MARK: - Validation Extensions
extension GameSession {
    /// Validates session data integrity
    var isValid: Bool {
        !name.isEmpty &&
        currentCardIndex >= 0 &&
        playerCount > 0 &&
        preferredDifficulty >= 1 &&
        preferredDifficulty <= 5 &&
        (endDate == nil || endDate! >= startDate)
    }
    
    /// Returns validation errors if any
    var validationErrors: [String] {
        var errors: [String] = []
        
        if name.isEmpty {
            errors.append("Session name cannot be empty")
        }
        
        if currentCardIndex < 0 {
            errors.append("Current card index cannot be negative")
        }
        
        if playerCount <= 0 {
            errors.append("Player count must be at least 1")
        }
        
        if preferredDifficulty < 1 || preferredDifficulty > 5 {
            errors.append("Preferred difficulty must be between 1 and 5")
        }
        
        if let endDate = endDate, endDate < startDate {
            errors.append("End date cannot be before start date")
        }
        
        if category == nil {
            errors.append("Session must have an associated category")
        }
        
        if let category = category, currentCardIndex >= category.actualCardCount {
            errors.append("Current card index exceeds available cards")
        }
        
        return errors
    }
}