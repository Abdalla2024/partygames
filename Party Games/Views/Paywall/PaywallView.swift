//
//  PaywallView.swift
//  Party Games
//
//  Created by Claude on 8/9/25.
//

import SwiftUI

/// Paywall view displaying subscription options
struct PaywallView: View {
    
    // MARK: - Properties
    
    @State var storeKitManager: StoreKitManager
    @State private var selectedPlan: String = "lifetimeplan" // Default to lifetime
    
    let onPurchaseComplete: () -> Void
    let onDismiss: (() -> Void)?
    
    // MARK: - Initialization
    
    init(
        storeKitManager: StoreKitManager,
        onPurchaseComplete: @escaping () -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self._storeKitManager = State(initialValue: storeKitManager)
        self.onPurchaseComplete = onPurchaseComplete
        self.onDismiss = onDismiss
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Black background matching app theme
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Header
                headerSection
                
                // Premium Features
                premiumFeaturesSection
                
                // Subscription Plans
                subscriptionPlansSection
                
                // Action Buttons
                actionButtonsSection
                
                // Footer
                footerSection
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            
            // Close Button (always show X button in top right)
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: { onDismiss?() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 24)
                .padding(.trailing, 28)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Crown Icon
            Image(systemName: "crown.fill")
                .font(.system(size: 48, weight: .medium))
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
                .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 8) {
                Text("Unlock Premium")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundColor(.white)
                
                Text("Get access to all game categories")
                    .font(.system(size: 18, weight: .medium, design: .default))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 40) // Always account for X button
    }
    
    // MARK: - Premium Features Section
    
    private var premiumFeaturesSection: some View {
        VStack(spacing: 20) {
            PremiumFeatureRow(
                icon: "star.fill",
                title: "All Game Categories",
                description: "Access Truth or Dare, Would You Rather, and more!"
            )
            
            PremiumFeatureRow(
                icon: "infinity",
                title: "Unlimited Games",
                description: "No limits on how much you can play"
            )
            
            PremiumFeatureRow(
                icon: "heart.fill",
                title: "Premium Content",
                description: "Exclusive questions and challenges"
            )
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Subscription Plans Section
    
    private var subscriptionPlansSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.system(size: 22, weight: .semibold, design: .default))
                .foregroundColor(.white)
                .padding(.bottom, 8)
            
            VStack(spacing: 12) {
                // Lifetime Plan
                SubscriptionCard(
                    title: "Lifetime Plan",
                    price: storeKitManager.lifetimeDisplayPrice,
                    originalPrice: "$169.99", // Crossed out original price
                    subtitle: "Pay once, own forever",
                    badge: "BEST VALUE",
                    isSelected: selectedPlan == "lifetimeplan",
                    badgeColor: Color(red: 0.118, green: 0.890, blue: 0.824)
                ) {
                    selectedPlan = "lifetimeplan"
                }
                
                // Weekly Plan
                SubscriptionCard(
                    title: "Weekly Plan",
                    price: storeKitManager.weeklyDisplayPrice + "/week",
                    originalPrice: nil, // No original price for weekly
                    subtitle: "3-day free trial",
                    badge: nil,
                    isSelected: selectedPlan == "weekly_399",
                    badgeColor: nil
                ) {
                    selectedPlan = "weekly_399"
                }
            }
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Continue Button
            Button(action: purchaseSelectedPlan) {
                HStack {
                    if storeKitManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold, design: .default))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.118, green: 0.890, blue: 0.824), // #1EE3D2
                                    Color(red: 0.098, green: 0.760, blue: 0.704)  // Darker teal
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: Color(red: 0.118, green: 0.890, blue: 0.824).opacity(0.4), radius: 16, x: 0, y: 8)
            }
            .disabled(storeKitManager.isLoading)
            
            // Restore Purchases Button
            Button(action: { Task { await storeKitManager.restorePurchases() } }) {
                Text("Restore Purchases")
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 8) {
            if let errorMessage = storeKitManager.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)
            }
            
            Text("Cancel anytime. No commitments.")
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Actions
    
    private func purchaseSelectedPlan() {
        Task {
            let product = selectedPlan == "lifetimeplan" ? storeKitManager.lifetimeProduct : storeKitManager.weeklyProduct
            
            guard let product = product else {
                storeKitManager.errorMessage = "Product not available"
                return
            }
            
            await storeKitManager.purchase(product)
            
            // Check if purchase was successful
            if storeKitManager.hasPremiumAccess && storeKitManager.errorMessage == nil {
                onPurchaseComplete()
            }
        }
    }
}

// MARK: - Premium Feature Row

private struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(red: 0.118, green: 0.890, blue: 0.824))
                .frame(width: 24, height: 24)
            
            // Text Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
    }
}

// MARK: - Subscription Card

private struct SubscriptionCard: View {
    let title: String
    let price: String
    let originalPrice: String?
    let subtitle: String
    let badge: String?
    let isSelected: Bool
    let badgeColor: Color?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Left side - Content
                VStack(alignment: .leading, spacing: 6) {
                    // Badge and title row
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 18, weight: .bold, design: .default))
                            .foregroundColor(.white)
                        
                        if let badge = badge, let badgeColor = badgeColor {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold, design: .default))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(badgeColor)
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                    }
                    
                    // Price with optional original price
                    HStack(spacing: 8) {
                        if let originalPrice = originalPrice {
                            Text(originalPrice)
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundColor(.white.opacity(0.5))
                                .strikethrough()
                        }
                        
                        Text(price)
                            .font(.system(size: 20, weight: .heavy, design: .default))
                            .foregroundColor(Color(red: 0.118, green: 0.890, blue: 0.824))
                    }
                    
                    // Subtitle
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium, design: .default))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Right side - Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(
                        isSelected ? Color(red: 0.118, green: 0.890, blue: 0.824) : .white.opacity(0.4)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(height: 90) // Compact height
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.055, green: 0.247, blue: 0.255), // #0E3F41
                                Color(red: 0.039, green: 0.373, blue: 0.349)  // #0A5F59
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                isSelected ? Color(red: 0.118, green: 0.890, blue: 0.824) : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? Color(red: 0.118, green: 0.890, blue: 0.824).opacity(0.25) : .black.opacity(0.15),
                radius: isSelected ? 12 : 6,
                x: 0,
                y: isSelected ? 6 : 3
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Paywall View") {
    PaywallView(
        storeKitManager: StoreKitManager(),
        onPurchaseComplete: {
            print("Purchase completed")
        },
        onDismiss: {
            print("Dismissed")
        }
    )
}
