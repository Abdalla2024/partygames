//
//  GameSessionViewModel.swift
//  Party Games
//
//  Created by Mohamed Abdelmagid on 8/8/25.
//

import Foundation
import SwiftData
import SwiftUI

/// ViewModel for managing individual game sessions in the party games app
/// Follows MVVM architecture with @Observable for SwiftUI integration
@Observable
final class GameSessionViewModel {
    
    // MARK: - Published State Properties
    
    /// Current active game session
    var currentSession: GameSession? = nil
    
    /// Current card being displayed
    var currentCard: GameCard? = nil
    
    /// Array of remaining cards to be shown
    private(set) var remainingCards: [GameCard] = []
    
    /// Array of completed cards in current session
    private(set) var completedCards: [GameCard] = []
    
    /// Whether a session is currently active
    var isSessionActive: Bool = false
    
    /// Session progress as percentage (0.0 to 1.0)
    var sessionProgress: Double = 0.0
    
    /// Loading state indicator
    var isLoading: Bool = false
    
    /// Error message for user feedback
    var errorMessage: String? = nil
    
    /// Whether session is paused
    var isSessionPaused: Bool = false
    
    /// Session statistics for display
    private(set) var sessionStats: SessionStatistics = SessionStatistics()
    
    // MARK: - Dependencies
    
