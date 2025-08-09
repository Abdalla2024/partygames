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
        ZStack {
            // Completely black background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Title with game icon - proper spacing from top
//                HStack(spacing: 12) {
//                    Image(category.iconName)
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(width: 32, height: 32)
//                        .clipShape(RoundedRectangle(cornerRadius: 8))
//                    
//                    Text(category.name)
//                        .font(.system(size: 22, weight: .semibold, design: .default))
//                        .foregroundColor(.white)
//                }
//                .padding(.top, 44) // Apple guidelines: 44pt from top for content under navigation
                
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
                
                // Control buttons with proper bottom spacing
                controlButtons
                    .padding(.bottom, 44) // Apple guidelines: 34pt from bottom for safe area content
            }
            .padding(.horizontal)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .medium))
                        Text("Back")
                            .font(.system(size: 17, weight: .regular))
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .task {
            await initializeSession()
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
        HStack(spacing: 22) {
            // Palette (matches the card without over-saturating the bar)
            let surface          = Color(red: 0.10, green: 0.12, blue: 0.13)   // charcoal
            let surfaceDisabled  = Color(red: 0.08, green: 0.09, blue: 0.10)
            let stroke           = Color(red: 0.16, green: 0.18, blue: 0.20)   // muted slate
            let strokeDisabled   = Color(red: 0.12, green: 0.13, blue: 0.15)
            let accentTeal       = Color(red: 0.118, green: 0.890, blue: 0.824) // #1EE3D2
            let labelPrimary     = Color.white.opacity(0.92)
            let labelSecondary   = Color.white.opacity(0.55)

            // Previous
            Button(action: { Task { await gameSessionVM.previousCard() } }) {
                VStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(gameSessionVM.canGoPrevious ? labelPrimary : labelSecondary)
                    Text("Previous")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(gameSessionVM.canGoPrevious ? labelPrimary : labelSecondary)
                }
                .frame(width: 84, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: [
                            surface.opacity(0.98), surface.opacity(0.95)
                        ], startPoint: .top, endPoint: .bottom))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(gameSessionVM.canGoPrevious ? stroke : strokeDisabled, lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 8)
            }
            .disabled(!gameSessionVM.canGoPrevious)

            // Shuffle (make this the accented control)
            Button(action: { Task { await gameSessionVM.shuffleCards() } }) {
                VStack(spacing: 6) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accentTeal)
                    Text("Shuffle")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(accentTeal.opacity(0.95))
                }
                .frame(width: 96, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: [
                            surface.opacity(0.98), surface.opacity(0.95)
                        ], startPoint: .top, endPoint: .bottom))
                        .overlay(
                            // subtle teal edge to echo the card rim
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(accentTeal.opacity(0.35), lineWidth: 1)
                        )
                )
                .shadow(color: accentTeal.opacity(0.25), radius: 16, x: 0, y: 10)
                .shadow(color: .black.opacity(0.45), radius: 14, x: 0, y: 10)
            }

            // Skip
            Button(action: { Task { await gameSessionVM.nextCard() } }) {
                VStack(spacing: 6) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(labelPrimary)
                    Text("Skip")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(labelPrimary)
                }
                .frame(width: 84, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: [
                            surface.opacity(0.98), surface.opacity(0.95)
                        ], startPoint: .top, endPoint: .bottom))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(stroke, lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 8)
            }
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
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                // Teal surface (like the mockup)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.055, green: 0.247, blue: 0.255), // #0E3F41 (top)
                            Color(red: 0.039, green: 0.373, blue: 0.349)  // #0A5F59 (bottom)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                // Cyan/teal edge highlight
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color(red: 0.118, green: 0.890, blue: 0.824).opacity(0.45), lineWidth: 2) // #1EE3D2 @ 45%
                )
                // Soft outer glow + lift
                .shadow(color: Color(red: 0.118, green: 0.890, blue: 0.824).opacity(0.10), radius: 12, x: 0, y: 12)
                .shadow(color: .black.opacity(0.30), radius: 14, x: 0, y: 20)
                .frame(width: 320, height: 460)
            
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
