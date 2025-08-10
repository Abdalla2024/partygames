//
//  UserPreferences.swift
//  Party Games
//
//  Created by Claude on 8/9/25.
//

import Foundation
import SwiftData

/// User preferences and subscription status management
@Model
final class UserPreferences {
    /// Unique identifier for the preferences record
    @Attribute(.unique) var id: UUID
    
    /// Whether the user has completed the onboarding flow
    var hasSeenOnboarding: Bool
    
    /// Whether the user has an active premium subscription
    var hasPremiumAccess: Bool
    
    /// Type of subscription the user has
    var subscriptionType: String?
    
    /// When the subscription was purchased or last verified
    var subscriptionDate: Date?
    
    /// When the subscription expires (for weekly subscriptions)
    var subscriptionExpirationDate: Date?
    
    /// Whether the user has rated the app
    var hasRatedApp: Bool
    
    /// When the rating prompt was last shown
    var ratingPromptDate: Date?
    
    /// Whether the user has seen the rating prompt
    var hasSeenRatingPrompt: Bool
    
    /// Creation date
    var createdAt: Date
    
    /// Last update date
    var updatedAt: Date
    
    init(
        hasSeenOnboarding: Bool = false,
        hasPremiumAccess: Bool = false,
        subscriptionType: String? = nil,
        subscriptionDate: Date? = nil,
        subscriptionExpirationDate: Date? = nil,
        hasRatedApp: Bool = false,
        ratingPromptDate: Date? = nil,
        hasSeenRatingPrompt: Bool = false
    ) {
        self.id = UUID()
        self.hasSeenOnboarding = hasSeenOnboarding
        self.hasPremiumAccess = hasPremiumAccess
        self.subscriptionType = subscriptionType
        self.subscriptionDate = subscriptionDate
        self.subscriptionExpirationDate = subscriptionExpirationDate
        self.hasRatedApp = hasRatedApp
        self.ratingPromptDate = ratingPromptDate
        self.hasSeenRatingPrompt = hasSeenRatingPrompt
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// Update subscription status
    func updateSubscription(
        type: String,
        hasPremium: Bool = true,
        expirationDate: Date? = nil
    ) {
        self.subscriptionType = type
        self.hasPremiumAccess = hasPremium
        self.subscriptionDate = Date()
        self.subscriptionExpirationDate = expirationDate
        self.updatedAt = Date()
    }
    
    /// Mark onboarding as completed
    func completeOnboarding() {
        self.hasSeenOnboarding = true
        self.updatedAt = Date()
    }
    
    /// Mark app as rated
    func markAppAsRated() {
        self.hasRatedApp = true
        self.updatedAt = Date()
    }
    
    /// Mark rating prompt as seen
    func markRatingPromptSeen() {
        self.hasSeenRatingPrompt = true
        self.ratingPromptDate = Date()
        self.updatedAt = Date()
    }
    
    /// Check if subscription is still valid (for weekly subscriptions)
    var isSubscriptionValid: Bool {
        guard hasPremiumAccess else { return false }
        
        // Lifetime subscription - always valid if hasPremiumAccess is true
        guard let expirationDate = subscriptionExpirationDate else {
            return true
        }
        
        // Weekly subscription - check expiration
        return Date() < expirationDate
    }
    
    /// Get or create the singleton user preferences
    static func getCurrentPreferences(from modelContext: ModelContext) -> UserPreferences {
        let descriptor = FetchDescriptor<UserPreferences>()
        
        do {
            let preferences = try modelContext.fetch(descriptor)
            if let existing = preferences.first {
                return existing
            }
        } catch {
            print("Error fetching user preferences: \(error)")
        }
        
        // Create new preferences if none exist
        let newPreferences = UserPreferences()
        modelContext.insert(newPreferences)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving new user preferences: \(error)")
        }
        
        return newPreferences
    }
}

// MARK: - Subscription Types
extension UserPreferences {
    enum SubscriptionType {
        static let weekly = "weekly_399"
        static let lifetime = "lifetimeplan"
    }
}