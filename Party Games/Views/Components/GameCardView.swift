//
//  GameCardView.swift
//  Party Games
//
//  Created by Claude on 8/8/25.
//

import SwiftUI

/// A reusable swipeable card component for displaying game cards
/// Integrates with CardInteractionViewModel for gesture handling and animations
struct GameCardView: View {
    
    // MARK: - Properties
    
    /// The game card to display
    let card: GameCard
    
    /// View model for handling swipe gestures and animations
    @Bindable var cardInteractionVM: CardInteractionViewModel
    
    /// Card size configuration
    var cardSize: CGSize = CGSize(width: 300, height: 400)
    
    /// Whether to show the category indicator
    var showCategory: Bool = true
    
    /// Whether the card responds to gestures
    var isInteractive: Bool = true
    
    /// Visual state of the card
    var cardState: CardState = .normal
    
    /// Color scheme for the card based on category
    var colorScheme: CardColorScheme = .default
    
    // MARK: - Computed Properties
    
    /// Dynamic card background based on category and state
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(backgroundGradient)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
    
    /// Background gradient based on color scheme and card state
    private var backgroundGradient: LinearGradient {
        switch cardState {
        case .normal:
            return LinearGradient(
                colors: colorScheme.backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dragging:
            return LinearGradient(
                colors: colorScheme.backgroundColors.map { $0.opacity(0.9) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .completing:
            return LinearGradient(
                colors: colorScheme.backgroundColors.map { $0.opacity(0.7) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .disabled:
            return LinearGradient(
                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    /// Border color based on card state
    private var borderColor: Color {
        switch cardState {
        case .normal:
            return colorScheme.borderColor
        case .dragging:
            return colorScheme.accentColor
        case .completing:
            return Color.green
        case .disabled:
            return Color.gray.opacity(0.3)
        }
    }
    
    /// Border width based on card state
    private var borderWidth: CGFloat {
        switch cardState {
        case .normal: return 1
        case .dragging: return 2
        case .completing: return 3
        case .disabled: return 1
        }
    }
    
    /// Shadow configuration based on card state and drag
    private var shadowRadius: CGFloat {
        let baseShadow: CGFloat = 8
        let dragMultiplier = abs(cardInteractionVM.cardOffset.width) / 100
        
        switch cardState {
        case .normal:
            return baseShadow + (dragMultiplier * 4)
        case .dragging:
            return baseShadow + (dragMultiplier * 6)
        case .completing:
            return baseShadow + 4
        case .disabled:
            return baseShadow / 2
        }
    }
    
    /// Card scale based on interaction state
    private var cardScale: CGFloat {
        switch cardState {
        case .normal:
            return 1.0
        case .dragging:
            let dragProgress = min(cardInteractionVM.swipeProgress, 1.0)
            return 1.0 + (dragProgress * 0.05) // Slight scale up during drag
        case .completing:
            return 0.95
        case .disabled:
            return 0.95
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Card Background
            cardBackground
                .frame(width: cardSize.width, height: cardSize.height)
                .shadow(
                    color: Color.black.opacity(0.15),
                    radius: shadowRadius,
                    x: 2,
                    y: 4
                )
            
            // Card Content
            VStack(spacing: 20) {
                // Category Header
                if showCategory {
                    categoryHeader
                }
                
                Spacer(minLength: 10)
                
                // Main Prompt Text
                promptText
                
                Spacer(minLength: 10)
                
                // Card Footer
                cardFooter
            }
            .padding(24)
            .frame(width: cardSize.width, height: cardSize.height)
            
            // Swipe Direction Indicators
            if isInteractive && cardInteractionVM.isDragging {
                swipeIndicators
            }
            
            // Favorite indicator
            if card.isFavorite {
                favoriteIndicator
            }
        }
        .scaleEffect(cardScale)
        .rotationEffect(.degrees(cardInteractionVM.cardRotation))
        .offset(cardInteractionVM.cardOffset)
        .opacity(cardOpacity)
        .animation(.spring(duration: 0.3, bounce: 0.2), value: cardState)
        .animation(.interactiveSpring(), value: cardInteractionVM.cardOffset)
        .gesture(
            isInteractive ? 
            DragGesture()
                .onChanged(cardInteractionVM.onDragChanged)
                .onEnded { value in
                    Task {
                        await cardInteractionVM.onDragEnded(value)
                    }
                }
            : nil
        )
        .onTapGesture {
            if isInteractive {
                Task {
                    await cardInteractionVM.handleCardInteraction(.tap)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityActions {
            if isInteractive {
                Button("Next Card") {
                    Task {
                        await cardInteractionVM.handleCardInteraction(.nextCard)
                    }
                }
                
                Button("Skip Card") {
                    Task {
                        await cardInteractionVM.handleCardInteraction(.skipCard)
                    }
                }
                
                Button("Favorite Card") {
                    Task {
                        await cardInteractionVM.handleCardInteraction(.favoriteCard)
                    }
                }
                
                Button("Discard Card") {
                    Task {
                        await cardInteractionVM.handleCardInteraction(.discardCard)
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Category header with icon and name
    private var categoryHeader: some View {
        HStack(spacing: 8) {
            // Category Icon
            if let uiImage = UIImage(named: card.category?.iconName ?? "") {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(colorScheme.accentColor)
            }
            
            // Category Name
            Text(card.categoryName)
                .font(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .foregroundColor(colorScheme.secondaryTextColor)
            
            Spacer()
            
            // Card Number
            Text("Card \(card.number)")
                .font(.caption2)
                .foregroundColor(colorScheme.secondaryTextColor.opacity(0.7))
        }
    }
    
    /// Main prompt text with dynamic sizing
    private var promptText: some View {
        Text(card.prompt)
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(colorScheme.primaryTextColor)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .minimumScaleFactor(0.7)
            .allowsTightening(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .fixedSize(horizontal: false, vertical: false)
    }
    
    /// Card footer with difficulty and usage indicators
    private var cardFooter: some View {
        HStack {
            // Difficulty Level
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { level in
                    Circle()
                        .fill(level <= card.difficultyLevel ? colorScheme.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            
            Spacer()
            
            // Usage Count (if > 0)
            if card.usageCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "repeat")
                        .font(.caption2)
                    Text("\(card.usageCount)")
                        .font(.caption2)
                }
                .foregroundColor(colorScheme.secondaryTextColor.opacity(0.7))
            }
        }
    }
    
    /// Swipe direction indicators during drag
    private var swipeIndicators: some View {
        VStack {
            // Up indicator (Favorite)
            if cardInteractionVM.cardOffset.height < -30 {
                swipeHint(direction: .up, isActive: cardInteractionVM.cardOffset.height < -60)
                    .transition(.scale.combined(with: .opacity))
            }
            
            Spacer()
            
            HStack {
                // Left indicator (Skip)
                if cardInteractionVM.cardOffset.width < -30 {
                    swipeHint(direction: .left, isActive: cardInteractionVM.cardOffset.width < -60)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
                
                // Right indicator (Next)
                if cardInteractionVM.cardOffset.width > 30 {
                    swipeHint(direction: .right, isActive: cardInteractionVM.cardOffset.width > 60)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            Spacer()
            
            // Down indicator (Discard)
            if cardInteractionVM.cardOffset.height > 30 {
                swipeHint(direction: .down, isActive: cardInteractionVM.cardOffset.height > 60)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.2), value: cardInteractionVM.cardOffset)
    }
    
    /// Individual swipe hint indicator
    private func swipeHint(direction: CardInteractionViewModel.SwipeDirection, isActive: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: direction.systemImageName)
                .font(.title2)
                .foregroundColor(isActive ? direction.activeColor : direction.inactiveColor)
            
            Text(direction.description)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(isActive ? direction.activeColor : direction.inactiveColor)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(isActive ? 0.7 : 0.4))
        )
        .scaleEffect(isActive ? 1.1 : 0.9)
        .opacity(isActive ? 1.0 : 0.7)
    }
    
    /// Favorite indicator overlay
    private var favoriteIndicator: some View {
        VStack {
            HStack {
                Spacer()
                
                Image(systemName: "heart.fill")
                    .font(.title3)
                    .foregroundColor(.red)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 32, height: 32)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
            }
            
            Spacer()
        }
        .padding(16)
    }
    
    // MARK: - Computed Properties for State
    
    /// Opacity based on card state
    private var cardOpacity: Double {
        switch cardState {
        case .normal, .dragging: return 1.0
        case .completing: return 0.8
        case .disabled: return 0.6
        }
    }
    
    /// Accessibility label for the card
    private var accessibilityLabel: String {
        var label = "\(card.categoryName) card \(card.number). \(card.prompt)"
        
        if card.isFavorite {
            label += ". Marked as favorite"
        }
        
        label += ". Difficulty level \(card.difficultyLevel) out of 5"
        
        if card.usageCount > 0 {
            label += ". Used \(card.usageCount) time\(card.usageCount == 1 ? "" : "s")"
        }
        
        return label
    }
    
    /// Accessibility hint for interaction
    private var accessibilityHint: String {
        guard isInteractive else { return "This card is not interactive" }
        
        return "Swipe right to go to next card, swipe left to skip, swipe up to favorite, swipe down to discard, or double tap to advance"
    }
}

// MARK: - Supporting Types

extension GameCardView {
    
    /// Visual states for the card
    enum CardState {
        case normal
        case dragging
        case completing
        case disabled
    }
    
    /// Color scheme for card appearance
    struct CardColorScheme {
        let backgroundColors: [Color]
        let primaryTextColor: Color
        let secondaryTextColor: Color
        let accentColor: Color
        let borderColor: Color
        
        static let `default` = CardColorScheme(
            backgroundColors: [
                Color.blue.opacity(0.1),
                Color.purple.opacity(0.1)
            ],
            primaryTextColor: .primary,
            secondaryTextColor: .secondary,
            accentColor: .blue,
            borderColor: Color.blue.opacity(0.3)
        )
        
        static let truthOrDare = CardColorScheme(
            backgroundColors: [
                Color.red.opacity(0.1),
                Color.orange.opacity(0.1)
            ],
            primaryTextColor: .primary,
            secondaryTextColor: .secondary,
            accentColor: .red,
            borderColor: Color.red.opacity(0.3)
        )
        
        static let wouldYouRather = CardColorScheme(
            backgroundColors: [
                Color.green.opacity(0.1),
                Color.mint.opacity(0.1)
            ],
            primaryTextColor: .primary,
            secondaryTextColor: .secondary,
            accentColor: .green,
            borderColor: Color.green.opacity(0.3)
        )
        
        static let neverHaveIEver = CardColorScheme(
            backgroundColors: [
                Color.purple.opacity(0.1),
                Color.pink.opacity(0.1)
            ],
            primaryTextColor: .primary,
            secondaryTextColor: .secondary,
            accentColor: .purple,
            borderColor: Color.purple.opacity(0.3)
        )
        
        /// Get color scheme based on category name
        static func forCategory(_ categoryName: String) -> CardColorScheme {
            switch categoryName.lowercased() {
            case "truth or dare":
                return .truthOrDare
            case "would you rather":
                return .wouldYouRather
            case "never have i ever":
                return .neverHaveIEver
            default:
                return .default
            }
        }
    }
}

// MARK: - SwipeDirection Extensions

extension CardInteractionViewModel.SwipeDirection {
    
    /// Active color when swipe is triggered
    var activeColor: Color {
        switch self {
        case .left: return .orange
        case .right: return .green
        case .up: return .red
        case .down: return .gray
        }
    }
    
    /// Inactive color when swipe is not triggered
    var inactiveColor: Color {
        Color.white.opacity(0.8)
    }
}

// MARK: - Initialization Helpers

extension GameCardView {
    
    /// Initialize with category-based color scheme
    init(card: GameCard, 
         cardInteractionVM: CardInteractionViewModel,
         cardSize: CGSize = CGSize(width: 300, height: 400),
         showCategory: Bool = true,
         isInteractive: Bool = true,
         cardState: CardState = .normal) {
        
        self.card = card
        self.cardInteractionVM = cardInteractionVM
        self.cardSize = cardSize
        self.showCategory = showCategory
        self.isInteractive = isInteractive
        self.cardState = cardState
        self.colorScheme = CardColorScheme.forCategory(card.categoryName)
    }
}

// MARK: - Preview

#Preview("Interactive Card") {
    VStack {
        GameCardView(
            card: GameCard(
                number: 1,
                prompt: "If you could have dinner with any historical figure, who would it be and why?",
                difficultyLevel: 3
            ),
            cardInteractionVM: CardInteractionViewModel(),
            cardSize: CGSize(width: 320, height: 420)
        )
        
        Spacer()
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Card Stack") {
    ZStack {
        // Background cards
        ForEach(0..<3, id: \.self) { index in
            GameCardView(
                card: GameCard(
                    number: index + 2,
                    prompt: "Sample prompt for card \(index + 2)",
                    difficultyLevel: 2
                ),
                cardInteractionVM: CardInteractionViewModel(),
                cardSize: CGSize(width: 300, height: 400),
                isInteractive: false
            )
            .scaleEffect(1.0 - (CGFloat(index) * 0.05))
            .offset(y: CGFloat(index) * 5)
            .opacity(0.7 - (Double(index) * 0.2))
        }
        
        // Front card
        GameCardView(
            card: GameCard(
                number: 1,
                prompt: "What's your biggest fear and how do you deal with it?",
                difficultyLevel: 4
            ),
            cardInteractionVM: CardInteractionViewModel(),
            cardSize: CGSize(width: 300, height: 400)
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Different States") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            GameCardView(
                card: GameCard(number: 1, prompt: "Normal State", difficultyLevel: 1),
                cardInteractionVM: CardInteractionViewModel(),
                cardSize: CGSize(width: 140, height: 180),
                isInteractive: false,
                cardState: .normal
            )
            
            GameCardView(
                card: GameCard(number: 2, prompt: "Dragging State", difficultyLevel: 2),
                cardInteractionVM: CardInteractionViewModel(),
                cardSize: CGSize(width: 140, height: 180),
                isInteractive: false,
                cardState: .dragging
            )
        }
        
        HStack(spacing: 20) {
            GameCardView(
                card: GameCard(number: 3, prompt: "Completing State", difficultyLevel: 3),
                cardInteractionVM: CardInteractionViewModel(),
                cardSize: CGSize(width: 140, height: 180),
                isInteractive: false,
                cardState: .completing
            )
            
            GameCardView(
                card: GameCard(number: 4, prompt: "Disabled State", difficultyLevel: 4),
                cardInteractionVM: CardInteractionViewModel(),
                cardSize: CGSize(width: 140, height: 180),
                isInteractive: false,
                cardState: .disabled
            )
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}