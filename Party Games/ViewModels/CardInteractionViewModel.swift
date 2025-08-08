//
//  CardInteractionViewModel.swift
//  Party Games
//
//  Created by Mohamed Abdelmagid on 8/8/25.
//

import Foundation
import SwiftUI

/// ViewModel for managing card swipe gestures and animations in the party games app
/// Coordinates with GameSessionViewModel for card progression and state management
@Observable
final class CardInteractionViewModel {
    
    // MARK: - Gesture State Properties
    
    /// Current card offset during drag gesture
    var cardOffset: CGSize = .zero
    
    /// Card rotation based on horizontal drag distance
    var cardRotation: Double = 0.0
    
    /// Whether a drag gesture is currently active
    var isDragging: Bool = false
    
    /// Threshold distance for triggering swipe actions (in points)
    var swipeThreshold: CGFloat = 100.0
    
    /// Velocity threshold for quick swipe detection
    var velocityThreshold: CGFloat = 500.0
    
    // MARK: - Animation State Properties
    
    /// Whether a card transition animation is in progress
    var isAnimating: Bool = false
    
    /// Whether to show the next card (for stacking animations)
    var showNextCard: Bool = false
    
    /// Scale factor for the next card in stack
    var nextCardScale: CGFloat = 0.95
    
    /// Opacity for cards in the stack
    var stackCardOpacity: Double = 0.8
    
    // MARK: - Interaction Configuration
    
    /// Maximum rotation angle in degrees
    private let maxRotationDegrees: Double = 15.0
    
    /// Maximum drag distance for calculating rotation
    private let maxDragDistance: CGFloat = 200.0
    
    /// Duration for card exit animations
    private let exitAnimationDuration: Double = 0.4
    
    /// Duration for card snap-back animations
    private let snapBackDuration: Double = 0.4
    
    /// Duration for next card reveal animation
    private let revealAnimationDuration: Double = 0.3
    
    // MARK: - Dependencies
    
    /// Reference to the game session view model for card progression
    private weak var gameSessionViewModel: GameSessionViewModel?
    
    // MARK: - Computed Properties
    
    /// Current drag distance for calculations
    private var dragDistance: CGFloat {
        sqrt(cardOffset.width * cardOffset.width + cardOffset.height * cardOffset.height)
    }
    
    /// Progress percentage of swipe (0.0 to 1.0)
    var swipeProgress: Double {
        min(dragDistance / swipeThreshold, 1.0)
    }
    
    /// Whether the current drag should trigger a swipe action
    private var shouldTriggerSwipe: Bool {
        dragDistance > swipeThreshold
    }
    
