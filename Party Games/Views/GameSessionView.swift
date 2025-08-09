//
//  GameSessionView.swift
//  Party Games
//
//  Created by Claude on 8/8/25.
//

import SwiftUI
import SwiftData

/// Main game session view with a clean 4-card stack implementation
struct GameSessionView: View {
    
    // MARK: - Properties
    
    let category: GameCategory
    let modelContext: ModelContext
    
    @State private var gameSessionVM: GameSessionViewModel
    @State private var cardInteractionVM: CardInteractionViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Animation state for card stack
    @State private var swipeOffset: CGSize = .zero
    @State private var isAnimatingSwipe: Bool = false
    
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
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Game title
                    Text(category.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Card Stack
                    if gameSessionVM.isLoading {
                        ProgressView("Loading Cards...")
                            .scaleEffect(1.2)
                    } else if let errorMessage = gameSessionVM.errorMessage {
                        ErrorView(message: errorMessage) {
                            Task { await initializeSession() }
                        }
                    } else if gameSessionVM.isSessionCompleted {
                        CompletionView {
                            Task { await gameSessionVM.restartSession() }
                        } onDismiss: {
                            dismiss()
                        }
                    } else {
                        cardStack
                    }
                    
                    Spacer()
                    
                    // Control buttons
                    controlButtons
                }
                .padding()
            }
            .task {
                await initializeSession()
            }
        }
    }
    
    // MARK: - Card Stack
    
    private var cardStack: some View {
        ZStack {
            let cards = gameSessionVM.stackCards
            
            // Render cards from back to front (bottom to top of stack)
            ForEach(Array(cards.enumerated().reversed()), id: \.element.id) { index, card in
                SimpleCardView(
                    card: card,
                    stackPosition: index,
                    isTopCard: index == 0,
                    swipeOffset: index == 0 ? swipeOffset : .zero
                )
                .zIndex(Double(cards.count - index))
                .offset(y: CGFloat(index * 25)) // Stack effect: each card 25pts below previous
                .scaleEffect(1.0 - (CGFloat(index) * 0.02)) // Slight scale reduction for depth
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: gameSessionVM.currentCard?.id)
                .gesture(
                    index == 0 ? // Only top card is interactive
                    DragGesture()
                        .onChanged(handleDragChanged)
                        .onEnded(handleDragEnded)
                    : nil
                )
            }
        }
        .frame(width: 320, height: 500) // Fixed frame to contain the stack
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        HStack(spacing: 60) {
            // Previous button
            Button(action: {
                Task { await gameSessionVM.previousCard() }
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                    Text("Previous")
                        .font(.caption)
                }
            }
            .disabled(!gameSessionVM.canGoPrevious)
            .foregroundColor(gameSessionVM.canGoPrevious ? .blue : .gray)
            
            // Shuffle button
            Button(action: {
                Task { await gameSessionVM.shuffleCards() }
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "shuffle.circle.fill")
                        .font(.title2)
                    Text("Shuffle")
                        .font(.caption)
                }
            }
            .foregroundColor(.blue)
            
            // Skip button
            Button(action: {
                Task { await gameSessionVM.nextCard() }
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                    Text("Skip")
                        .font(.caption)
                }
            }
            .foregroundColor(.blue)
        }
    }
    
    // MARK: - Drag Handling
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        guard !isAnimatingSwipe else { return }
        swipeOffset = value.translation
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        guard !isAnimatingSwipe else { return }
        
        let threshold: CGFloat = 100
        let velocity = CGSize(
            width: value.predictedEndLocation.x - value.location.x,
            height: value.predictedEndLocation.y - value.location.y
        )
        
        // Check if swipe is strong enough
        if abs(swipeOffset.width) > threshold || abs(swipeOffset.height) > threshold || 
           abs(velocity.width) > 500 || abs(velocity.height) > 500 {
            animateCardExit()
        } else {
            animateSnapBack()
        }
    }
    
    private func animateCardExit() {
        isAnimatingSwipe = true
        
        // Animate card off screen
        let exitOffset = CGSize(
            width: swipeOffset.width > 0 ? 500 : -500,
            height: swipeOffset.height
        )
        
        withAnimation(.easeInOut(duration: 0.4)) {
            swipeOffset = exitOffset
        }
        
        // Wait and then move to next card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            Task {
                await gameSessionVM.nextCard()
                swipeOffset = .zero
                isAnimatingSwipe = false
            }
        }
    }
    
    private func animateSnapBack() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            swipeOffset = .zero
        }
    }
    
    // MARK: - Initialization
    
    @MainActor
    private func initializeSession() async {
        await gameSessionVM.startNewSession(for: category)
        cardInteractionVM.setGameSessionViewModel(gameSessionVM)
    }
}

// MARK: - Simple Card View

private struct SimpleCardView: View {
    let card: GameCard
    let stackPosition: Int
    let isTopCard: Bool
    let swipeOffset: CGSize
    
    private var cardColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple]
        return colors[min(stackPosition, colors.count - 1)]
    }
    
    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 20)
                .fill(cardColor.opacity(0.8))
                .stroke(cardColor, lineWidth: 2)
                .frame(width: 320, height: 420)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            // Card content
            VStack(spacing: 20) {
                // Card number indicator
                HStack {
                    Text("Card \(card.number)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Capsule())
                    Spacer()
                }
                
                Spacer()
                
                // Main prompt
                Text(card.prompt)
                    .font(.title2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                
                Spacer()
                
                // Swipe hint for top card
                if isTopCard {
                    Text("Swipe to continue")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 20)
                }
            }
            .frame(width: 320, height: 420)
        }
        .offset(swipeOffset)
        .rotationEffect(.degrees(Double(swipeOffset.width / 20)))
        .opacity(isTopCard ? 1.0 : 0.8)
    }
}

// MARK: - Supporting Views

private struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Oops!")
                .font(.title)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Try Again", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

private struct CompletionView: View {
    let onPlayAgain: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Great Job!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("You've completed all the cards in this category!")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(spacing: 15) {
                Button("Play Again", action: onPlayAgain)
                    .buttonStyle(.borderedProminent)
                
                Button("Choose New Category", action: onDismiss)
                    .buttonStyle(.bordered)
            }
        }
        .padding()
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