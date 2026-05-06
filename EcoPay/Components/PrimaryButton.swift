//
//  PrimaryButton.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

// PrimaryButton.swift
// EcoPayApp/Components/PrimaryButton.swift
//
// Reusable primary action button used across the app.
// Handles loading state, disabled state, and consistent styling.
// Used for Login, Send Payment, Add Card, and other primary actions.

import SwiftUI

struct PrimaryButton: View {
    
    // MARK: - Properties
    
    let title: String
    let icon: String?
    let isLoading: Bool
    let isEnabled: Bool
    let style: ButtonStyle
    let action: () -> Void
    
    // MARK: - Initialization
    
    init(
        title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        style: ButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.style = style
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            if isEnabled && !isLoading {
                action()
            }
        }) {
            HStack(spacing: AppTheme.Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.textColor))
                        .scaleEffect(0.9)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    Text(title)
                        .font(AppTheme.Typography.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor)
            .foregroundStyle(style.textColor)
            .cornerRadius(AppTheme.CornerRadius.button)
        }
        .disabled(!isEnabled || isLoading)
        .animation(AppTheme.Animation.quick, value: isLoading)
        .animation(AppTheme.Animation.quick, value: isEnabled)
    }
    
    // MARK: - Computed Colors
    
    private var backgroundColor: Color {
        if !isEnabled || isLoading {
            return style.backgroundColor.opacity(0.5)
        }
        return style.backgroundColor
    }
}

// MARK: - Button Styles

extension PrimaryButton {
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        case outline
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .blue
            case .secondary: return AppTheme.Colors.secondaryBackground
            case .destructive: return .red
            case .outline: return .clear
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return AppTheme.Colors.primaryText
            case .destructive: return .white
            case .outline: return .blue
            }
        }
    }
}

// MARK: - Preview

#Preview("Primary Button States") {
    VStack(spacing: 16) {
        PrimaryButton(title: "Sign In", icon: "arrow.right") {}
        
        PrimaryButton(title: "Signing In...", isLoading: true) {}
        
        PrimaryButton(title: "Sign In", isEnabled: false) {}
        
        PrimaryButton(
            title: "Use Passkey",
            icon: "person.badge.key.fill",
            style: .secondary
        ) {}
        
        PrimaryButton(
            title: "Log Out",
            icon: "rectangle.portrait.and.arrow.right",
            style: .destructive
        ) {}
        
        PrimaryButton(
            title: "Cancel",
            style: .outline
        ) {}
    }
    .padding()
}