    /// Model context for SwiftData operations
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    /// Initialize ViewModel with ModelContext
    /// - Parameter modelContext: SwiftData model context for data operations
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Attempt to restore active session on initialization
        Task {
            await restoreActiveSession()
        }
    }
    
    // MARK: - Session Management
    
    /// Start a new game session for the specified category
    /// - Parameters:
    ///   - category: The game category to create session for
    ///   - playerCount: Number of players (default: 2)
    ///   - shuffleCards: Whether to shuffle cards (default: false)
    ///   - sessionName: Custom session name (optional)
    @MainActor
    func startNewSession(
        for category: GameCategory,
        playerCount: Int = 2,
        shuffleCards: Bool = false,
        sessionName: String? = nil
    ) async {
        
        isLoading = true
        errorMessage = nil
        
        do {
            // End any existing active session first
            if let existingSession = currentSession, existingSession.isActive {
                await endCurrentSession()
            }
            
            // Validate category has cards
            guard !category.cards.isEmpty else {
                throw SessionError.noCategoriesAvailable
            }
            
            // Create new session
            let sessionName = sessionName ?? generateSessionName(for: category)
            let newSession = GameSession(
                name: sessionName,
                category: category,
                playerCount: playerCount
            )
            
            // Configure shuffling if requested
            if shuffleCards {
                newSession.shuffleCards()
            }
            
            // Save session to SwiftData
            modelContext.insert(newSession)
            try modelContext.save()
            
            // Update ViewModel state
            currentSession = newSession
            isSessionActive = true
            isSessionPaused = false
            
            // Initialize card state
            await updateCardState()
            updateProgress()
            updateSessionStats()
            
            print("Started new session: \(newSession.name) for category: \(category.name)")
            
        } catch {
            errorMessage = "Failed to start session: \(error.localizedDescription)"
            print("Error starting session: \(error)")
        }
        
        isLoading = false
    }
    
    /// End the current active session
    @MainActor
    func endCurrentSession() async {
        guard let session = currentSession else { return }
        
        do {
            // End session and update duration
            session.endSession()
            
            // Save changes to SwiftData
            try modelContext.save()
            
            // Update ViewModel state
            isSessionActive = false
            isSessionPaused = false
            updateSessionStats()
            
            print("Ended session: \(session.name)")
            
        } catch {
            errorMessage = "Failed to end session: \(error.localizedDescription)"
            print("Error ending session: \(error)")
        }
    }
    
    /// Pause the current session
    @MainActor
    func pauseSession() async {
        guard let session = currentSession, session.isActive else { return }
        
        do {
            session.endSession() // This pauses the session
            isSessionPaused = true
            
            try modelContext.save()
            updateSessionStats()
            
            print("Paused session: \(session.name)")
            
        } catch {
            errorMessage = "Failed to pause session: \(error.localizedDescription)"
            print("Error pausing session: \(error)")
        }
    }
    
    /// Resume a paused session
    @MainActor
    func resumeSession() async {
        guard let session = currentSession, isSessionPaused else { return }
        
        do {
            session.resumeSession()
            isSessionPaused = false
            
            try modelContext.save()
            updateSessionStats()
            
            print("Resumed session: \(session.name)")
            
        } catch {
            errorMessage = "Failed to resume session: \(error.localizedDescription)"
            print("Error resuming session: \(error)")
        }
    }
    
    /// Restart the current session
    @MainActor
    func restartSession() async {
        guard let session = currentSession else { return }
        
        do {
            // Reset session progress and card states
            session.resetProgress()
            
            // Reset card completion status
            for card in session.category?.cards ?? [] {
                card.resetCompletion()
            }
            
            // Restart session timing
            if !session.isActive {
                session.resumeSession()
            }
            
            isSessionActive = true
            isSessionPaused = false
            
            try modelContext.save()
            
            // Refresh card state and progress
            await updateCardState()
            updateProgress()
            updateSessionStats()
            
            print("Restarted session: \(session.name)")
            
        } catch {
            errorMessage = "Failed to restart session: \(error.localizedDescription)"
            print("Error restarting session: \(error)")
        }
    }
    
    // MARK: - Card Navigation
    
    /// Move to the next card
    @MainActor
    func nextCard() async {
        guard let session = currentSession else { return }
        
        do {
            // Move session to next card
            session.moveToNextCard()
            
            // Update card state and progress
            await updateCardState()
            updateProgress()
            
            try modelContext.save()
            
            // Check if session is completed
            if session.isCompleted {
                await endCurrentSession()
            }
            
        } catch {
            errorMessage = "Failed to move to next card: \(error.localizedDescription)"
            print("Error moving to next card: \(error)")
        }
    }
    
    /// Move to the previous card
    @MainActor
    func previousCard() async {
        guard let session = currentSession else { return }
        
        do {
            session.moveToPreviousCard()
            await updateCardState()
            updateProgress()
            try modelContext.save()
            
        } catch {
            errorMessage = "Failed to move to previous card: \(error.localizedDescription)"
            print("Error moving to previous card: \(error)")
        }
    }
    
    /// Jump to a specific card index
    /// - Parameter index: The card index to jump to
    @MainActor
    func jumpToCard(at index: Int) async {
        guard let session = currentSession else { return }
        
        do {
            session.jumpToCard(at: index)
            await updateCardState()
            updateProgress()
            try modelContext.save()
            
        } catch {
            errorMessage = "Failed to jump to card: \(error.localizedDescription)"
            print("Error jumping to card: \(error)")
        }
    }
    
    /// Mark the current card as completed
    @MainActor
    func markCardComplete() async {
        guard let session = currentSession,
              let card = currentCard else { return }
        
        do {
            // Mark card as completed in session
            session.markCardAsCompleted(card.id)
            
            // Mark card as used
            card.markAsUsed()
            
            // Update state
            await updateCardState()
            updateProgress()
            updateSessionStats()
            
            try modelContext.save()
            
            print("Marked card \(card.number) as completed")
            
        } catch {
            errorMessage = "Failed to mark card complete: \(error.localizedDescription)"
            print("Error marking card complete: \(error)")
        }
    }
    
    // MARK: - Card Management
    
    /// Shuffle the cards in the current session
    @MainActor
    func shuffleCards() async {
        guard let session = currentSession else { return }
        
        do {
            session.shuffleCards()
            await updateCardState()
            try modelContext.save()
            
            print("Shuffled cards for session: \(session.name)")
            
        } catch {
            errorMessage = "Failed to shuffle cards: \(error.localizedDescription)"
            print("Error shuffling cards: \(error)")
        }
    }
    
    /// Reset shuffle and return to original order
    @MainActor
    func resetShuffle() async {
        guard let session = currentSession else { return }
        
        do {
            session.resetShuffle()
            await updateCardState()
            try modelContext.save()
            
            print("Reset shuffle for session: \(session.name)")
            
        } catch {
            errorMessage = "Failed to reset shuffle: \(error.localizedDescription)"
            print("Error resetting shuffle: \(error)")
        }
    }
    
    // MARK: - Session Restoration
    
    /// Restore an active session from previous app launch
    @MainActor
    private func restoreActiveSession() async {
        do {
            // Query for active sessions
            let descriptor = FetchDescriptor<GameSession>(
                predicate: #Predicate<GameSession> { $0.isActive },
                sortBy: [SortDescriptor(\.startDate, order: .reverse)]
            )
            
            let activeSessions = try modelContext.fetch(descriptor)
            
            if let mostRecentSession = activeSessions.first {
                currentSession = mostRecentSession
                isSessionActive = true
                isSessionPaused = false
                
                await updateCardState()
                updateProgress()
                updateSessionStats()
                
                print("Restored active session: \(mostRecentSession.name)")
            }
            
        } catch {
            print("Error restoring session: \(error)")
            // Don't show error to user as this is background restoration
        }
    }
    
    // MARK: - State Updates
    
    /// Update the current card and card arrays based on session state
    @MainActor
    private func updateCardState() async {
        guard let session = currentSession,
              let category = session.category else {
            currentCard = nil
            remainingCards = []
            completedCards = []
            return
        }
        
        let allCards = category.cards.sorted { $0.number < $1.number }
        
        // Get current card based on session's current index
        let actualIndex = session.getActualCardIndex()
        let newCard = actualIndex < allCards.count ? allCards[actualIndex] : nil
        
        // Debug: Print card progression
        print("GameSessionViewModel: Updating to card at index \(actualIndex), card number: \(newCard?.number ?? -1)")
        
        currentCard = newCard
        
        // Calculate completed and remaining cards
        completedCards = allCards.filter { session.completedCardIds.contains($0.id) }
        
        // Remaining cards are those not yet completed
        let completedIds = Set(session.completedCardIds)
        remainingCards = allCards.filter { !completedIds.contains($0.id) }
    }
    
    /// Update session progress percentage
    private func updateProgress() {
        guard let session = currentSession else {
            sessionProgress = 0.0
            return
        }
        
        sessionProgress = session.progressPercentage
    }
    
    /// Update session statistics
    private func updateSessionStats() {
        guard let session = currentSession else {
            sessionStats = SessionStatistics()
            return
        }
        
        sessionStats = SessionStatistics(
            totalCards: session.category?.actualCardCount ?? 0,
            completedCards: session.completedCardCount,
            remainingCards: session.remainingCardCount,
            sessionDuration: session.formattedDuration,
            playerCount: session.playerCount,
            isShuffled: session.isShuffled,
            startDate: session.startDate,
            endDate: session.endDate
        )
    }
    
    // MARK: - Helper Methods
    
    /// Generate a default session name
    /// - Parameter category: Category for the session
    /// - Returns: Generated session name
    private func generateSessionName(for category: GameCategory) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return "\(category.name) - \(formatter.string(from: Date()))"
    }
    
    // MARK: - Computed Properties
    
    /// Whether we can navigate to the next card
    var canGoNext: Bool {
        guard let session = currentSession else { return false }
        let totalCards = session.category?.actualCardCount ?? 0
        return session.currentCardIndex < totalCards - 1
    }
    
    /// Whether we can navigate to the previous card
    var canGoPrevious: Bool {
        guard let session = currentSession else { return false }
        return session.currentCardIndex > 0
    }
    
    /// Current card number for display (1-based)
    var currentCardNumber: Int {
        (currentSession?.currentCardIndex ?? 0) + 1
    }
    
    /// Total cards in current session
    var totalCards: Int {
        currentSession?.category?.actualCardCount ?? 0
    }
    
    /// Session name for display
    var sessionName: String {
        currentSession?.name ?? "No Session"
    }
    
    /// Category name for current session
    var categoryName: String {
        currentSession?.categoryName ?? "Unknown"
    }
    
    /// Whether the current card is completed
    var isCurrentCardCompleted: Bool {
        guard let session = currentSession,
              let card = currentCard else { return false }
        return session.completedCardIds.contains(card.id)
    }
    
    /// Whether all cards have been completed
    var isSessionCompleted: Bool {
        currentSession?.isCompleted ?? false
    }
    
    /// Get the next 4 cards to display in the stack (including current card)
    var stackCards: [GameCard] {
        guard let session = currentSession,
              let category = session.category else {
            return []
        }
        
        let allCards = category.cards.sorted { $0.number < $1.number }
        let currentIndex = session.getActualCardIndex()
        
        // Get up to 4 cards starting from current position
        let endIndex = min(currentIndex + 4, allCards.count)
        let startIndex = max(0, currentIndex)
        
        guard startIndex < allCards.count else { return [] }
        
        return Array(allCards[startIndex..<endIndex])
    }
    
    // MARK: - Validation
    
    /// Validate current session state
    var isSessionValid: Bool {
        guard let session = currentSession else { return false }
        return session.isValid && session.category != nil
    }
    
    /// Get validation errors for current session
    var sessionValidationErrors: [String] {
        currentSession?.validationErrors ?? []
    }
}

