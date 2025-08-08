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
    
    /// Selected category for game session
    @State private var selectedCategory: GameCategory?
    
    /// Search text for filtering categories
    @State private var searchText = ""
    
    /// Controls the game session sheet presentation
    @State private var showingGameSession = false
    
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
                .searchable(text: $searchText, prompt: "Search categories...")
                .task {
                    await loadInitialData()
                }
                .refreshable {
                    await refreshData()
                }
                .sheet(item: $selectedCategory) { category in
                    GameSessionView(category: category, modelContext: modelContext)
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
                    CategoryCardView(
                        category: category,
                        onTap: { selectCategory(category) }
                    )
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
    
    // MARK: - Filtered Categories
    
    private var filteredCategories: [GameCategory] {
        if searchText.isEmpty {
            return categoriesViewModel.categories
        } else {
            return categoriesViewModel.categories.filter { category in
                category.name.localizedCaseInsensitiveContains(searchText)
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
            
            Text(searchText.isEmpty ? "No game categories available" : "No categories match '\(searchText)'")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Actions
    
    private func selectCategory(_ category: GameCategory) {
        selectedCategory = category
    }
    
    private func loadInitialData() async {
        await categoriesViewModel.loadCategories()
    }
    
    private func refreshData() async {
        await categoriesViewModel.refresh()
    }
}

// MARK: - Category Card View

struct CategoryCardView: View {
    let category: GameCategory
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
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
            .frame(minWidth: 140)
            .background(Color(UIColor.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(UIColor.separator), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityLabel(category.name)
        .accessibilityValue("\(category.cards.count) cards available")
        .accessibilityHint("Double tap to start playing")
        .accessibilityAddTraits(.isButton)
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
        onTap: {}
    )
    .frame(width: 160, height: 200)
    .padding()
}