    /// Determined swipe direction based on current offset
    private var swipeDirection: SwipeDirection? {
        guard shouldTriggerSwipe else { return nil }
        
        let horizontalThreshold = abs(cardOffset.width)
        let verticalThreshold = abs(cardOffset.height)
        
        if horizontalThreshold > verticalThreshold {
            return cardOffset.width > 0 ? .right : .left
        } else {
            return cardOffset.height < 0 ? .up : .down
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize with reference to GameSessionViewModel
    /// - Parameter gameSessionViewModel: The session view model to coordinate with
    init(gameSessionViewModel: GameSessionViewModel? = nil) {
        self.gameSessionViewModel = gameSessionViewModel
    }
    
    // MARK: - Gesture Handling Methods
    
    /// Handle drag gesture changes during card interaction
    /// - Parameter value: The current drag gesture value
    @MainActor
    func onDragChanged(_ value: DragGesture.Value) {
        guard !isAnimating else { return }
        
        isDragging = true
        cardOffset = value.translation
        
        // Calculate rotation based on horizontal offset
        let rotationFactor = cardOffset.width / maxDragDistance
        cardRotation = Double(rotationFactor) * maxRotationDegrees
        
        // Clamp rotation to maximum values
        cardRotation = max(-maxRotationDegrees, min(maxRotationDegrees, cardRotation))
        
        // Show next card preview when drag distance is significant
        showNextCard = dragDistance > swipeThreshold * 0.5
    }
    
    /// Handle drag gesture end and determine swipe action
    /// - Parameter value: The final drag gesture value
    @MainActor
    func onDragEnded(_ value: DragGesture.Value) async {
        guard !isAnimating else { return }
        
        isDragging = false
        let velocity = CGSize(
            width: value.predictedEndLocation.x - value.location.x,
            height: value.predictedEndLocation.y - value.location.y
        )
        
        // Check for high velocity swipe
        let velocityMagnitude = sqrt(velocity.width * velocity.width + velocity.height * velocity.height)
        let isVelocitySwipe = velocityMagnitude > velocityThreshold
        
        // Determine if we should complete the swipe
        if shouldTriggerSwipe || isVelocitySwipe {
            // Determine direction for velocity-based swipes
            let finalDirection = swipeDirection ?? getVelocityDirection(velocity)
            
            if let direction = finalDirection {
                Task {
                    await performSwipeAction(direction: direction)
                }
            } else {
                await animateSnapBack()
            }
        } else {
            await animateSnapBack()
        }
    }
    
    /// Programmatically trigger a swipe in the specified direction
    /// - Parameter direction: The direction to swipe
    @MainActor
    func swipeCard(direction: SwipeDirection) async {
        guard !isAnimating, !isDragging else { return }
        
        await performSwipeAction(direction: direction)
    }
    
    /// Reset card to center position with animation
    @MainActor
    func resetCardPosition() async {
        guard !isAnimating else { return }
        
        await animateSnapBack()
    }
    
    /// Handle specific card interaction types
    /// - Parameter interaction: The type of interaction to perform
    @MainActor
    func handleCardInteraction(_ interaction: CardInteraction) async {
        switch interaction {
        case .nextCard:
            await swipeCard(direction: .right)
        case .skipCard:
            await swipeCard(direction: .left)
        case .favoriteCard:
            await swipeCard(direction: .up)
        case .discardCard:
            await swipeCard(direction: .down)
        case .tap:
            await handleTapAction()
        }
    }
    
    // MARK: - Animation Methods
    
    /// Perform the swipe action with exit animation
    /// - Parameter direction: The swipe direction
    @MainActor
    private func performSwipeAction(direction: SwipeDirection) async {
        isAnimating = true
        
        // Calculate exit position with enhanced movement
        let exitOffset = calculateEnhancedExitOffset(for: direction)
        let exitRotation = calculateExitRotation(for: direction)
        
        // Animate card exit with smooth spring animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.1)) {
            cardOffset = exitOffset
            cardRotation = exitRotation
        }
        
        // Wait for half the animation to complete before processing
        try? await Task.sleep(nanoseconds: UInt64(exitAnimationDuration * 0.5 * 1_000_000_000))
        
        // Process the swipe action
        await processSwipeAction(direction: direction)
        
        // Complete the exit animation
        try? await Task.sleep(nanoseconds: UInt64(exitAnimationDuration * 0.5 * 1_000_000_000))
        
        // Reset and reveal next card
        await resetForNextCardWithReveal()
    }
    
    /// Animate card snapping back to center
    @MainActor
    private func animateSnapBack() async {
        isAnimating = true
        
        withAnimation(.spring(duration: snapBackDuration, bounce: 0.3)) {
            cardOffset = .zero
            cardRotation = 0.0
            showNextCard = false
        }
        
        isAnimating = false
    }
    
    /// Reset card state for the next card with reveal animation
    @MainActor
    private func resetForNextCard() async {
        // Immediately reset position
        cardOffset = .zero
        cardRotation = 0.0
        
        // Animate next card reveal
        withAnimation(.easeOut(duration: revealAnimationDuration)) {
            showNextCard = false
            nextCardScale = 0.95
        }
        
        isAnimating = false
    }
    
    /// Enhanced reset with smooth reveal animation for next card
    @MainActor
    private func resetForNextCardWithReveal() async {
        // Start with card positioned below (as if sliding up from stack)
        cardOffset = CGSize(width: 0, height: 50)
        cardRotation = 0.0
        
        // Animate card sliding up into position with spring animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.9, blendDuration: 0.1)) {
            cardOffset = .zero
            showNextCard = false
            nextCardScale = 1.0
        }
        
        isAnimating = false
    }
    
