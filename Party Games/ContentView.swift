//
//  ContentView.swift
//  Party Games
//
//  Created by Mohamed Abdelmagid on 8/7/25.
//

import SwiftUI
import SwiftData

/// Main content view that coordinates onboarding, paywall, and app navigation
/// Handles the complete user flow: onboarding → paywall → main app
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Initialization state
    @State private var isInitializing = true
    @State private var initializationError: Error?
    @State private var showingError = false
    
    // App flow state  
    @State private var userPreferences: UserPreferences?
    @State private var storeKitManager = StoreKitManager()
    @State private var showingOnboarding = false
    @State private var showingPaywall = false
    @State private var hasUserDismissedPaywall = false
    
    // Current flow step
    private enum FlowStep {
        case initializing
        case onboarding
        case ratingPrompt
        case paywall
        case mainApp
        case error
    }
    
    private var currentStep: FlowStep {
        if isInitializing {
            return .initializing
        } else if initializationError != nil {
            return .error
        } else if let preferences = userPreferences {
            if !preferences.hasSeenOnboarding {
                return .onboarding
            } else if !preferences.hasRatedApp && !preferences.hasSeenRatingPrompt {
                return .ratingPrompt
            } else if !preferences.isSubscriptionValid && !storeKitManager.hasPremiumAccess && !hasUserDismissedPaywall {
                return .paywall
            } else {
                return .mainApp
            }
        } else {
            return .onboarding
        }
    }
    
    var body: some View {
        Group {
            switch currentStep {
            case .initializing:
                initializationView
            case .error:
                errorView(initializationError!)
            case .onboarding:
                OnboardingView {
                    handleOnboardingComplete()
                }
            case .ratingPrompt:
                RatingPromptView(
                    onRatingComplete: {
                        handleRatingComplete()
                    },
                    onDismiss: {
                        handleRatingDismiss()
                    }
                )
            case .paywall:
                PaywallView(
                    storeKitManager: storeKitManager,
                    onPurchaseComplete: {
                        handlePaywallComplete()
                    },
                    onDismiss: {
                        handlePaywallDismiss()
                    }
                )
            case .mainApp:
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
            
            // Update premium status for categories
            try updatePremiumCategoriesIfNeeded()
            
            // Validate data integrity
            try validateGameData()
            
            // Load user preferences
            loadUserPreferences()
            
            // Sync UserPreferences with current StoreKit status
            await syncUserPreferencesWithStoreKit()
            
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
    
    /// Update premium status for categories based on predefined list
    private func updatePremiumCategoriesIfNeeded() throws {
        let categories = try GameDataManager.getAllCategories(modelContext: modelContext)
        var hasChanges = false
        
        for category in categories {
            let shouldBePremium = GameCategory.shouldBePremium(category.name)
            let shouldBeRatingUnlockable = GameCategory.shouldBeRatingUnlockable(category.name)
            
            if category.isPremium != shouldBePremium {
                category.isPremium = shouldBePremium
                hasChanges = true
            }
            
            if category.isRatingUnlockable != shouldBeRatingUnlockable {
                category.isRatingUnlockable = shouldBeRatingUnlockable
                hasChanges = true
            }
        }
        
        if hasChanges {
            try modelContext.save()
            print("Updated premium and rating-unlockable status for categories")
        }
    }
    
    /// Load user preferences
    private func loadUserPreferences() {
        userPreferences = UserPreferences.getCurrentPreferences(from: modelContext)
    }
    
    /// Sync UserPreferences with current StoreKit entitlements
    private func syncUserPreferencesWithStoreKit() async {
        guard let userPreferences = userPreferences else {
            print("⚠️ Cannot sync - UserPreferences not loaded")
            return
        }
        
        do {
            await storeKitManager.syncUserPreferencesWithStoreKit(userPreferences)
            try modelContext.save()
            print("✅ UserPreferences synced and saved successfully")
        } catch {
            print("❌ Error syncing UserPreferences with StoreKit: \(error)")
            // Don't fail initialization due to sync errors
        }
    }
    
    /// Handle onboarding completion
    private func handleOnboardingComplete() {
        userPreferences?.completeOnboarding()
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving onboarding completion: \(error)")
        }
    }
    
    /// Handle paywall completion (purchase success)
    private func handlePaywallComplete() {
        // Update user preferences with premium status
        if let userPreferences = userPreferences {
            storeKitManager.updateUserPreferences(userPreferences)
            
            do {
                try modelContext.save()
            } catch {
                print("Error saving premium status: \(error)")
            }
        }
    }
    
    /// Handle rating completion
    private func handleRatingComplete() {
        userPreferences?.markAppAsRated()
        
        do {
            try modelContext.save()
            print("Rating completed - This or That category unlocked")
        } catch {
            print("Error saving rating completion: \(error)")
        }
    }
    
    /// Handle rating prompt dismissal (user chooses "Maybe Later")
    private func handleRatingDismiss() {
        userPreferences?.markRatingPromptSeen()
        
        do {
            try modelContext.save()
            print("Rating prompt dismissed - continuing to main app")
        } catch {
            print("Error saving rating prompt dismissal: \(error)")
        }
    }
    
    /// Handle paywall dismissal (user closes without purchase)
    private func handlePaywallDismiss() {
        // Set flag to allow user to bypass paywall and access free content
        hasUserDismissedPaywall = true
        print("Paywall dismissed - continuing to main app with free content access")
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
