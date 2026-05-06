//
//  AuthError.swift
//  EcoPayAuthKit
//
//  Created by Pratik Solanki on 2026-05-06.
//

// AuthError.swift
// EcoPayAuthKit/Sources/EcoPayAuthKit/AuthError.swift
//
// Authentication-specific errors separate from network errors.
// These cover input validation, Keychain failures, passkey issues,
// and session management — things that happen before or after
// a network request, not during one.

import Foundation
import EcoPayNetworking

// MARK: - Auth Error

/// All errors specific to the authentication flow.
/// AuthService throws these, and LoginViewModel catches them
/// to display appropriate user-facing messages.
public enum AuthError: LocalizedError, Equatable {
    
    // MARK: - Input Validation
    
    /// Email field is empty or has invalid format
    case invalidEmail
    
    /// Password is empty or doesn't meet requirements
    case invalidPassword
    
    /// Both email and password are invalid
    case invalidCredentials
    
    // MARK: - Authentication Failures
    
    /// Server rejected the login attempt (wrong email/password)
    case loginFailed(String)
    
    /// Too many failed login attempts
    case accountLocked
    
    // MARK: - Keychain Errors
    
    /// Failed to save data to Keychain
    case keychainSaveFailed
    
    /// Failed to read data from Keychain
    case keychainReadFailed
    
    /// Failed to delete data from Keychain
    case keychainDeleteFailed
    
    /// No auth token found in Keychain (user needs to log in)
    case noStoredToken
    
    // MARK: - Passkey Errors
    
    /// Passkey registration failed
    case passkeyRegistrationFailed(String)
    
    /// Passkey authentication failed
    case passkeyAuthenticationFailed(String)
    
    /// No passkey is registered for this device
    case noPasskeyRegistered
    
    /// Passkey is not supported on this device
    case passkeyNotSupported
    
    // MARK: - Session Errors
    
    /// The user's session has expired
    case sessionExpired
    
    /// Token refresh failed — user must log in again
    case tokenRefreshFailed
    
    // MARK: - General
    
    /// A network error occurred during authentication
    case networkError(NetworkError)
    
    /// An unexpected error not covered by other cases
    case unknown(String)
    
    // MARK: - User-Facing Messages
    
    public var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
            
        case .invalidPassword:
            return "Password must be at least 8 characters with one uppercase letter, one lowercase letter, and one number."
            
        case .invalidCredentials:
            return "Please check your email and password."
            
        case .loginFailed(let message):
            return message
            
        case .accountLocked:
            return "Your account has been temporarily locked due to too many failed attempts. Please try again later."
            
        case .keychainSaveFailed:
            return "Unable to save your login securely. Please try again."
            
        case .keychainReadFailed:
            return "Unable to retrieve your saved login. Please log in again."
            
        case .keychainDeleteFailed:
            return "Unable to clear your saved login. Please try again."
            
        case .noStoredToken:
            return "Your session has ended. Please log in again."
            
        case .passkeyRegistrationFailed(let reason):
            return "Passkey setup failed: \(reason)"
            
        case .passkeyAuthenticationFailed(let reason):
            return "Passkey login failed: \(reason)"
            
        case .noPasskeyRegistered:
            return "No passkey found. Please set up a passkey in Security Settings or log in with your password."
            
        case .passkeyNotSupported:
            return "Passkey authentication is not supported on this device."
            
        case .sessionExpired:
            return "Your session has expired. Please log in again."
            
        case .tokenRefreshFailed:
            return "Unable to refresh your session. Please log in again."
            
        case .networkError(let error):
            return error.errorDescription
            
        case .unknown(let message):
            return message.isEmpty
                ? "An unexpected error occurred. Please try again."
                : message
        }
    }
    
    // MARK: - Helper Properties
    
    /// Returns true if the error means the user must log in again.
    /// AppViewModel uses this to force navigation back to LoginView.
    public var requiresReLogin: Bool {
        switch self {
        case .sessionExpired,
             .tokenRefreshFailed,
             .noStoredToken,
             .keychainReadFailed:
            return true
        case .networkError(let error):
            return error.isAuthError
        default:
            return false
        }
    }
    
    /// Returns true if the error is related to user input
    /// and can be fixed by the user correcting their input.
    public var isInputError: Bool {
        switch self {
        case .invalidEmail, .invalidPassword, .invalidCredentials:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Factory Method
    
    /// Converts a NetworkError into an AuthError.
    /// Used by AuthService when a network call fails during auth.
    public static func from(_ networkError: NetworkError) -> AuthError {
        switch networkError {
        case .unauthorized:
            return .loginFailed("Invalid email or password. Please try again.")
        case .sessionExpired:
            return .sessionExpired
        case .forbidden:
            return .accountLocked
        default:
            return .networkError(networkError)
        }
    }
    
    // Equatable conformance for cases with associated values
    public static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        return lhs.errorDescription == rhs.errorDescription
    }
}