    // MARK: - Action Processing
    
    /// Process the swipe action and coordinate with session view model
    /// - Parameter direction: The swipe direction
    @MainActor
    private func processSwipeAction(direction: SwipeDirection) async {
        guard let sessionVM = gameSessionViewModel else { return }
        
        switch direction {
        case .right:
            // Move to next card
            await sessionVM.nextCard()
            
        case .left:
            // Skip card (still progress but don't mark as completed)
            await sessionVM.nextCard()
            
        case .up:
            // Mark as favorite and move to next
            if let currentCard = sessionVM.currentCard {
                currentCard.toggleFavorite()
                await sessionVM.markCardComplete()
            }
            await sessionVM.nextCard()
            
        case .down:
            // Discard card and move to next
            await sessionVM.nextCard()
        }
    }
    
    /// Handle tap action on card
    @MainActor
    private func handleTapAction() async {
        guard let sessionVM = gameSessionViewModel else { return }
        
        // Simple tap moves to next card
        await sessionVM.nextCard()
    }
    
    // MARK: - Helper Methods
    
    /// Calculate the exit offset for a given swipe direction
    /// - Parameter direction: The swipe direction
    /// - Returns: The target offset for card exit
    private func calculateExitOffset(for direction: SwipeDirection) -> CGSize {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        switch direction {
        case .right:
            return CGSize(width: screenWidth, height: cardOffset.height)
        case .left:
            return CGSize(width: -screenWidth, height: cardOffset.height)
        case .up:
            return CGSize(width: cardOffset.width, height: -screenHeight)
        case .down:
            return CGSize(width: cardOffset.width, height: screenHeight)
        }
    }
    
    /// Calculate enhanced exit offset with more natural movement
    /// - Parameter direction: The swipe direction
    /// - Returns: The calculated enhanced exit offset
    private func calculateEnhancedExitOffset(for direction: SwipeDirection) -> CGSize {
        let cardWidth: CGFloat = 320
        let cardHeight: CGFloat = 420
        let exitMultiplier: CGFloat = 1.5
        
        switch direction {
        case .right:
            return CGSize(width: cardWidth * exitMultiplier, height: cardOffset.height * 0.3)
        case .left:
            return CGSize(width: -cardWidth * exitMultiplier, height: cardOffset.height * 0.3)
        case .up:
            return CGSize(width: cardOffset.width * 0.2, height: -cardHeight * exitMultiplier)
        case .down:
            return CGSize(width: cardOffset.width * 0.2, height: cardHeight * exitMultiplier)
        }
    }
    
    /// Calculate exit rotation based on swipe direction
    /// - Parameter direction: The swipe direction
    /// - Returns: The rotation angle in degrees
    private func calculateExitRotation(for direction: SwipeDirection) -> Double {
        switch direction {
        case .right:
            return maxRotationDegrees * 1.2
        case .left:
            return -maxRotationDegrees * 1.2
        case .up:
            return cardRotation * 0.5 // Maintain current rotation but reduce it
        case .down:
            return cardRotation * 0.5
        }
    }
    
    /// Determine swipe direction based on velocity
    /// - Parameter velocity: The gesture velocity
    /// - Returns: The determined swipe direction
    private func getVelocityDirection(_ velocity: CGSize) -> SwipeDirection? {
        let horizontalMagnitude = abs(velocity.width)
        let verticalMagnitude = abs(velocity.height)
        
        if horizontalMagnitude > verticalMagnitude {
            return velocity.width > 0 ? .right : .left
        } else {
            return velocity.height < 0 ? .up : .down
        }
    }
    
    // MARK: - Configuration Methods
    
    /// Update swipe sensitivity settings
    /// - Parameters:
    ///   - threshold: Distance threshold for swipe detection
    ///   - velocityThreshold: Velocity threshold for quick swipes
    func updateSwipeSettings(threshold: CGFloat? = nil, velocityThreshold: CGFloat? = nil) {
        if let threshold = threshold {
            self.swipeThreshold = max(50, min(200, threshold))
        }
        
        if let velocityThreshold = velocityThreshold {
            self.velocityThreshold = max(200, min(1000, velocityThreshold))
        }
    }
    