// MARK: - Supporting Types

extension GameSessionViewModel {
    
    /// Session error types
    enum SessionError: LocalizedError {
        case noCategoriesAvailable
        case sessionNotFound
        case invalidSessionState
        case cardNotFound
        
        var errorDescription: String? {
            switch self {
            case .noCategoriesAvailable:
                return "No cards available in this category"
            case .sessionNotFound:
                return "Session not found"
            case .invalidSessionState:
                return "Invalid session state"
            case .cardNotFound:
                return "Card not found"
            }
        }
    }
    
    /// Session statistics structure
    struct SessionStatistics {
        var totalCards: Int = 0
        var completedCards: Int = 0
        var remainingCards: Int = 0
        var sessionDuration: String = "0:00"
        var playerCount: Int = 0
        var isShuffled: Bool = false
        var startDate: Date? = nil
        var endDate: Date? = nil
        
        /// Progress as percentage string
        var progressPercentage: String {
            guard totalCards > 0 else { return "0%" }
            let percentage = (Double(completedCards) / Double(totalCards)) * 100
            return String(format: "%.0f%%", percentage)
        }
        
        /// Session status description
        var statusDescription: String {
            if endDate != nil {
                return "Completed"
            } else if totalCards > 0 && completedCards == 0 {
                return "Not Started"
            } else {
                return "In Progress"
            }
        }
    }
}

