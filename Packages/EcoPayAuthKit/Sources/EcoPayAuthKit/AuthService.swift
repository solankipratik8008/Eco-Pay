//
//  AuthService.swift
//  EcoPayAuthKit
//
//  Created by Pratik Solanki on 2026-05-06.
//

// AuthService.swift
// EcoPayAuthKit/Sources/EcoPayAuthKit/AuthService.swift
//
// Main authentication service that coordinates login, logout,
// token storage, and session management. Uses APIClientProtocol
// for network calls and KeychainServiceProtocol for secure storage.
// ViewModels depend on AuthServiceProtocol, not this concrete class.

import Foundation
import EcoPayNetworking

// MARK: - Auth Service Protocol

/// Contract for authentication operations.
/// AppViewModel and LoginViewModel depend on this protocol.
public protocol AuthServiceProtocol: Sendable {
    
    /// Logs in with email and password.
    /// Stores tokens in Keychain on success.
    /// - Returns: The authenticated user's profile
    func login(credentials: LoginCredentials) async throws -> UserProfile
    
    /// Logs in using a stored passkey credential.
    /// - Returns: The authenticated user's profile
    func loginWithPasskey() async throws -> UserProfile
    
    /// Logs out the user and clears all stored credentials.
    func logout() async throws
    
    /// Attempts to restore a previous session from stored tokens.
    /// - Returns: UserProfile if a valid session exists, nil otherwise
    func restoreSession() async -> UserProfile?
    
    /// Registers a new passkey for the current user.
    func registerPasskey(userId: String) async throws
    
    /// Checks if a passkey is registered on this device.
    func hasPasskeyRegistered() -> Bool
    
    /// Returns the stored access token, if available.
    func getAccessToken() -> String?
}

// MARK: - Auth Service Implementation

public final class AuthService: AuthServiceProtocol, @unchecked Sendable {
    
    // MARK: - Dependencies
    
    private let apiClient: APIClientProtocol
    private let keychain: KeychainServiceProtocol
    
    // MARK: - Keychain Keys
    // Using constants prevents key mismatches between save and read
    
    private enum Keys {
        static let accessToken = "com.ecopay.accessToken"
        static let refreshToken = "com.ecopay.refreshToken"
        static let userId = "com.ecopay.userId"
        static let userEmail = "com.ecopay.userEmail"
        static let userName = "com.ecopay.userName"
        static let passkeyCredential = "com.ecopay.passkeyCredential"
    }
    
    // MARK: - Initialization
    
    /// Creates an AuthService with injectable dependencies.
    ///
    /// - Parameters:
    ///   - apiClient: The API client to use for auth requests
    ///   - keychain: The Keychain service for secure token storage
    public init(
        apiClient: APIClientProtocol,
        keychain: KeychainServiceProtocol = KeychainService()
    ) {
        self.apiClient = apiClient
        self.keychain = keychain
    }
    
    // MARK: - Login with Email/Password
    