    /// Set the game session view model reference
    /// - Parameter viewModel: The game session view model
    func setGameSessionViewModel(_ viewModel: GameSessionViewModel) {
        self.gameSessionViewModel = viewModel
    }
    
    // MARK: - Accessibility Support
    
    /// Perform swipe action via accessibility
    /// - Parameter direction: The direction to swipe
    @MainActor
    func performAccessibilitySwipe(direction: SwipeDirection) async {
        await swipeCard(direction: direction)
    }
}

// MARK: - Supporting Types

extension CardInteractionViewModel {
    
    /// Available swipe directions
    enum SwipeDirection: CaseIterable {
        case left
        case right
        case up
        case down
        
        var description: String {
            switch self {
            case .left:
                return "Skip"
            case .right:
                return "Next"
            case .up:
                return "Favorite"
            case .down:
                return "Discard"
            }
        }
        
        var systemImageName: String {
            switch self {
            case .left:
                return "arrow.left"
            case .right:
                return "arrow.right"
            case .up:
                return "heart.fill"
            case .down:
                return "trash"
            }
        }
    }
    
    /// Card interaction types
    enum CardInteraction: CaseIterable {
        case nextCard
        case skipCard
        case favoriteCard
        case discardCard
        case tap
        
        var swipeDirection: SwipeDirection {
            switch self {
            case .nextCard, .tap:
                return .right
            case .skipCard:
                return .left
            case .favoriteCard:
                return .up
            case .discardCard:
                return .down
            }
        }
    }
}

// MARK: - Animation Extensions

extension CardInteractionViewModel {
    
    /// Get spring animation for card interactions
    /// - Parameter type: The type of animation needed
    /// - Returns: SwiftUI animation configuration
    func getAnimation(for type: AnimationType) -> Animation {
        switch type {
        case .snapBack:
            return .spring(duration: snapBackDuration, bounce: 0.3)
        case .exit:
            return .easeInOut(duration: exitAnimationDuration)
        case .reveal:
            return .easeOut(duration: revealAnimationDuration)
        case .drag:
            return .interactiveSpring()
        }
    }
    
    /// Animation types for different card interactions
    enum AnimationType {
        case snapBack
        case exit
        case reveal
        case drag
    }
}

// MARK: - Debug Support

extension CardInteractionViewModel {
    
    /// Debug information for gesture state
    var debugInfo: String {
        """
        Card Interaction Debug:
        - Offset: \(cardOffset)
        - Rotation: \(String(format: "%.1f°", cardRotation))
        - Dragging: \(isDragging)
        - Animating: \(isAnimating)
        - Swipe Progress: \(String(format: "%.1f%%", swipeProgress * 100))
        - Should Trigger: \(shouldTriggerSwipe)
        - Direction: \(swipeDirection?.description ?? "None")
        """
    }
}

// MARK: - Platform-Specific Extensions

#if os(macOS)
extension CardInteractionViewModel {
    
    /// Handle mouse/trackpad gestures on macOS
    /// - Parameter event: The mouse event
    @MainActor
    func handleMouseGesture(_ event: NSEvent) async {
        // Convert mouse coordinates and handle similarly to touch gestures
        let location = CGPoint(x: event.locationInWindow.x, y: event.locationInWindow.y)
        
        // Implement macOS-specific gesture handling
        switch event.type {
        case .leftMouseDragged:
            let translation = CGSize(width: event.deltaX, height: -event.deltaY)
            await handleDragTranslation(translation)
            
        case .leftMouseUp:
            await onDragEnded(DragGesture.Value(
                location: location,
                startLocation: location,
                translation: cardOffset
            ))
            
        default:
            break
        }
    }
    
    /// Handle drag translation for macOS
    /// - Parameter translation: The drag translation
    @MainActor
    private func handleDragTranslation(_ translation: CGSize) async {
        cardOffset = translation
        
        let rotationFactor = cardOffset.width / maxDragDistance
        cardRotation = Double(rotationFactor) * maxRotationDegrees
        cardRotation = max(-maxRotationDegrees, min(maxRotationDegrees, cardRotation))
        
        showNextCard = dragDistance > swipeThreshold * 0.5
    }
}
#endif