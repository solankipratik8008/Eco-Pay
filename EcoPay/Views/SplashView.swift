//
//  SplashView.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

// SplashView.swift
// EcoPayApp/Views/SplashView.swift
//
// Animated splash screen shown during app initialization.
// Displays while AppViewModel checks for stored session.
// Professional first impression for portfolio screenshots.

import SwiftUI

struct SplashView: View {
    
    @State private var isAnimating = false
    @State private var showTagline = false
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()
            
            // Animated app icon
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 3)
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                
                // Inner circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)
                    .shadow(color: .blue.opacity(0.3), radius: 20, y: 8)
                
                // Icon
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(.white)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
            }
            .animation(
                .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                value: isAnimating
            )
            
            // App name
            VStack(spacing: AppTheme.Spacing.xs) {
                Text(AppConstants.App.name)
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                
                if showTagline {
                    Text(AppConstants.App.tagline)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            
            Spacer()
            
            // Loading indicator
            VStack(spacing: AppTheme.Spacing.sm) {
                ProgressView()
                    .scaleEffect(1.1)
                
                Text("Securing your wallet...")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background)
        .onAppear {
            isAnimating = true
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                showTagline = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Splash Screen") {
    SplashView()
}