// MARK: - Convenience Extensions

extension GameSessionViewModel {
    
    /// Quick access to session history
    func getRecentSessions(limit: Int = 10) -> [GameSession] {
        do {
            let descriptor = FetchDescriptor<GameSession>(
                sortBy: [SortDescriptor(\.startDate, order: .reverse)]
            )
            
            let sessions = try modelContext.fetch(descriptor)
            return Array(sessions.prefix(limit))
            
        } catch {
            print("Error fetching recent sessions: \(error)")
            return []
        }
    }
    
    /// Get sessions for a specific category
    func getSessions(for category: GameCategory, limit: Int = 5) -> [GameSession] {
        do {
            let descriptor = FetchDescriptor<GameSession>(
                sortBy: [SortDescriptor(\.startDate, order: .reverse)]
            )
            
            let allSessions = try modelContext.fetch(descriptor)
            let filteredSessions = allSessions.filter { $0.category?.id == category.id }
            return Array(filteredSessions.prefix(limit))
            
        } catch {
            print("Error fetching sessions for category: \(error)")
            return []
        }
    }
    
    /// Delete a specific session
    @MainActor
    func deleteSession(_ session: GameSession) async {
        do {
            // If deleting current session, clear state
            if currentSession?.id == session.id {
                currentSession = nil
                isSessionActive = false
                currentCard = nil
                remainingCards = []
                completedCards = []
                sessionProgress = 0.0
            }
            
            modelContext.delete(session)
            try modelContext.save()
            
            print("Deleted session: \(session.name)")
            
        } catch {
            errorMessage = "Failed to delete session: \(error.localizedDescription)"
            print("Error deleting session: \(error)")
        }
    }
}