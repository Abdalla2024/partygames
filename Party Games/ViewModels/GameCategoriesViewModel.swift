//
//  GameCategoriesViewModel.swift
//  Party Games
//
//  Created by Mohamed Abdelmagid on 8/8/25.
//

import Foundation
import SwiftData
import SwiftUI

/// ViewModel for managing game categories in the party games app
/// Follows MVVM architecture with @Observable for SwiftUI integration
@Observable
final class GameCategoriesViewModel {
    
    // MARK: - Published State Properties
    
    /// All categories loaded from SwiftData
    var categories: [GameCategory] = []
    
    /// Loading state indicator
    var isLoading: Bool = false
    
    /// Error message for user feedback
    var errorMessage: String? = nil
    
    /// Search/filter text for category filtering
    var searchText: String = "" {
        didSet {
            // Automatically update filtered categories when search text changes
            filteredCategories = calculateFilteredCategories()
        }
    }
    
    /// Currently selected category
    var selectedCategory: GameCategory? = nil
    
    /// Filtered categories based on search text
    private(set) var filteredCategories: [GameCategory] = []
    
    /// Indicates if data has been successfully initialized
    private(set) var isInitialized: Bool = false
    
    // MARK: - Dependencies
    
    /// Model context for SwiftData operations
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    /// Initialize ViewModel with ModelContext
    /// - Parameter modelContext: SwiftData model context for data operations
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.filteredCategories = []
    }
    
    // MARK: - Core Data Operations
    
    /// Load all categories from SwiftData
    /// Handles loading state and error management
    @MainActor
    func loadCategories() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Initialize data if needed (first launch)
            await initializeDataIfNeeded()
            
            // Fetch categories from SwiftData
            let fetchedCategories = try GameDataManager.getAllCategories(modelContext: modelContext)
            
            categories = fetchedCategories
            filteredCategories = calculateFilteredCategories()
            isInitialized = true
            
        } catch {
            errorMessage = "Failed to load categories: \(error.localizedDescription)"
            categories = []
            filteredCategories = []
            print("Error loading categories: \(error)")
        }
        
        isLoading = false
    }
    
    /// Initialize data from JSON if no categories exist (first launch)
    /// This handles the initial data seeding requirement
    @MainActor
    private func initializeDataIfNeeded() async {
        // Check if data already exists
        guard !GameDataManager.hasImportedData(modelContext: modelContext) else {
            return
        }
        
        do {
            // Import data from the JSON file
            try await GameDataManager.importGameData(
                from: "couples_party_games_complete",
                to: modelContext
            )
            print("Successfully initialized game data from JSON")
        } catch {
            errorMessage = "Failed to initialize game data: \(error.localizedDescription)"
            print("Error initializing data: \(error)")
        }
    }
    
    /// Refresh categories data
    /// Useful for pulling fresh data after external changes
    @MainActor
    func refresh() async {
        await loadCategories()
    }
    
    // MARK: - Category Management
    
    /// Select a category and update selection state
    /// - Parameter category: The category to select
    func selectCategory(_ category: GameCategory) {
        selectedCategory = category
    }
    
    /// Clear category selection
    func clearSelection() {
        selectedCategory = nil
    }
    
    /// Get category by name (case-insensitive)
    /// - Parameter name: Category name to search for
    /// - Returns: Matching category or nil
    func getCategoryByName(_ name: String) -> GameCategory? {
        return categories.first { category in
            category.name.lowercased() == name.lowercased()
        }
    }
    
    /// Get category by ID
    /// - Parameter id: Category UUID to search for
    /// - Returns: Matching category or nil
    func getCategoryById(_ id: UUID) -> GameCategory? {
        return categories.first { $0.id == id }
    }
    
    // MARK: - Filtering & Search
    
    /// Calculate filtered categories based on search text
    /// - Returns: Array of filtered categories
    private func calculateFilteredCategories() -> [GameCategory] {
        guard !searchText.isEmpty else {
            return categories.filter { $0.isActive }
        }
        
        let lowercasedSearch = searchText.lowercased()
        return categories.filter { category in
            category.isActive && category.name.lowercased().contains(lowercasedSearch)
        }
    }
    
    /// Clear search filter
    func clearSearch() {
        searchText = ""
    }
    
    // MARK: - Computed Properties
    
    /// Active categories count
    var activeCategoriesCount: Int {
        categories.filter { $0.isActive }.count
    }
    
    /// Total cards count across all categories
    var totalCardsCount: Int {
        categories.reduce(0) { $0 + $1.actualCardCount }
    }
    
    /// Whether there are any categories available
    var hasCategories: Bool {
        !categories.isEmpty
    }
    
    /// Whether search is active
    var isSearching: Bool {
        !searchText.isEmpty
    }
    
    /// Search results count
    var searchResultsCount: Int {
        filteredCategories.count
    }
    
    // MARK: - Validation & Health Checks
    
    /// Validate all categories data integrity
    /// - Returns: Array of validation errors across all categories
    func validateCategories() -> [String] {
        var allErrors: [String] = []
        
        for category in categories {
            let errors = category.validationErrors
            if !errors.isEmpty {
                allErrors.append("Category '\(category.name)': \(errors.joined(separator: ", "))")
            }
        }
        
        return allErrors
    }
    
    /// Check if categories data is healthy
    var isDataHealthy: Bool {
        validateCategories().isEmpty
    }
    
    // MARK: - Category Statistics
    
    /// Get statistics for a specific category
    /// - Parameter category: Category to analyze
    /// - Returns: Dictionary with category statistics
    func getStatistics(for category: GameCategory) -> [String: Any] {
        return [
            "name": category.name,
            "cardCount": category.actualCardCount,
            "activeSessionsCount": category.activeSessionsCount,
            "isActive": category.isActive,
            "createdAt": category.createdAt,
            "validationErrors": category.validationErrors.count
        ]
    }
    
    /// Get overall statistics
    var overallStatistics: [String: Any] {
        return [
            "totalCategories": categories.count,
            "activeCategories": activeCategoriesCount,
            "totalCards": totalCardsCount,
            "isInitialized": isInitialized,
            "hasErrors": !isDataHealthy,
            "errorCount": validateCategories().count
        ]
    }
}

// MARK: - Supporting Types

extension GameCategoriesViewModel {
    
    /// Loading state enumeration for better state management
    enum LoadingState {
        case idle
        case loading
        case loaded
        case error(String)
        
        var isLoading: Bool {
            if case .loading = self { return true }
            return false
        }
        
        var errorMessage: String? {
            if case .error(let message) = self { return message }
            return nil
        }
    }
    
    /// Search scope for filtering
    enum SearchScope {
        case all
        case activeOnly
        case withCards
        
        func filter(_ categories: [GameCategory]) -> [GameCategory] {
            switch self {
            case .all:
                return categories
            case .activeOnly:
                return categories.filter { $0.isActive }
            case .withCards:
                return categories.filter { $0.actualCardCount > 0 }
            }
        }
    }
}

// MARK: - Convenience Extensions

extension GameCategoriesViewModel {
    
    /// Quick access to most popular categories (by card count)
    var popularCategories: [GameCategory] {
        filteredCategories
            .sorted { $0.actualCardCount > $1.actualCardCount }
            .prefix(5)
            .map { $0 }
    }
    
    /// Quick access to recently created categories
    var recentCategories: [GameCategory] {
        filteredCategories
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(3)
            .map { $0 }
    }
}