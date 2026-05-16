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

// MARK: - Auth Screen Mode

enum AuthScreenMode {
    case login
    case register
    
    var title: String {
        switch self {
        case .login:
            return "Welcome Back"
        case .register:
            return "Create Account"
        }
    }
    
    var subtitle: String {
        switch self {
        case .login:
            return "Sign in to continue using EcoPay."
        case .register:
            return "Create your EcoPay wallet account."
        }
    }
    
    var primaryButtonTitle: String {
        switch self {
        case .login:
            return "Sign In"
        case .register:
            return "Create Account"
        }
    }
    
    var switchPrompt: String {
        switch self {
        case .login:
            return "Don't have an account?"
        case .register:
            return "Already have an account?"
        }
    }
    
    var switchButtonTitle: String {
        switch self {
        case .login:
            return "Create one"
        case .register:
            return "Sign in"
        }
    }
}

// MARK: - Login ViewModel

@MainActor
final class LoginViewModel: ObservableObject {
    
    // MARK: - Form State
    
    @Published var mode: AuthScreenMode = .login
    
    /// Full name input used during registration.
    @Published var fullName: String = ""
    
    /// Email input from the text field.
    @Published var email: String = ""
    
    /// Password input from the text field.
    @Published var password: String = ""
    
    /// Controls password visibility toggle.
    @Published var isPasswordVisible: Bool = false
    
    // MARK: - UI State
    
    /// Whether an auth request is in progress.
    @Published var isLoading: Bool = false
    
    /// Error message shown below the form.
    @Published var errorMessage: String?
    
    /// Which field has a validation error.
    @Published var errorField: LoginField?
    
    /// Whether passkey login is available on this device.
    @Published var isPasskeyAvailable: Bool = false
    
    /// Show success animation briefly before transitioning.
    @Published var showSuccess: Bool = false
    
    // MARK: - Dependencies
    
    /// Reference to the parent AppViewModel for auth operations.
    private weak var appViewModel: AppViewModel?
    
    // MARK: - Initialization
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        self.isPasskeyAvailable = appViewModel.passkeyService.isRegistered
    }
    
    // MARK: - Computed Properties
    
    var isLoginMode: Bool {
        mode == .login
    }
    
    var isRegisterMode: Bool {
        mode == .register
    }
    
    /// Whether the primary button should be enabled.
    var isPrimaryButtonEnabled: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if isRegisterMode {
            return !trimmedName.isEmpty
                && !trimmedEmail.isEmpty
                && !trimmedPassword.isEmpty
                && !isLoading
        }
        
        return !trimmedEmail.isEmpty
            && !trimmedPassword.isEmpty
            && !isLoading
    }
    
    /// Keeps backward compatibility if your LoginView still uses this name.
    var isLoginEnabled: Bool {
        isPrimaryButtonEnabled
    }
    
    /// Whether the form has any content.
    var hasInput: Bool {
        return !fullName.isEmpty || !email.isEmpty || !password.isEmpty
    }
    
    // MARK: - Submit
    
    /// Handles the main button tap.
    func submit() async {
        switch mode {
        case .login:
            await login()
        case .register:
            await register()
        }
    }
    
    // MARK: - Login with Password
    
    func login() async {
        clearError()
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            showFieldError(.email, message: "Please enter your email address.")
            return
        }
        
        guard trimmedEmail.isValidEmail else {
            showFieldError(.email, message: "Please enter a valid email address.")
            return
        }
        
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPassword.isEmpty else {
            showFieldError(.password, message: "Please enter your password.")
            return
        }
        
        guard trimmedPassword.count >= 8 else {
            showFieldError(.password, message: "Password must be at least 8 characters.")
            return
        }
        
        isLoading = true
        
        await appViewModel?.login(
            email: trimmedEmail,
            password: trimmedPassword
        )
        
        handleAuthResult()
    }
    
    // MARK: - Register
    
    func register() async {
        clearError()
        
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            showFieldError(.fullName, message: "Please enter your full name.")
            return
        }
        
        guard trimmedName.count >= 2 else {
            showFieldError(.fullName, message: "Name must be at least 2 characters.")
            return
        }
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            showFieldError(.email, message: "Please enter your email address.")
            return
        }
        
        guard trimmedEmail.isValidEmail else {
            showFieldError(.email, message: "Please enter a valid email address.")
            return
        }
        
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPassword.isEmpty else {
            showFieldError(.password, message: "Please enter your password.")
            return
        }
        
        guard trimmedPassword.count >= 8 else {
            showFieldError(.password, message: "Password must be at least 8 characters.")
            return
        }
        
        isLoading = true
        
        await appViewModel?.register(
            name: trimmedName,
            email: trimmedEmail,
            password: trimmedPassword
        )
        
        handleAuthResult()
    }
    
    // MARK: - Login with Passkey
    
    func loginWithPasskey() async {
        clearError()
        isLoading = true
        
        await appViewModel?.loginWithPasskey()
        
        handleAuthResult()
    }
    
    // MARK: - Demo Autofill
    
    func fillDemoCredentials() {
        withAnimation(AppTheme.Animation.standard) {
            mode = .login
            fullName = ""
            email = AppConstants.MockUser.email
            password = AppConstants.MockUser.password
            clearError()
        }
    }
    
    // MARK: - Form Management
    
    func toggleMode() {
        withAnimation(AppTheme.Animation.standard) {
            mode = mode == .login ? .register : .login
            clearError()
            isPasswordVisible = false
        }
    }
    
    func clearForm() {
        withAnimation(AppTheme.Animation.standard) {
            fullName = ""
            email = ""
            password = ""
            isPasswordVisible = false
            clearError()
        }
    }
    
    func clearError() {
        errorMessage = nil
        errorField = nil
        
        if let appViewModel, case .error = appViewModel.authState {
            appViewModel.clearError()
        }
    }
    
    func togglePasswordVisibility() {
        isPasswordVisible.toggle()
    }
    
    // MARK: - Private Helpers
    
    private func handleAuthResult() {
        if let appViewModel, case .error(let message) = appViewModel.authState {
            errorMessage = message
            isLoading = false
        } else {
            showSuccess = true
            
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                isLoading = false
            }
        }
    }
    
    private func showFieldError(_ field: LoginField, message: String) {
        withAnimation(AppTheme.Animation.quick) {
            errorMessage = message
            errorField = field
        }
    }
}

// MARK: - Login Field

enum LoginField: Equatable {
    case fullName
    case email
    case password
}
