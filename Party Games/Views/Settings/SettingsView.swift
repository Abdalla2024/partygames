//
//  SettingsView.swift
//  Party Games
//
//  Created by Claude on 8/10/25.
//

import SwiftUI
import StoreKit
import SwiftData

/// Settings view with subscription management and app utilities
struct SettingsView: View {
    
    // MARK: - Properties
    
    /// StoreKit manager for premium purchases
    @State private var storeKitManager: StoreKitManager
    
    /// User preferences for premium status
    @State private var userPreferences: UserPreferences?
    
    /// Model context for SwiftData operations
    let modelContext: ModelContext
    
    /// Paywall presentation state
    @State private var showingPaywall = false
    
    /// Dismissal action
    let onDismiss: () -> Void
    
    // MARK: - Initialization
    
    init(storeKitManager: StoreKitManager, modelContext: ModelContext, onDismiss: @escaping () -> Void) {
        self._storeKitManager = State(initialValue: storeKitManager)
        self.modelContext = modelContext
        self.onDismiss = onDismiss
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Black background matching app theme
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Settings List
                    settingsListSection
                    
                    Spacer()
                    
                    // Footer
                    footerSection
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(Color(red: 0.118, green: 0.890, blue: 0.824))
                }
            }
            .task {
                loadUserPreferences()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(
                    storeKitManager: storeKitManager,
                    onPurchaseComplete: {
                        handlePurchaseComplete()
                    },
                    onDismiss: {
                        showingPaywall = false
                    }
                )
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon
            Image("partygamesicon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color(red: 0.118, green: 0.890, blue: 0.824).opacity(0.3), radius: 12, x: 0, y: 6)
            
            VStack(spacing: 4) {
                Text("Party Games")
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .foregroundColor(.white)
                
                if hasPremiumAccess {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12, weight: .medium))
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
                        
                        Text("Premium")
                            .font(.system(size: 14, weight: .semibold, design: .default))
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.1))
                    .clipShape(Capsule())
                } else {
                    Text("Free Version")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 32)
    }
    
    // MARK: - Settings List Section
    
    private var settingsListSection: some View {
        VStack(spacing: 12) {
            // Subscribe to Pro (only show if not premium)
            if !hasPremiumAccess {
                SettingsRowButton(
                    icon: "crown.fill",
                    title: "Subscribe to Pro",
                    subtitle: "Unlock all premium games",
                    iconColor: Color(red: 1.0, green: 0.84, blue: 0.0),
                    showChevron: true
                ) {
                    showingPaywall = true
                }
            }
            
            // Rate This App and Unlock a Gift
            SettingsRowButton(
                icon: "heart.fill",
                title: "Rate This App and Unlock a Gift",
                subtitle: "Help us improve and get rewarded",
                iconColor: Color(red: 0.118, green: 0.890, blue: 0.824),
                showChevron: true
            ) {
                requestAppReview()
            }
            
            // Privacy Policy
            SettingsRowButton(
                icon: "hand.raised.fill",
                title: "Privacy Policy",
                subtitle: "How we protect your data",
                iconColor: Color(red: 0.118, green: 0.890, blue: 0.824),
                showChevron: true
            ) {
                openPrivacyPolicy()
            }
            
            // Terms of Service
            SettingsRowButton(
                icon: "doc.text.fill",
                title: "Terms of Service",
                subtitle: "App usage terms and conditions",
                iconColor: Color(red: 0.118, green: 0.890, blue: 0.824),
                showChevron: true
            ) {
                openTermsOfService()
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("Version 1.0.0")
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Made with ❤️ for great parties")
                .font(.system(size: 12, weight: .regular, design: .default))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.bottom, 32)
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
    
    // MARK: - Actions
    
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
    }
    
    private func requestAppReview() {
        // Request app store review using StoreKit
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
    
    private func openPrivacyPolicy() {
        // Open privacy policy URL
        if let url = URL(string: "https://abdalla2024.github.io/GameNight/privacy.html") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openTermsOfService() {
        // Open terms of service URL
        if let url = URL(string: "https://abdalla2024.github.io/GameNight/terms.html") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Settings Row Button

private struct SettingsRowButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let showChevron: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular, design: .default))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Chevron
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Settings View") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: GameCategory.self, GameCard.self, GameSession.self, UserPreferences.self, configurations: config)
    
    SettingsView(
        storeKitManager: StoreKitManager(),
        modelContext: container.mainContext,
        onDismiss: {
            print("Settings dismissed")
        }
    )
}
