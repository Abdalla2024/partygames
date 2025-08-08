//
//  GameDataManager.swift
//  Party Games
//
//  Created by Mohamed Abdelmagid on 8/8/25.
//

import Foundation
import SwiftData

/// Data manager for importing and managing party game data
final class GameDataManager {
    
    /// JSON structure for importing game data
    struct GameDataImport: Codable {
        let cards: [CardData]
        
        struct CardData: Codable {
            let game: String
            let number: Int
            let prompt: String
        }
    }
    
    /// Import game data from JSON file
    static func importGameData(from jsonFileName: String, to modelContext: ModelContext) async throws {
        guard let url = Bundle.main.url(forResource: jsonFileName, withExtension: "json") else {
            throw DataImportError.fileNotFound(jsonFileName)
        }
        
        let data = try Data(contentsOf: url)
        let gameData = try JSONDecoder().decode(GameDataImport.self, from: data)
        
        // Group cards by game category
        let groupedCards = Dictionary(grouping: gameData.cards) { $0.game }
        
        try await MainActor.run {
            // Clear existing data if any
            clearExistingData(modelContext: modelContext)
            
            // Create categories and cards
            for (categoryName, cards) in groupedCards {
                let iconName = GameCategory.defaultIconName(for: categoryName)
                let category = GameCategory(
                    name: categoryName,
                    iconName: iconName,
                    cardCount: cards.count
                )
                
                modelContext.insert(category)
                
                // Create cards for this category
                for cardData in cards.sorted(by: { $0.number < $1.number }) {
                    let card = GameCard(
                        number: cardData.number,
                        prompt: cardData.prompt,
                        category: category,
                        difficultyLevel: estimateDifficulty(for: cardData.prompt)
                    )
                    
                    modelContext.insert(card)
                }
            }
            
            // Save changes
            try modelContext.save()
        }
    }
    
    /// Clear existing data from the model context
    private static func clearExistingData(modelContext: ModelContext) {
        // Delete all existing sessions
        let sessionDescriptor = FetchDescriptor<GameSession>()
        do {
            let sessions = try modelContext.fetch(sessionDescriptor)
            for session in sessions {
                modelContext.delete(session)
            }
        } catch {
            print("Error deleting sessions: \(error)")
        }
        
        // Delete all existing cards
        let cardDescriptor = FetchDescriptor<GameCard>()
        do {
            let cards = try modelContext.fetch(cardDescriptor)
            for card in cards {
                modelContext.delete(card)
            }
        } catch {
            print("Error deleting cards: \(error)")
        }
        
        // Delete all existing categories
        let categoryDescriptor = FetchDescriptor<GameCategory>()
        do {
            let categories = try modelContext.fetch(categoryDescriptor)
            for category in categories {
                modelContext.delete(category)
            }
        } catch {
            print("Error deleting categories: \(error)")
        }
    }
    
    /// Estimate difficulty based on prompt complexity
    private static func estimateDifficulty(for prompt: String) -> Int {
        let wordCount = prompt.components(separatedBy: .whitespacesAndNewlines).count
        let hasComplexWords = prompt.range(of: #"\b\w{10,}\b"#, options: .regularExpression) != nil
        let hasMultipleQuestions = prompt.components(separatedBy: "?").count > 2
        
        var difficulty = 1
        
        // Increase difficulty based on length
        if wordCount > 20 {
            difficulty += 1
        }
        if wordCount > 35 {
            difficulty += 1
        }
        
        // Increase difficulty for complex words
        if hasComplexWords {
            difficulty += 1
        }
        
        // Increase difficulty for multiple questions
        if hasMultipleQuestions {
            difficulty += 1
        }
        
        return min(5, difficulty)
    }
    
    /// Check if data has been imported
    static func hasImportedData(modelContext: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<GameCategory>()
        do {
            let categories = try modelContext.fetch(descriptor)
            return !categories.isEmpty
        } catch {
            return false
        }
    }
    
    /// Get all categories
    static func getAllCategories(modelContext: ModelContext) throws -> [GameCategory] {
        let descriptor = FetchDescriptor<GameCategory>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Get cards for a specific category
    static func getCards(for category: GameCategory, modelContext: ModelContext) throws -> [GameCard] {
        let descriptor = FetchDescriptor<GameCard>(
            sortBy: [SortDescriptor(\.number)]
        )
        let allCards = try modelContext.fetch(descriptor)
        return allCards.filter { $0.category?.id == category.id }
    }
    
    /// Create a new game session
    static func createSession(
        name: String = "",
        category: GameCategory,
        playerCount: Int = 2,
        preferredDifficulty: Int = 1,
        shouldShuffle: Bool = false,
        modelContext: ModelContext
    ) -> GameSession {
        let session = GameSession(
            name: name,
            category: category,
            playerCount: playerCount
        )
        session.preferredDifficulty = preferredDifficulty
        
        if shouldShuffle {
            session.shuffleCards()
        }
        
        modelContext.insert(session)
        return session
    }
    
    /// Get active sessions
    static func getActiveSessions(modelContext: ModelContext) throws -> [GameSession] {
        let descriptor = FetchDescriptor<GameSession>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Get session history
    static func getSessionHistory(modelContext: ModelContext, limit: Int = 50) throws -> [GameSession] {
        var descriptor = FetchDescriptor<GameSession>(
            predicate: #Predicate<GameSession> { session in
                session.isActive == false
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }
}

// MARK: - Error Types
enum DataImportError: LocalizedError {
    case fileNotFound(String)
    case invalidFormat
    case importFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let fileName):
            return "Could not find file: \(fileName).json"
        case .invalidFormat:
            return "Invalid JSON format"
        case .importFailed(let reason):
            return "Import failed: \(reason)"
        }
    }
}