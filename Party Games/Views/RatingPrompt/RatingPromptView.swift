//
//  RatingPromptView.swift
//  Party Games
//
//  Created by Claude on 8/11/25.
//

import SwiftUI
import StoreKit

/// Rating prompt view that encourages users to rate the app to unlock "This or That" category
struct RatingPromptView: View {
    
    // MARK: - Properties
    
    /// Completion handler when user rates the app
    let onRatingComplete: () -> Void
    
    /// Dismissal handler when user chooses "Maybe Later"
    let onDismiss: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Black background matching app theme
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Header
                headerSection
                
                // Feature showcase
                featureSection
                
                // Action buttons
                actionButtonsSection
                
                // Footer
                footerSection
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
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
            
            VStack(spacing: 8) {
                Text("Rate Our App")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundColor(.white)
                
                Text("Unlock This or That Game")
                    .font(.system(size: 18, weight: .medium, design: .default))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 40)
    }
    
    // MARK: - Feature Section
    
    private var featureSection: some View {
        VStack(spacing: 20) {
            // Gift unlock explanation
            VStack(spacing: 16) {
                // Star icon with glow effect
                Image(systemName: "star.fill")
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
                    .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4), radius: 12, x: 0, y: 6)
                
                VStack(spacing: 12) {
                    Text("Get a Special Gift!")
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Rate our app in the App Store and unlock the \"This or That\" game category for free!")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
            }
            
            // Benefits showcase
            VStack(spacing: 16) {
                RatingBenefitRow(
                    icon: "gamecontroller.fill",
                    title: "This or That Game",
                    description: "Fun choices and dilemmas to explore"
                )
                
                RatingBenefitRow(
                    icon: "heart.fill", 
                    title: "Support Our Work",
                    description: "Help us create even better party games"
                )
                
                RatingBenefitRow(
                    icon: "gift.fill",
                    title: "Completely Free",
                    description: "No subscription required for this unlock"
                )
            }
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Rate Now Button
            Button(action: handleRateApp) {
                HStack {
                    Text("Rate Now")
                        .font(.system(size: 18, weight: .semibold, design: .default))
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
            
            // Maybe Later Button
            Button(action: onDismiss) {
                Text("Maybe Later")
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("Takes less than 30 seconds")
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Actions
    
    private func handleRateApp() {
        // Request app store review using StoreKit
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
        
        // Mark as rated and complete the flow
        // Note: We assume the user will rate when prompted, as we can't reliably detect completion
        onRatingComplete()
    }
}

// MARK: - Rating Benefit Row

private struct RatingBenefitRow: View {
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

// MARK: - Previews

#Preview("Rating Prompt View") {
    RatingPromptView(
        onRatingComplete: {
            print("Rating completed")
        },
        onDismiss: {
            print("Rating prompt dismissed")
        }
    )
}
