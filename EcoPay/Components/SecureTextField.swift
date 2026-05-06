//
//  SecureTextField.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//
// SecureTextField.swift
// EcoPayApp/Components/SecureTextField.swift
//
// Reusable text field with icon, placeholder, error highlighting,
// and optional password visibility toggle. Used for email and
// password inputs on the login screen and other forms.

import SwiftUI

struct AppTextField: View {
    
    // MARK: - Properties
    
    let placeholder: String
    let icon: String
    @Binding var text: String
    var isSecure: Bool = false
    var isPasswordVisible: Bool = false
    var hasError: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .never
    var onToggleVisibility: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            // Leading icon
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(hasError ? .red : .secondary)
                .frame(width: 24)
            
            // Text input
            if isSecure && !isPasswordVisible {
                SecureField(placeholder, text: $text)
                    .textContentType(textContentType)
                    .autocorrectionDisabled()
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
            }
            
            // Password visibility toggle
            if isSecure {
                Button(action: {
                    onToggleVisibility?()
                }) {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
            }
            
            // Clear button (non-secure fields only)
            if !isSecure && !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(hasError ? Color.red : Color.clear, lineWidth: 1.5)
        )
        .animation(AppTheme.Animation.quick, value: hasError)
    }
}

// MARK: - Convenience Initializers

extension AppTextField {
    /// Creates an email text field with appropriate keyboard and content type.
    static func email(
        text: Binding<String>,
        hasError: Bool = false
    ) -> AppTextField {
        AppTextField(
            placeholder: "Email address",
            icon: "envelope.fill",
            text: text,
            hasError: hasError,
            keyboardType: .emailAddress,
            textContentType: .emailAddress
        )
    }
    
    /// Creates a password field with visibility toggle.
    static func password(
        text: Binding<String>,
        isVisible: Bool = false,
        hasError: Bool = false,
        onToggleVisibility: (() -> Void)? = nil
    ) -> AppTextField {
        AppTextField(
            placeholder: "Password",
            icon: "lock.fill",
            text: text,
            isSecure: true,
            isPasswordVisible: isVisible,
            hasError: hasError,
            textContentType: .password,
            onToggleVisibility: onToggleVisibility
        )
    }
}

// MARK: - Preview

#Preview("Text Fields") {
    VStack(spacing: 16) {
        AppTextField.email(
            text: .constant("demo@ecopay.com")
        )
        
        AppTextField.email(
            text: .constant("bad-email"),
            hasError: true
        )
        
        AppTextField.password(
            text: .constant("password123"),
            isVisible: false
        )
        
        AppTextField.password(
            text: .constant("password123"),
            isVisible: true,
            hasError: true
        )
        
        AppTextField(
            placeholder: "Recipient name",
            icon: "person.fill",
            text: .constant("Alex Johnson")
        )
    }
    .padding()
}
