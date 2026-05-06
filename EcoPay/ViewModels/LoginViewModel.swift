//
//  LoginViewModel.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

// LoginViewModel.swift
// EcoPayApp/ViewModels/LoginViewModel.swift
//
// Manages login form state, input validation, and authentication.
// Delegates actual auth operations to AppViewModel while handling
// form-specific concerns like field validation and error display.

import SwiftUI
import EcoPayAuthKit
import Combine

// MARK: - Login ViewModel

@MainActor
final class LoginViewModel: ObservableObject {
    
    // MARK: - Form State
    
    /// Email input from the text field
    @Published var email: String = ""
    
    /// Password input from the text field
    @Published var password: String = ""
    
    /// Controls password visibility toggle
    @Published var isPasswordVisible: Bool = false
    
    // MARK: - UI State
    
    /// Whether a login request is in progress
    @Published var isLoading: Bool = false
    
    /// Error message shown below the form
    @Published var errorMessage: String?
    
    /// Which field has a validation error (for highlighting)
    @Published var errorField: LoginField?
    
    /// Whether passkey login is available on this device
    @Published var isPasskeyAvailable: Bool = false
    
    /// Show success animation briefly before transitioning
    @Published var showSuccess: Bool = false
    
    // MARK: - Dependencies
    
    /// Reference to the parent AppViewModel for auth operations
    private weak var appViewModel: AppViewModel?
    
    // MARK: - Initialization
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        
        // Check if a passkey is registered on this device
        self.isPasskeyAvailable = appViewModel.passkeyService.isRegistered
    }
    
    // MARK: - Computed Properties
    
    /// Whether the login button should be enabled.
    /// Requires non-empty email and password, and no active request.
    var isLoginEnabled: Bool {
        return !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isLoading
    }
    
    /// Whether the form has any content (for showing clear button)
    var hasInput: Bool {
        return !email.isEmpty || !password.isEmpty
    }
    
    // MARK: - Login with Password
    
    /// Validates input and triggers login through AppViewModel.
    func login() async {
        // Clear previous errors
        clearError()
        
        // Validate email
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            showFieldError(.email, message: "Please enter your email address.")
            return
        }
        
        guard trimmedEmail.isValidEmail else {
            showFieldError(.email, message: "Please enter a valid email address.")
            return
        }
        
        // Validate password
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPassword.isEmpty else {
            showFieldError(.password, message: "Please enter your password.")
            return
        }
        
        guard trimmedPassword.count >= 8 else {
            showFieldError(.password, message: "Password must be at least 8 characters.")
            return
        }
        
        // All validation passed — attempt login
        isLoading = true
        
        await appViewModel?.login(
            email: trimmedEmail,
            password: trimmedPassword
        )
        
        // Check if login failed (AppViewModel sets authState to .error)
        if let appViewModel, case .error(let message) = appViewModel.authState {
            errorMessage = message
            isLoading = false
        } else {
            // Login succeeded — show brief success state
            showSuccess = true
            
            // Small delay so the user sees the success feedback
            try? await Task.sleep(nanoseconds: 500_000_000)
            isLoading = false
        }
    }
    
    // MARK: - Login with Passkey
    
    /// Triggers passkey authentication through AppViewModel.
    func loginWithPasskey() async {
        clearError()
        isLoading = true
        
        await appViewModel?.loginWithPasskey()
        
        // Check result
        if let appViewModel, case .error(let message) = appViewModel.authState {
            errorMessage = message
            isLoading = false
        } else {
            showSuccess = true
            try? await Task.sleep(nanoseconds: 500_000_000)
            isLoading = false
        }
    }
    
    // MARK: - Demo Autofill
    
    /// Fills in the demo credentials for easy testing.
    /// Shows in the UI as a "Use Demo Account" button.
    func fillDemoCredentials() {
        withAnimation(AppTheme.Animation.standard) {
            email = AppConstants.MockUser.email
            password = AppConstants.MockUser.password
            clearError()
        }
    }
    
    // MARK: - Form Management
    
    /// Clears all form fields and errors.
    func clearForm() {
        withAnimation(AppTheme.Animation.standard) {
            email = ""
            password = ""
            isPasswordVisible = false
            clearError()
        }
    }
    
    /// Clears error state without clearing form fields.
    func clearError() {
        errorMessage = nil
        errorField = nil
        
        // Also clear AppViewModel error state if needed
        if let appViewModel, case .error = appViewModel.authState {
            appViewModel.clearError()
        }
    }
    
    /// Toggles password visibility.
    func togglePasswordVisibility() {
        isPasswordVisible.toggle()
    }
    
    // MARK: - Private Helpers
    
    /// Shows an error message and highlights the relevant field.
    private func showFieldError(_ field: LoginField, message: String) {
        withAnimation(AppTheme.Animation.quick) {
            errorMessage = message
            errorField = field
        }
    }
}

// MARK: - Login Field

/// Identifies which form field has an error.
/// Used to apply red border/highlight to the correct field.
enum LoginField: Equatable {
    case email
    case password
}

