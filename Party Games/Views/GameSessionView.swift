//
//  GameSessionView.swift
//  Party Games
//
//  Created by Claude on 8/8/25.
//

import SwiftUI
import SwiftData

/// Main game session view that presents swipeable cards and manages game flow
/// Integrates GameSessionViewModel and CardInteractionViewModel for complete game experience
struct GameSessionView: View {
    
    // MARK: - Properties
    
    /// The game category being played
    let category: GameCategory
    
    /// Model context for SwiftData operations
    let modelContext: ModelContext
    
    /// Session management ViewModel
    @State private var gameSessionVM: GameSessionViewModel
    
    /// Card interaction and gesture handling ViewModel
    @State private var cardInteractionVM: CardInteractionViewModel
    
    /// Controls sheet presentation
    @Environment(\.dismiss) private var dismiss
    
    /// Session configuration
    @State private var showingSettings = false
    @State private var showingStats = false
    
    // MARK: - Initialization
    
    init(category: GameCategory, modelContext: ModelContext) {
        self.category = category
        self.modelContext = modelContext
        self._gameSessionVM = State(initialValue: GameSessionViewModel(modelContext: modelContext))
        self._cardInteractionVM = State(initialValue: CardInteractionViewModel())
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundGradient
                    .ignoresSafeArea()
                
                // Main content
                VStack(spacing: 0) {
                    // Session header
                    sessionHeader
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Progress bar
                    progressBar
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    
                    // Card area
                    Spacer()
                    
                    cardArea
                    
                    Spacer()
                    
                    // Session controls
                    sessionControls
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: pauseSession) {
                        Image(systemName: gameSessionVM.isSessionPaused ? "play.fill" : "pause.fill")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Session Stats", systemImage: "chart.bar") {
                            showingStats = true
                        }
                        
                        Button("Settings", systemImage: "gear") {
                            showingSettings = true
                        }
                        
                        Divider()
                        
                        Button("End Session", systemImage: "stop.fill", role: .destructive) {
                            endSession()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                await initializeSession()
            }
            .sheet(isPresented: $showingStats) {
                sessionStatsView
            }
            .sheet(isPresented: $showingSettings) {
                sessionSettingsView
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Background gradient for the session
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemGroupedBackground),
                Color(.systemBackground).opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Session information header
    private var sessionHeader: some View {
        VStack(spacing: 6) {
            Text(gameSessionVM.sessionName)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                // Card counter
                HStack(spacing: 4) {
                    Image(systemName: "rectangle.stack")
                        .font(.caption)
                    Text("\(gameSessionVM.currentCardNumber)/\(gameSessionVM.totalCards)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                // Session duration
                if gameSessionVM.isSessionActive {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(gameSessionVM.sessionStats.sessionDuration)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                
                // Completion percentage
                HStack(spacing: 4) {
                    Image(systemName: "percent")
                        .font(.caption)
                    Text(gameSessionVM.sessionStats.progressPercentage)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .foregroundColor(.secondary)
        }
    }
    
    /// Progress bar showing session completion
    private var progressBar: some View {
        VStack(spacing: 8) {
            ProgressView(value: gameSessionVM.sessionProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(y: 2, anchor: .center)
            
            HStack {
                Text("Completed: \(gameSessionVM.sessionStats.completedCards)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Remaining: \(gameSessionVM.sessionStats.remainingCards)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    /// Main card display area
    private var cardArea: some View {
        ZStack {
            if gameSessionVM.isLoading {
                loadingView
            } else if let errorMessage = gameSessionVM.errorMessage {
                errorView(errorMessage)
            } else if gameSessionVM.isSessionCompleted {
                completionView
            } else if let currentCard = gameSessionVM.currentCard {
                cardStack(currentCard: currentCard)
            } else {
                noCardsView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 450)
        .padding(.horizontal, 20)
    }
    
    /// Stack of cards with the current card on top
    private func cardStack(currentCard: GameCard) -> some View {
        ZStack {
            // Background placeholder cards (visual depth without text confusion)
            ForEach(0..<min(2, gameSessionVM.remainingCards.count), id: \.self) { index in
                placeholderCard(stackIndex: index)
            }
            
            // Current interactive card
            GameCardView(
                card: currentCard,
                cardInteractionVM: cardInteractionVM,
                cardSize: CGSize(width: 320, height: 420),
                isInteractive: true,
                cardState: .normal
            )
        }
    }
    
    /// Create a placeholder card for stack depth without text content
    private func placeholderCard(stackIndex: Int) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.15),
                        Color.purple.opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
            .frame(width: 320, height: 420)
            .offset(x: CGFloat(stackIndex + 1) * 2, y: CGFloat(stackIndex + 1) * 8)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    /// Loading view while session initializes
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Starting Game Session...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    /// Error view for session errors
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Session Error")
                .font(.headline)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                Task {
                    await retrySession()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    /// Completion view when all cards are done
    private var completionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Session Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("You completed all \(gameSessionVM.totalCards) cards in \(gameSessionVM.sessionStats.sessionDuration)")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                Button("Play Again") {
                    Task {
                        await restartSession()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Choose Different Category") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
    
    /// No cards available view
    private var noCardsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Cards Available")
                .font(.headline)
            
            Text("This category doesn't have any cards to play.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Choose Different Category") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    /// Session control buttons
    private var sessionControls: some View {
        HStack(spacing: 20) {
            // Previous card
            Button(action: previousCard) {
                VStack(spacing: 4) {
                    Image(systemName: "chevron.left.circle")
                        .font(.title2)
                    Text("Previous")
                        .font(.caption2)
                }
            }
            .disabled(!gameSessionVM.canGoPrevious)
            
            Spacer()
            
            // Skip card
            Button(action: skipCard) {
                VStack(spacing: 4) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                    Text("Skip")
                        .font(.caption2)
                }
            }
            .disabled(gameSessionVM.isSessionCompleted)
            
            // Next card
            Button(action: nextCard) {
                VStack(spacing: 4) {
                    Image(systemName: "chevron.right.circle")
                        .font(.title2)
                    Text("Next")
                        .font(.caption2)
                }
            }
            .disabled(!gameSessionVM.canGoNext)
            
            Spacer()
            
            // Shuffle
            Button(action: {
                Task {
                    await shuffleCards()
                }
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "shuffle")
                        .font(.title2)
                    Text("Shuffle")
                        .font(.caption2)
                }
            }
            .disabled(gameSessionVM.isLoading)
        }
        .foregroundColor(.blue)
    }
    
    /// Session statistics sheet
    private var sessionStatsView: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    StatRow(title: "Total Cards", value: "\(gameSessionVM.sessionStats.totalCards)")
                    StatRow(title: "Completed", value: "\(gameSessionVM.sessionStats.completedCards)")
                    StatRow(title: "Remaining", value: "\(gameSessionVM.sessionStats.remainingCards)")
                    StatRow(title: "Progress", value: gameSessionVM.sessionStats.progressPercentage)
                    StatRow(title: "Duration", value: gameSessionVM.sessionStats.sessionDuration)
                    StatRow(title: "Players", value: "\(gameSessionVM.sessionStats.playerCount)")
                    StatRow(title: "Shuffled", value: gameSessionVM.sessionStats.isShuffled ? "Yes" : "No")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Session Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingStats = false
                    }
                }
            }
        }
    }
    
    /// Session settings sheet
    private var sessionSettingsView: some View {
        NavigationStack {
            Form {
                Section("Session Actions") {
                    Button("Restart Session") {
                        showingSettings = false
                        Task {
                            await restartSession()
                        }
                    }
                    
                    Button("Shuffle Cards") {
                        showingSettings = false
                        Task {
                            await shuffleCards()
                        }
                    }
                }
                
                Section("Session Info") {
                    HStack {
                        Text("Category")
                        Spacer()
                        Text(category.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total Cards")
                        Spacer()
                        Text("\(gameSessionVM.totalCards)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Started")
                        Spacer()
                        if let startDate = gameSessionVM.sessionStats.startDate {
                            Text(startDate.formatted(date: .omitted, time: .shortened))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Unknown")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingSettings = false
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    /// Initialize the game session
    @MainActor
    private func initializeSession() async {
        await gameSessionVM.startNewSession(for: category)
        
        // Connect card interaction to session progression
        cardInteractionVM.setGameSessionViewModel(gameSessionVM)
    }
    
    /// Pause or resume session
    @MainActor
    private func pauseSession() {
        Task {
            if gameSessionVM.isSessionPaused {
                await gameSessionVM.resumeSession()
            } else {
                await gameSessionVM.pauseSession()
            }
        }
    }
    
    /// End the current session
    @MainActor
    private func endSession() {
        Task {
            await gameSessionVM.endCurrentSession()
            dismiss()
        }
    }
    
    /// Restart the session
    @MainActor
    private func restartSession() async {
        await gameSessionVM.restartSession()
    }
    
    /// Retry session initialization
    @MainActor
    private func retrySession() async {
        await gameSessionVM.startNewSession(for: category)
    }
    
    /// Move to next card
    @MainActor
    private func nextCard() {
        Task {
            await gameSessionVM.nextCard()
        }
    }
    
    /// Move to previous card
    @MainActor
    private func previousCard() {
        Task {
            await gameSessionVM.previousCard()
        }
    }
    
    /// Skip current card
    @MainActor
    private func skipCard() {
        Task {
            await gameSessionVM.nextCard()
        }
    }
    
    /// Shuffle the cards
    @MainActor
    private func shuffleCards() async {
        await gameSessionVM.shuffleCards()
    }
}

// MARK: - Helper Views

/// Statistic row for the stats view
struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
    }
}


// MARK: - Previews

#Preview("Game Session") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: GameCategory.self, GameCard.self, GameSession.self, configurations: config)
    
    let sampleCategory = GameCategory(
        name: "Truth or Dare",
        iconName: "truth_or_dare",
        cardCount: 52
    )
    
    GameSessionView(category: sampleCategory, modelContext: container.mainContext)
}