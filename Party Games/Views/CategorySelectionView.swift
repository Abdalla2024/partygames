//
//  CategorySelectionView.swift
//  Party Games
//
//  Created by Claude on 8/8/25.
//

import SwiftUI
import SwiftData

/// Main view for selecting party game categories
/// Displays a grid of available game categories with search functionality
struct CategorySelectionView: View {
    
    // MARK: - Properties
    
    /// Model context for SwiftData operations
    let modelContext: ModelContext
    
    /// ViewModel for managing category data and state
    @State private var categoriesViewModel: GameCategoriesViewModel
    
    /// StoreKit manager for premium purchases
    @State private var storeKitManager = StoreKitManager()
    
    /// User preferences for premium status
    @State private var userPreferences: UserPreferences?
    
    /// Paywall presentation state
    @State private var showingPaywall = false
    
    /// Rating prompt presentation state
    @State private var showingRatingPrompt = false
    
    /// Settings presentation state
    @State private var showingSettings = false
    
    /// Selected premium category (when paywall is shown)
    @State private var selectedPremiumCategory: GameCategory?
    
    /// Selected rating-unlockable category (when rating prompt is shown)
    @State private var selectedRatingCategory: GameCategory?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self._categoriesViewModel = State(initialValue: GameCategoriesViewModel(modelContext: modelContext))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Party Games")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(Color(red: 1, green: 1, blue: 1))
                        }
                    }
                }
                .task {
                    await loadInitialData()
                    loadUserPreferences()
                }
                .refreshable {
                    await refreshData()
                }
                .sheet(isPresented: $showingPaywall) {
                    PaywallView(
                        storeKitManager: storeKitManager,
                        onPurchaseComplete: {
                            handlePurchaseComplete()
                        },
                        onDismiss: {
                            showingPaywall = false
                            selectedPremiumCategory = nil
                        }
                    )
                }
                .sheet(isPresented: $showingRatingPrompt) {
                    RatingPromptView(
                        onRatingComplete: {
                            handleRatingComplete()
                        },
                        onDismiss: {
                            handleRatingDismiss()
                        }
                    )
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView(
                        storeKitManager: storeKitManager,
                        modelContext: modelContext,
                        onDismiss: {
                            showingSettings = false
                        }
                    )
                }
        }
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        if categoriesViewModel.isLoading {
            loadingView
        } else if let errorMessage = categoriesViewModel.errorMessage {
            errorView(message: errorMessage)
        } else if filteredCategories.isEmpty {
            emptyStateView
        } else {
            categoryGrid
        }
    }
    
    // MARK: - Category Grid
    
    private var categoryGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 20) {
                ForEach(filteredCategories) { category in
                    if category.isPremium && !hasPremiumAccess {
                        // Premium category - show paywall
                        Button(action: {
                            selectedPremiumCategory = category
                            showingPaywall = true
                        }) {
                            CategoryCardView(
                                category: category,
                                badgeType: .crown,
                                onTap: { }
                            )
                        }
                        .buttonStyle(.plain)
                    } else if category.isRatingUnlockable && !hasRatedApp {
                        // Rating-unlockable category - show rating prompt
                        Button(action: {
                            selectedRatingCategory = category
                            showingRatingPrompt = true
                        }) {
                            CategoryCardView(
                                category: category,
                                badgeType: .star,
                                onTap: { }
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        // Free category, user has premium, or user has rated - navigate to game
                        NavigationLink(destination: GameSessionView(category: category, modelContext: modelContext)) {
                            CategoryCardView(
                                category: category,
                                badgeType: .none,
                                onTap: { }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Grid Configuration
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 160), spacing: 20)
        ]
    }
    
    // MARK: - Sorted Categories
    
    private var filteredCategories: [GameCategory] {
        // Sort categories: free games first, then premium games
        // Within each group, sort alphabetically by name
        return categoriesViewModel.categories.sorted { category1, category2 in
            if category1.isPremium == category2.isPremium {
                // Both have same premium status, sort alphabetically
                return category1.name.localizedCaseInsensitiveCompare(category2.name) == .orderedAscending
            } else {
                // Different premium status, free games (isPremium = false) come first
                return !category1.isPremium && category2.isPremium
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading Party Games...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.headline)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                Task {
                    await refreshData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Categories Found")
                .font(.headline)
            
            Text("No game categories available")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var hasPremiumAccess: Bool {
        // Primary: Use StoreKitManager as the authoritative source of truth
        if storeKitManager.hasPremiumAccess {
            return true
        }
        
        // Only use UserPreferences as fallback if StoreKitManager failed to load products
        // This ensures we have offline functionality while maintaining StoreKit as source of truth
        if !storeKitManager.products.isEmpty {
            // StoreKitManager loaded successfully, trust its result (false)
            return false
        } else {
            // StoreKitManager failed to load, use cached UserPreferences as fallback
            return userPreferences?.isSubscriptionValid ?? false
        }
    }
    
    private var hasRatedApp: Bool {
        return userPreferences?.hasRatedApp ?? false
    }
    
    // MARK: - Actions
    
    private func loadInitialData() async {
        await categoriesViewModel.loadCategories()
    }
    
    private func refreshData() async {
        await categoriesViewModel.refresh()
    }
    
    private func loadUserPreferences() {
        userPreferences = UserPreferences.getCurrentPreferences(from: modelContext)
    }
    
    private func handlePurchaseComplete() {
        // Update user preferences with new premium status
        if let userPreferences = userPreferences {
            storeKitManager.updateUserPreferences(userPreferences)
            
            do {
                try modelContext.save()
            } catch {
                print("Error saving user preferences after purchase: \(error)")
            }
        }
        
        // Dismiss paywall
        showingPaywall = false
        
        // Navigate to the selected premium category if one was selected
        if let category = selectedPremiumCategory {
            selectedPremiumCategory = nil
            // The navigation will now work since user has premium access
        }
    }
    
    private func handleRatingComplete() {
        // Update user preferences with rating completion
        userPreferences?.markAppAsRated()
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving user preferences after rating: \(error)")
        }
        
        // Dismiss rating prompt
        showingRatingPrompt = false
        
        // Navigate to the selected rating-unlockable category if one was selected
        if let category = selectedRatingCategory {
            selectedRatingCategory = nil
            // The navigation will now work since user has rated the app
        }
    }
    
    private func handleRatingDismiss() {
        // Mark rating prompt as seen
        userPreferences?.markRatingPromptSeen()
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving rating prompt dismissal: \(error)")
        }
        
        // Dismiss rating prompt
        showingRatingPrompt = false
        selectedRatingCategory = nil
    }
}

// MARK: - Category Badge Type

enum CategoryBadgeType {
    case crown    // Premium
    case star     // Rating unlockable
    case none     // Free/unlocked
}

// MARK: - Category Card View

struct CategoryCardView: View {
    let category: GameCategory
    let badgeType: CategoryBadgeType
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                // Category Icon
                AsyncImage(url: nil) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(category.iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                VStack(spacing: 4) {
                    // Category Name
                    Text(category.name)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    // Card Count
                    Text("\(category.cards.count) cards")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(UIColor.separator), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Badge (Crown for premium, Star for rating-unlockable)
            if badgeType != .none {
                VStack {
                    HStack {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 28, height: 28)
                            
                            Group {
                                if badgeType == .crown {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 14, weight: .medium))
                                } else if badgeType == .star {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 14, weight: .medium))
                                }
                            }
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.84, blue: 0.0),  // Gold
                                        Color(red: 1.0, green: 0.72, blue: 0.0)   // Darker gold
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        }
                        .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4), radius: 4, x: 0, y: 2)
                        .offset(x: -4, y: 4)
                    }
                    Spacer()
                }
            }
        }
        .accessibilityLabel(category.name)
        .accessibilityValue("\(category.cards.count) cards available")
        .accessibilityHint(accessibilityHintText)
        .accessibilityAddTraits(.isButton)
    }
    
    private var accessibilityHintText: String {
        switch badgeType {
        case .crown:
            return "Premium content - Double tap to upgrade"
        case .star:
            return "Rate the app to unlock - Double tap to rate"
        case .none:
            return "Double tap to start playing"
        }
    }
}


// MARK: - Previews

#Preview("Main View") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: GameCategory.self, GameCard.self, GameSession.self, configurations: config)
    
    CategorySelectionView(modelContext: container.mainContext)
}

#Preview("Category Card") {
    let sampleCategory = GameCategory(
        name: "Truth or Dare",
        iconName: "truth_or_dare",
        cardCount: 52
    )
    
    CategoryCardView(
        category: sampleCategory,
        badgeType: .crown,
        onTap: {}
    )
    .frame(width: 160, height: 200)
    .padding()
}
