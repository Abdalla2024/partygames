//
//  ContentView.swift
//  Party Games
//
//  Created by Mohamed Abdelmagid on 8/7/25.
//

import SwiftUI
import SwiftData

/// Main content view that hosts the primary navigation for the Party Games app
/// Integrates CategorySelectionView with proper SwiftData and ViewModel setup
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isInitializing = true
    @State private var initializationError: Error?
    @State private var showingError = false
    
    var body: some View {
        Group {
            if isInitializing {
                initializationView
            } else if let error = initializationError {
                errorView(error)
            } else {
                CategorySelectionView(modelContext: modelContext)
            }
        }
        .task {
            await performInitialization()
        }
        .alert("Initialization Error", isPresented: $showingError) {
            Button("Try Again") {
                Task { await performInitialization() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(initializationError?.localizedDescription ?? "Unknown error occurred during initialization")
        }
    }
    
    // MARK: - Initialization View
    
    private var initializationView: some View {
        VStack(spacing: 24) {
            // App Logo/Icon
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
                .symbolEffect(.pulse, options: .repeating)
            
            VStack(spacing: 12) {
                Text("Party Games")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Setting up your game experience...")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            ProgressView()
                .scaleEffect(1.2)
                .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            VStack(spacing: 12) {
                Text("Setup Failed")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(error.localizedDescription)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                Button("Try Again") {
                    Task { await performInitialization() }
                }
                .buttonStyle(.borderedProminent)
                
                Button("View Details") {
                    initializationError = error
                    showingError = true
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Initialization Logic
    
    /// Perform app initialization including data setup and validation
    @MainActor
    private func performInitialization() async {
        isInitializing = true
        initializationError = nil
        
        do {
            // Check SwiftData container health
            try validateModelContainer()
            
            // Initialize game data if needed (first launch)
            try await initializeGameDataIfNeeded()
            
            // Validate data integrity
            try validateGameData()
            
            // Initialization complete
            isInitializing = false
            
        } catch {
            initializationError = error
            isInitializing = false
            print("Initialization failed: \(error)")
        }
    }
    
    /// Validate that the SwiftData ModelContainer is properly configured
    private func validateModelContainer() throws {
        // Test basic SwiftData operations
        let descriptor = FetchDescriptor<GameCategory>()
        do {
            _ = try modelContext.fetch(descriptor)
        } catch {
            throw InitializationError.modelContainerFailure(error.localizedDescription)
        }
    }
    
    /// Initialize game data from JSON if no data exists (first launch)
    private func initializeGameDataIfNeeded() async throws {
        // Check if data already exists
        guard !GameDataManager.hasImportedData(modelContext: modelContext) else {
            return
        }
        
        // Import data from JSON file
        try await GameDataManager.importGameData(
            from: "couples_party_games_complete",
            to: modelContext
        )
        
        print("Successfully initialized game data from JSON")
    }
    
    /// Validate that game data is properly loaded and structured
    private func validateGameData() throws {
        let categories = try GameDataManager.getAllCategories(modelContext: modelContext)
        
        guard !categories.isEmpty else {
            throw InitializationError.noGameData
        }
        
        // Validate that categories have cards
        let categoriesWithCards = categories.filter { $0.actualCardCount > 0 }
        guard !categoriesWithCards.isEmpty else {
            throw InitializationError.invalidGameData("No categories have cards")
        }
        
        print("Validated game data: \(categories.count) categories, \(categories.reduce(0) { $0 + $1.actualCardCount }) total cards")
    }
}

// MARK: - Error Types

/// Initialization errors for the ContentView setup process
enum InitializationError: LocalizedError {
    case modelContainerFailure(String)
    case noGameData
    case invalidGameData(String)
    case dataImportFailure(String)
    
    var errorDescription: String? {
        switch self {
        case .modelContainerFailure(let details):
            return "SwiftData setup failed: \(details)"
        case .noGameData:
            return "No game data available. Please check that the game data file is included in the app bundle."
        case .invalidGameData(let reason):
            return "Game data is invalid: \(reason)"
        case .dataImportFailure(let reason):
            return "Failed to import game data: \(reason)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .modelContainerFailure:
            return "Try restarting the app. If the problem persists, reinstall the app."
        case .noGameData, .invalidGameData:
            return "Check that the app was installed correctly and try again."
        case .dataImportFailure:
            return "Ensure you have sufficient storage space and try again."
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [GameCategory.self, GameCard.self, GameSession.self], inMemory: true)
}
