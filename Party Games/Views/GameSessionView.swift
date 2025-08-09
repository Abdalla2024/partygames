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
                // Clean modern dark background
                Color(red: 0.05, green: 0.05, blue: 0.07) // Modern dark background
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Clean modern title
                    Text(category.name)
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Card Stack
                    if gameSessionVM.isLoading {
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(
                                    CircularProgressViewStyle(
                                        tint: .white
                                    )
                                )
                                .scaleEffect(1.5)
                            
                            Text("Loading Cards...")
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.8))
                        }
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
        HStack(spacing: 40) {
            // Previous button
            Button(action: {
                Task { await gameSessionVM.previousCard() }
            }) {
                VStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Previous")
                        .font(.system(size: 11, weight: .medium, design: .default))
                }
                .frame(width: 70, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: gameSessionVM.canGoPrevious ? [
                                    Color(red: 0.2, green: 0.2, blue: 0.25),
                                    Color(red: 0.15, green: 0.15, blue: 0.20)
                                ] : [
                                    Color(red: 0.1, green: 0.1, blue: 0.12),
                                    Color(red: 0.08, green: 0.08, blue: 0.10)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .stroke(
                            Color(red: 0.3, green: 0.3, blue: 0.35).opacity(gameSessionVM.canGoPrevious ? 0.6 : 0.3),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .disabled(!gameSessionVM.canGoPrevious)
            .foregroundColor(gameSessionVM.canGoPrevious ? Color(red: 0.8, green: 0.8, blue: 0.9) : Color(red: 0.4, green: 0.4, blue: 0.5))
            
            // Shuffle button
            Button(action: {
                Task { await gameSessionVM.shuffleCards() }
            }) {
                VStack(spacing: 6) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Shuffle")
                        .font(.system(size: 11, weight: .medium, design: .default))
                }
                .frame(width: 70, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.13, green: 0.13, blue: 0.15))
                        .stroke(Color(red: 0.19, green: 0.19, blue: 0.22), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .foregroundColor(.white)
            
            // Skip button
            Button(action: {
                Task { await gameSessionVM.nextCard() }
            }) {
                VStack(spacing: 6) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Skip")
                        .font(.system(size: 11, weight: .medium, design: .default))
                }
                .frame(width: 70, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.13, green: 0.13, blue: 0.15))
                        .stroke(Color(red: 0.19, green: 0.19, blue: 0.22), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .foregroundColor(.white)
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
    
    var body: some View {
        ZStack {
            // Modern flat card background
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.13, green: 0.13, blue: 0.15)) // Modern card surface
                .stroke(Color(red: 0.19, green: 0.19, blue: 0.22), lineWidth: 1) // Subtle border
                .frame(width: 320, height: 420)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4) // Clean subtle shadow
            
            // Card content
            VStack(spacing: 20) {
                Spacer()
                
                // Clean modern text
                Text(card.prompt)
                    .font(.system(size: 20, weight: .medium, design: .default))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
                
                Spacer()
                
                // Clean swipe hint
                if isTopCard {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.draw")
                            .font(.caption2)
                        Text("Swipe to continue")
                            .font(.system(size: 12, weight: .medium, design: .default))
                    }
                    .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.08, green: 0.08, blue: 0.10))
                            .stroke(Color(red: 0.15, green: 0.15, blue: 0.18), lineWidth: 1)
                    )
                    .padding(.bottom, 20)
                }
            }
            .frame(width: 320, height: 420)
        }
        .offset(swipeOffset)
        .rotationEffect(.degrees(Double(swipeOffset.width / 20)))
    }
}

// MARK: - Supporting Views

private struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56, weight: .medium))
                .foregroundColor(Color(red: 1.0, green: 0.58, blue: 0.0))
            
            Text("Oops!")
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(size: 16, weight: .medium, design: .default))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.8))
                .lineSpacing(2)
            
            Button(action: onRetry) {
                Text("Try Again")
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                    .frame(width: 120, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.13, green: 0.13, blue: 0.15))
                            .stroke(Color(red: 0.19, green: 0.19, blue: 0.22), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
        .padding(32)
    }
}

private struct CompletionView: View {
    let onPlayAgain: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 88, weight: .medium))
                .foregroundColor(Color(red: 0.2, green: 0.78, blue: 0.35))
            
            Text("Great Job!")
                .font(.system(size: 32, weight: .bold, design: .default))
                .foregroundColor(.white)
            
            Text("You've completed all the cards in this category!")
                .font(.system(size: 16, weight: .medium, design: .default))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.8))
                .lineSpacing(2)
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                Button(action: onPlayAgain) {
                    Text("Play Again")
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                        .frame(width: 160, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.13, green: 0.13, blue: 0.15))
                                .stroke(Color(red: 0.19, green: 0.19, blue: 0.22), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                
                Button(action: onDismiss) {
                    Text("Choose New Category")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.8))
                        .frame(width: 160, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.19, green: 0.19, blue: 0.22), lineWidth: 1)
                        )
                }
            }
        }
        .padding(32)
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