    public func login(credentials: LoginCredentials) async throws -> UserProfile {
        // Validate input before making a network request
        guard credentials.isValid else {
            if credentials.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !credentials.email.contains("@") {
                throw AuthError.invalidEmail
            }
            throw AuthError.invalidPassword
        }
        
        do {
            // Make the login API call
            let endpoint = EcoPayEndpoint.Login(
                email: credentials.email,
                password: credentials.password
            )
            
            let response = try await apiClient.request(
                endpoint,
                responseType: LoginResponse.self
            )
            
            // Store tokens securely in Keychain
            try storeTokens(from: response)
            
            // Create and return the user profile
            let profile = UserProfile.from(response)
            return profile
            
        } catch let error as NetworkError {
            throw AuthError.from(error)
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    // MARK: - Login with Passkey
    
    public func loginWithPasskey() async throws -> UserProfile {
        // Check if a passkey credential exists in Keychain
        guard let credentialData = try keychain.readData(key: Keys.passkeyCredential) else {
            throw AuthError.noPasskeyRegistered
        }
        
        // Decode the stored passkey credential
        let credential: PasskeyCredential
        do {
            credential = try JSONDecoder().decode(PasskeyCredential.self, from: credentialData)
        } catch {
            throw AuthError.passkeyAuthenticationFailed("Stored passkey data is corrupted.")
        }
        
        do {
            // Make the passkey login API call
            let endpoint = EcoPayEndpoint.PasskeyLogin(
                credentialId: credential.credentialId
            )
            
            let response = try await apiClient.request(
                endpoint,
                responseType: LoginResponse.self
            )
            
            // Store tokens securely
            try storeTokens(from: response)
            
            // Create and return the user profile
            let profile = UserProfile.from(response)
            return profile
            
        } catch let error as NetworkError {
            throw AuthError.from(error)
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.passkeyAuthenticationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Logout
    
    public func logout() async throws {
        do {
            // Notify the server (best-effort — we log out locally even if this fails)
            let endpoint = EcoPayEndpoint.Logout()
            try await apiClient.requestVoid(endpoint)
        } catch {
            // Server logout failed, but we still clear local data
            print("Server logout failed: \(error.localizedDescription)")
        }
        
        // Always clear local credentials regardless of server response
        try clearStoredCredentials()
    }
    
    // MARK: - Session Restoration
    
    public func restoreSession() async -> UserProfile? {
        // Check if we have a stored access token
        guard let _ = try? keychain.read(key: Keys.accessToken),
              let userId = try? keychain.read(key: Keys.userId),
              let email = try? keychain.read(key: Keys.userEmail),
              let name = try? keychain.read(key: Keys.userName) else {
            return nil
        }
        
        // Determine auth method from stored passkey
        let authMethod: AuthMethod = hasPasskeyRegistered() ? .passkey : .password
        
        // Reconstruct the user profile from stored data
        return UserProfile(
            userId: userId,
            email: email,
            name: name,
            authMethod: authMethod
        )
    }
    
    // MARK: - Passkey Registration
    
    public func registerPasskey(userId: String) async throws {
        // In a real app, this would use ASAuthorizationController
        // to create a platform credential with Face ID / Touch ID.
        // For this demo, we simulate it by storing a mock credential.
        
        let credential = PasskeyCredential(
            credentialId: "passkey_\(UUID().uuidString)",
            userId: userId,
            createdAt: Date(),
            displayName: "EcoPay Passkey"
        )
        
        do {
            let data = try JSONEncoder().encode(credential)
            try keychain.saveData(key: Keys.passkeyCredential, value: data)
        } catch {
            throw AuthError.passkeyRegistrationFailed(
                "Unable to save passkey to secure storage."
            )
        }
    }
    
    // MARK: - Passkey Check
    
    public func hasPasskeyRegistered() -> Bool {
        return keychain.exists(key: Keys.passkeyCredential)
    }
    
    // MARK: - Access Token
    
    public func getAccessToken() -> String? {
        return try? keychain.read(key: Keys.accessToken)
    }
    
    // MARK: - Private Helpers
    
    /// Stores all auth tokens and user info from a login response.
    /// Called after both password and passkey login succeed.
    private func storeTokens(from response: LoginResponse) throws {
        do {
            try keychain.save(key: Keys.accessToken, value: response.accessToken)
            try keychain.save(key: Keys.refreshToken, value: response.refreshToken)
            try keychain.save(key: Keys.userId, value: response.userId)
            try keychain.save(key: Keys.userEmail, value: response.email)
            try keychain.save(key: Keys.userName, value: response.name)
        } catch {
            throw AuthError.keychainSaveFailed
        }
    }
    
    /// Clears all stored credentials from Keychain.
    /// Called during logout. Passkey credential is preserved
    /// so the user can still use passkey login next time.
    private func clearStoredCredentials() throws {
        do {
            try keychain.delete(key: Keys.accessToken)
            try keychain.delete(key: Keys.refreshToken)
            try keychain.delete(key: Keys.userId)
            try keychain.delete(key: Keys.userEmail)
            try keychain.delete(key: Keys.userName)
            // Note: we keep the passkey credential so user can
            // use passkey login even after logging out
        } catch {
            throw AuthError.keychainDeleteFailed
        }
    }
}
