//
//  AppTheme.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

// AppTheme.swift
// EcoPayApp/Utilities/AppTheme.swift
//
// Centralized design system for Eco-Pay.
// Contains all colors, fonts, spacing, and corner radius values
// used throughout the app. This ensures visual consistency
// and makes it easy to update the design in one place.

import SwiftUI

// MARK: - App Theme

enum AppTheme {
    
    // MARK: - Colors
    
    enum Colors {
        // Primary brand color — used for buttons, links, and key actions
        static let primary = Color("PrimaryColor", bundle: nil)
        
        // Fallback programmatic colors if asset catalog colors are not set up yet.
        // These work in both light and dark mode automatically.
        static let primaryFallback = Color(red: 0.0, green: 0.48, blue: 1.0)
        
        // Background colors
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let groupedBackground = Color(.systemGroupedBackground)
        
        // Text colors
        static let primaryText = Color(.label)
        static let secondaryText = Color(.secondaryLabel)
        static let tertiaryText = Color(.tertiaryLabel)
        
        // Semantic colors for transaction states
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let pending = Color.yellow
        
        // Card gradient colors — gives the wallet card a premium look
        static let cardGradientStart = Color(red: 0.1, green: 0.1, blue: 0.3)
        static let cardGradientEnd = Color(red: 0.2, green: 0.15, blue: 0.5)
        
        // Card gradient used across wallet card components
        static let cardGradient = LinearGradient(
            colors: [cardGradientStart, cardGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Typography
    // Predefined font styles so every screen uses consistent sizing.
    
    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        
        // Special styles for financial data
        static let balance = Font.system(size: 40, weight: .bold, design: .rounded)
        static let amount = Font.system(size: 24, weight: .semibold, design: .monospaced)
        static let cardNumber = Font.system(size: 18, weight: .medium, design: .monospaced)
    }
    
    // MARK: - Spacing
    // Consistent spacing values based on an 4pt grid system.
    
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let card: CGFloat = 20
        static let button: CGFloat = 12
    }
    
    // MARK: - Shadows
    // Reusable shadow configurations for cards and elevated elements.
    
    enum Shadow {
        static let color = Color.black.opacity(0.1)
        static let radius: CGFloat = 10
        static let x: CGFloat = 0
        static let y: CGFloat = 4
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
    }
}

// MARK: - View Extensions
// Convenience modifiers that apply theme values cleanly.

extension View {
    /// Applies the standard card shadow to any view
    func cardShadow() -> some View {
        self.shadow(
            color: AppTheme.Shadow.color,
            radius: AppTheme.Shadow.radius,
            x: AppTheme.Shadow.x,
            y: AppTheme.Shadow.y
        )
    }
    
    /// Wraps any view in a standard card container with background and rounded corners
    func cardStyle() -> some View {
        self
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(AppTheme.CornerRadius.card)
            .cardShadow()
    }
}
