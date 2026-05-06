//
//  PasskeyAuthService.swift
//  EcoPayAuthKit
//
//  Created by Pratik Solanki on 2026-05-06.
//

// PasskeyAuthService.swift
// EcoPayAuthKit/Sources/EcoPayAuthKit/PasskeyAuthService.swift
//
// Dedicated service for passkey/FIDO2 operations.
// Simulates the passkey registration and authentication flow
// that would use ASAuthorizationController in a real app.
// Manages passkey credential lifecycle and provides
// status information for the Security Settings screen.

import Foundation

// MARK: - Passkey Service Protocol

/// Contract for passkey-specific operations.
/// SecurityViewModel depends on this to manage passkey settings.
public protocol PasskeyServiceProtocol: Sendable {
    
    /// Registers a new passkey for the given user.
    /// In a real app, this would trigger Face ID / Touch ID.
    func register(userId: String, displayName: String) async throws -> PasskeyCredential
    
    /// Removes the stored passkey from this device.
    func removePasskey() async throws
    
    /// Returns the stored passkey credential, if one exists.
    func getStoredCredential() -> PasskeyCredential?
    
    /// Returns true if a passkey is registered on this device.
    var isRegistered: Bool { get }
    
    /// Returns information about the passkey setup for display.
    func getPasskeyInfo() -> PasskeyInfo?
}

// MARK: - Passkey Info

/// Display-friendly information about the registered passkey.
/// Used by SecuritySettingsView to show passkey status.
public struct PasskeyInfo: Sendable {
    /// Display name of the passkey
    public let displayName: String
    
    /// When the passkey was created
    public let createdAt: Date
    
    /// The user ID associated with this passkey
    public let userId: String
    
    /// Formatted creation date for display
    public var createdDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    public init(displayName: String, createdAt: Date, userId: String) {
        self.displayName = displayName
        self.createdAt = createdAt
        self.userId = userId
    }
}

// MARK: - Passkey Auth Service

public final class PasskeyAuthService: PasskeyServiceProtocol, @unchecked Sendable {
    
    // MARK: - Dependencies
    
    private let keychain: KeychainServiceProtocol
    private let keychainKey = "com.ecopay.passkeyCredential"
    
    // MARK: - Initialization
    
    public init(keychain: KeychainServiceProtocol = KeychainService()) {
        self.keychain = keychain
    }
    
    // MARK: - Registration
    
    public func register(userId: String, displayName: String) async throws -> PasskeyCredential {
        // Simulate the time it takes for biometric verification
        // In a real app, this is where ASAuthorizationController
        // would present the Face ID / Touch ID prompt
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Simulate platform authenticator creating a credential
        // In a real FIDO2 flow:
        // 1. Server sends a challenge
        // 2. Device creates a public/private key pair
        // 3. Private key is stored in Secure Enclave
        // 4. Public key is sent to server
        // 5. Server stores the public key for future verification
        //
        // For this demo, we generate a mock credential ID
        
        let credential = PasskeyCredential(
            credentialId: generateCredentialId(),
            userId: userId,
            createdAt: Date(),
            displayName: displayName
        )
        
        // Store the credential in Keychain
        do {
            let data = try JSONEncoder().encode(credential)
            try keychain.saveData(key: keychainKey, value: data)
            return credential
        } catch {
            throw AuthError.passkeyRegistrationFailed(
                "Unable to store passkey securely on this device."
            )
        }
    }
    
    // MARK: - Remove Passkey
    
    public func removePasskey() async throws {
        // Simulate processing time
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        do {
            try keychain.delete(key: keychainKey)
        } catch {
            throw AuthError.keychainDeleteFailed
        }
    }
    
    // MARK: - Get Stored Credential
    
    public func getStoredCredential() -> PasskeyCredential? {
        guard let data = try? keychain.readData(key: keychainKey) else {
            return nil
        }
        
        return try? JSONDecoder().decode(PasskeyCredential.self, from: data)
    }
    
    // MARK: - Registration Check
    
    public var isRegistered: Bool {
        return keychain.exists(key: keychainKey)
    }
    
    // MARK: - Passkey Info
    
    public func getPasskeyInfo() -> PasskeyInfo? {
        guard let credential = getStoredCredential() else {
            return nil
        }
        
        return PasskeyInfo(
            displayName: credential.displayName,
            createdAt: credential.createdAt,
            userId: credential.userId
        )
    }
    
    // MARK: - Private Helpers
    
    /// Generates a mock credential ID that looks like a real FIDO2 credential.
    /// Real credential IDs are base64-encoded byte arrays from the authenticator.
    private func generateCredentialId() -> String {
        // Create a realistic-looking credential ID
        // Format: "passkey" prefix + UUID for uniqueness
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return "passkey_\(uuid)"
    }
}

// MARK: - Mock Passkey Service

/// Mock implementation for SwiftUI previews and testing.
/// Provides controllable passkey state without touching Keychain.
public final class MockPasskeyService: PasskeyServiceProtocol, @unchecked Sendable {
    
    // MARK: - Controllable State
    
    /// Set this to control whether the mock has a registered passkey
    public var mockCredential: PasskeyCredential?
    
    /// Set this to make registration fail for testing error states
    public var shouldFailRegistration: Bool = false
    
    /// Set this to make removal fail for testing error states
    public var shouldFailRemoval: Bool = false
    
    public init(hasPasskey: Bool = false) {
        if hasPasskey {
            self.mockCredential = PasskeyCredential(
                credentialId: "mock_passkey_001",
                userId: "user_001",
                createdAt: Date(),
                displayName: "Demo Passkey"
            )
        }
    }
    
    // MARK: - PasskeyServiceProtocol
    
    public func register(userId: String, displayName: String) async throws -> PasskeyCredential {
        // Simulate delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        if shouldFailRegistration {
            throw AuthError.passkeyRegistrationFailed("Simulated registration failure")
        }
        
        let credential = PasskeyCredential(
            credentialId: "mock_passkey_\(UUID().uuidString.prefix(8))",
            userId: userId,
            createdAt: Date(),
            displayName: displayName
        )
        
        mockCredential = credential
        return credential
    }
    
    public func removePasskey() async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
        
        if shouldFailRemoval {
            throw AuthError.keychainDeleteFailed
        }
        
        mockCredential = nil
    }
    
    public func getStoredCredential() -> PasskeyCredential? {
        return mockCredential
    }
    
    public var isRegistered: Bool {
        return mockCredential != nil
    }
    
    public func getPasskeyInfo() -> PasskeyInfo? {
        guard let credential = mockCredential else { return nil }
        
        return PasskeyInfo(
            displayName: credential.displayName,
            createdAt: credential.createdAt,
            userId: credential.userId
        )
    }
}
