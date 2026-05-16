//
//  AppViewModel.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

// EcoPayApp.swift
// EcoPayApp/App/EcoPayApp.swift
//
// Main entry point for the Eco-Pay wallet application.
// Creates AppViewModel and injects it into the environment.
// AppViewModel.swift
// EcoPayApp/ViewModels/AppViewModel.swift
//
// The root ViewModel for the entire app. Manages authentication
// state, initializes all shared services, and provides them
// to child ViewModels. Injected into the SwiftUI environment
// from EcoPayApp.swift so every view can access it.

import SwiftUI
import EcoPayNetworking
import EcoPayAuthKit
import EcoPayPayments
import EcoPayAnalytics
import Combine
import FirebaseAuth

// MARK: - App ViewModel

@MainActor
public final class AppViewModel: ObservableObject {
    
    // MARK: - Published State
    
    /// The current authentication state — drives the root navigation.
    /// When this changes, RootView switches between login and dashboard.
    @Published var authState: AuthState = .unauthenticated
    
    /// Global loading state for splash/initialization.
    @Published var isInitializing: Bool = true
    
    /// Global error message shown as an alert.
    @Published var globalError: String?
    
    /// Controls whether the global error alert is showing.
    @Published var showGlobalError: Bool = false
    
    // MARK: - Shared Services
    // These are created once and shared across all ViewModels.
    // Using protocols means we can swap mock/real implementations.
    
    let apiClient: APIClientProtocol
    let authService: AuthServiceProtocol
    let passkeyService: PasskeyServiceProtocol
    let paymentService: PaymentServiceProtocol
    let analyticsService: AnalyticsServiceProtocol
    
    // MARK: - Computed Properties
    
    /// Convenience check used by RootView to decide which screen to show.
    var isAuthenticated: Bool {
        return authState.isAuthenticated
    }
    
    /// The current user's profile, if logged in.
    var currentUser: UserProfile? {
        return authState.userProfile
    }
    
    // MARK: - Initialization
    
    /// Creates the AppViewModel with all dependencies.
    /// Default parameters use MockAPIClient for the portfolio demo.
    /// To switch to a real backend, pass URLSessionAPIClient() instead.
    init(
        apiClient: APIClientProtocol? = nil,
        keychainService: KeychainServiceProtocol? = nil,
        analyticsService: AnalyticsServiceProtocol? = nil
    ) {
        let client = apiClient ?? MockAPIClient()
        let keychain = keychainService ?? KeychainService()
        let analytics = analyticsService ?? ConsoleAnalyticsService()

        self.apiClient = client
        self.analyticsService = analytics

        // Firebase Auth is now used for real login, registration, logout,
        // Firestore user profile creation, and session restore.
        self.authService = FirebaseAuthService()

        // Passkey support stays local/demo for now.
        // We can connect real passkeys later if needed.
        self.passkeyService = PasskeyAuthService(
            keychain: keychain
        )

        // Payment service is still mock/API-based for now.
        // Next phase will connect wallet balance and transactions to Firestore.
        self.paymentService = PaymentService(
            apiClient: client
        )
    }
    
    // MARK: - Session Restoration
    
    /// Called on app launch to check if the user was previously logged in.
    /// If valid tokens exist in Keychain, skips the login screen.
    private func restoreSession() async {
        print("EcoPay restore session started")
        isInitializing = true
        
        try? await Task.sleep(nanoseconds: 700_000_000)
        
        authState = .unauthenticated
        isInitializing = false
        
        print("EcoPay restore session finished")
    }
    
    // MARK: - Login
    
    /// Logs in with email and password.
    /// Called by LoginViewModel after input validation.
    func login(email: String, password: String) async {
        authState = .loading
        
        let credentials = LoginCredentials(
            email: email,
            password: password
        )
        
        do {
            let profile = try await authService.login(credentials: credentials)
            authState = .authenticated(profile)
            analyticsService.track(.loginSuccess(method: "password"))
        } catch let error as AuthError {
            authState = .error(error.localizedDescription)
            analyticsService.track(
                .loginFailed(reason: error.localizedDescription)
            )
        } catch {
            authState = .error(error.localizedDescription)
            analyticsService.track(
                .loginFailed(reason: error.localizedDescription)
            )
        }
    }
    
    // MARK: - Register

    /// Registers a new user with Firebase Auth and creates
    /// their Firestore user profile and wallet document.
    func register(name: String, email: String, password: String) async {
        authState = .loading
        
        guard let firebaseAuthService = authService as? FirebaseAuthService else {
            authState = .error("Firebase registration service is not available.")
            return
        }
        
        do {
            let profile = try await firebaseAuthService.register(
                email: email,
                password: password,
                name: name
            )
            
            authState = .authenticated(profile)
            analyticsService.track(.loginSuccess(method: "firebase_register"))
        } catch let error as AuthError {
            authState = .error(error.localizedDescription)
            analyticsService.track(
                .loginFailed(reason: error.localizedDescription)
            )
        } catch {
            authState = .error(error.localizedDescription)
            analyticsService.track(
                .loginFailed(reason: error.localizedDescription)
            )
        }
    }
    // MARK: - Passkey Login
    
    /// Logs in using a stored passkey credential.
    /// Called by LoginViewModel when the passkey button is tapped.
    func loginWithPasskey() async {
        authState = .loading
        analyticsService.track(.passkeyLoginAttempt())
        
        do {
            let profile = try await authService.loginWithPasskey()
            authState = .authenticated(profile)
            analyticsService.track(.loginSuccess(method: "passkey"))
        } catch let error as AuthError {
            authState = .error(error.localizedDescription)
            analyticsService.track(
                .loginFailed(reason: error.localizedDescription)
            )
        } catch {
            authState = .error(error.localizedDescription)
        }
    }
    
    // MARK: - Logout
    
    /// Logs out the user and returns to the login screen.
    /// Clears all stored credentials and resets app state.
    func logout() async {
        do {
            try await authService.logout()
        } catch {
            // Log but don't block — we still want to clear local state
            print("Logout error: \(error.localizedDescription)")
        }
        
        authState = .unauthenticated
        analyticsService.track(.logout())
    }
    
    // MARK: - Error Handling
    
    /// Shows a global error alert. Used for errors that don't
    /// belong to a specific screen (e.g., session expiry).
    func showError(_ message: String) {
        globalError = message
        showGlobalError = true
    }
    
    /// Clears the current error state.
    /// Called when the user dismisses the error alert.
    func clearError() {
        globalError = nil
        showGlobalError = false
        
        // If the auth state is .error, reset it to unauthenticated
        if case .error = authState {
            authState = .unauthenticated
        }
    }
    
    /// Handles auth errors from child ViewModels.
    /// If the error requires re-login, forces logout.
    func handleAuthError(_ error: AuthError) async {
        if error.requiresReLogin {
            await logout()
            showError("Your session has expired. Please log in again.")
        } else {
            showError(error.localizedDescription)
        }
    }
}
