//
//  AuthModels.swift
//  EcoPayAuthKit
//
//  Created by Pratik Solanki on 2026-05-06.
//
// AuthModels.swift
// EcoPayAuthKit/Sources/EcoPayAuthKit/AuthModels.swift
//
// Data models for authentication. These match the JSON structure
// returned by the login and token refresh endpoints in the
// MockAPIClient. Used by AuthService to parse API responses
// and by ViewModels to display user information.

import Foundation

// MARK: - Login Response

/// The response returned after a successful login.
/// Matches the JSON from /auth/login and /auth/passkey endpoints.
public struct LoginResponse: Codable, Sendable {
    /// Unique user identifier
    public let userId: String
    
    /// User's email address
    public let email: String
    
    /// User's display name
    public let name: String
    
    /// JWT access token for authenticated requests
    public let accessToken: String
    
    /// Token used to refresh the access token when it expires
    public let refreshToken: String
    
    /// Access token lifetime in seconds
    public let expiresIn: Int
    
    /// Authentication method used (password, passkey)
    /// Optional because password login doesn't include this field
    public let authMethod: String?
    
    public init(
        userId: String,
        email: String,
        name: String,
        accessToken: String,
        refreshToken: String,
        expiresIn: Int,
        authMethod: String? = nil
    ) {
        self.userId = userId
        self.email = email
        self.name = name
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.authMethod = authMethod
    }
}

// MARK: - Token Refresh Response

/// The response returned when refreshing an expired access token.
/// Matches the JSON from /auth/refresh endpoint.
public struct TokenRefreshResponse: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    
    public init(
        accessToken: String,
        refreshToken: String,
        expiresIn: Int
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }
}

// MARK: - User Profile

/// Represents the currently logged-in user.
/// Created from LoginResponse and stored in AppViewModel.
public struct UserProfile: Codable, Sendable, Identifiable {
    public var id: String { userId }
    
    public let userId: String
    public let email: String
    public let name: String
    public let authMethod: AuthMethod
    
    public init(
        userId: String,
        email: String,
        name: String,
        authMethod: AuthMethod = .password
    ) {
        self.userId = userId
        self.email = email
        self.name = name
        self.authMethod = authMethod
    }
    
    /// Creates a UserProfile from a LoginResponse.
    /// This is the primary way profiles are created after login.
    public static func from(_ response: LoginResponse) -> UserProfile {
        return UserProfile(
            userId: response.userId,
            email: response.email,
            name: response.name,
            authMethod: AuthMethod(rawValue: response.authMethod ?? "password") ?? .password
        )
    }
}

// MARK: - Auth Method

/// The method used to authenticate the user.
public enum AuthMethod: String, Codable, Sendable {
    case password
    case passkey
    case biometric
}

// MARK: - Auth State

/// Represents the current authentication state of the app.
/// Used by AppViewModel to decide which screen to show.
public enum AuthState: Equatable, Sendable {
    /// User is not logged in
    case unauthenticated
    
    /// Login/logout is in progress
    case loading
    
    /// User is logged in with a valid session
    case authenticated(UserProfile)
    
    /// Authentication failed with an error message
    case error(String)
    
    /// Convenience check for whether the user is logged in
    public var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }
    
    /// Extracts the user profile if authenticated, otherwise nil
    public var userProfile: UserProfile? {
        if case .authenticated(let profile) = self {
            return profile
        }
        return nil
    }
    
    // Custom Equatable since UserProfile needs to be compared
    public static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.unauthenticated, .unauthenticated):
            return true
        case (.loading, .loading):
            return true
        case (.authenticated(let a), .authenticated(let b)):
            return a.userId == b.userId
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Login Credentials

/// Holds the user's login input from the LoginView.
/// Passed to AuthService.login() to authenticate.
public struct LoginCredentials: Sendable {
    public let email: String
    public let password: String
    
    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
    
    /// Validates that both fields are filled and properly formatted.
    public var isValid: Bool {
        return !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && email.contains("@")
            && password.count >= 8
    }
}

// MARK: - Passkey Credential

/// Represents a stored passkey credential for passwordless login.
/// In a real app, this would come from Apple's AuthenticationServices.
/// For this demo, we simulate it with a stored credential ID.
public struct PasskeyCredential: Codable, Sendable {
    /// Unique identifier for the passkey
    public let credentialId: String
    
    /// The user ID associated with this passkey
    public let userId: String
    
    /// When the passkey was registered
    public let createdAt: Date
    
    /// Display name shown in the security settings
    public let displayName: String
    
    public init(
        credentialId: String,
        userId: String,
        createdAt: Date = Date(),
        displayName: String = "EcoPay Passkey"
    ) {
        self.credentialId = credentialId
        self.userId = userId
        self.createdAt = createdAt
        self.displayName = displayName
    }
}
