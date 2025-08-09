//
//  OnboardingView.swift
//  Party Games
//
//  Created by Claude on 8/9/25.
//

import SwiftUI

/// Onboarding view showcasing app features and benefits
struct OnboardingView: View {
    
    // MARK: - Properties
    
    let onContinue: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Black background matching app theme
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // App Icon and Welcome
                VStack(spacing: 24) {
                    // App Icon
                    Image("partygamesicon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: Color(red: 0.118, green: 0.890, blue: 0.824).opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    // Welcome Title
                    VStack(spacing: 8) {
                        Text("Welcome to")
                            .font(.system(size: 24, weight: .medium, design: .default))
                            .foregroundColor(Color.white.opacity(0.8))
                        
                        Text("Party Games")
                            .font(.system(size: 36, weight: .bold, design: .default))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                // Features List
                VStack(spacing: 32) {
                    FeatureRow(
                        icon: "gamecontroller.fill",
                        title: "10 Game Categories",
                        description: "Truth or Dare, Would You Rather, and more!"
                    )
                    
                    FeatureRow(
                        icon: "rectangle.stack.fill",
                        title: "Hundreds of Cards",
                        description: "Never run out of fun questions and challenges"
                    )
                    
                    FeatureRow(
                        icon: "hand.draw.fill",
                        title: "Swipe to Play",
                        description: "Intuitive card-based gameplay"
                    )
                    
                    FeatureRow(
                        icon: "person.3.fill",
                        title: "Perfect for Groups",
                        description: "Great for parties, dates, and hanging out"
                    )
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Continue Button
                Button(action: onContinue) {
                    HStack(spacing: 12) {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .foregroundColor(.white)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
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
                    .shadow(color: Color(red: 0.118, green: 0.890, blue: 0.824).opacity(0.4), radius: 20, x: 0, y: 8)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 44)
            }
        }
    }
}

// MARK: - Feature Row Component

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0.118, green: 0.890, blue: 0.824).opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color(red: 0.118, green: 0.890, blue: 0.824))
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 15, weight: .regular, design: .default))
                    .foregroundColor(Color.white.opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
    }
}

// MARK: - Previews

#Preview("Onboarding View") {
    OnboardingView {
        print("Continue tapped")
    }
}
