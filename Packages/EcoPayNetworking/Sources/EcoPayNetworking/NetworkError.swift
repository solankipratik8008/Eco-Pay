//
//  NetworkError.swift
//  EcoPayNetworking
//
//  Created by Pratik Solanki on 2026-05-06.
//

// NetworkError.swift
// EcoPayNetworking/Sources/EcoPayNetworking/NetworkError.swift
//
// Defines all possible errors from the networking layer.
// Each case carries enough context for ViewModels to show
// meaningful error messages to the user. Conforms to
// LocalizedError so SwiftUI alerts can display .localizedDescription.

import Foundation

// MARK: - Network Error

/// All errors that can occur during API communication.
/// Used by both the real APIClient and MockAPIClient.
public enum NetworkError: LocalizedError, Equatable {
    
    /// The URL could not be constructed from the endpoint.
    case invalidURL
    
    /// The request body could not be encoded to JSON.
    case encodingFailed
    
    /// The response body could not be decoded into the expected type.
    /// Carries the underlying description for debugging.
    case decodingFailed(String)
    
    /// The server returned an HTTP error status code.
    /// Carries the status code and optional server message.
    case httpError(statusCode: Int, message: String?)
    
    /// Authentication failed — invalid credentials or expired token.
    case unauthorized
    
    /// The user's session has expired and needs to re-login.
    case sessionExpired
    
    /// The server understood the request but refused it.
    /// Example: insufficient funds, duplicate transaction.
    case forbidden(String?)
    
    /// The requested resource was not found.
    case notFound
    
    /// The request timed out.
    case timeout
    
    /// No internet connection or network is unreachable.
    case noConnection
    
    /// The server returned an unexpected or empty response.
    case invalidResponse
    
    /// A catch-all for errors not covered by other cases.
    /// Wraps the underlying error description.
    case unknown(String)
    
    // MARK: - User-Facing Error Messages
    
    /// Human-readable error description shown in alerts and UI.
    /// These messages are written for end users, not developers.
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Unable to connect. Please try again."
            
        case .encodingFailed:
            return "Unable to send your request. Please try again."
            
        case .decodingFailed:
            return "We received an unexpected response. Please try again."
            
        case .httpError(let statusCode, let message):
            if let message {
                return message
            }
            return "Something went wrong (Error \(statusCode)). Please try again."
            
        case .unauthorized:
            return "Invalid email or password. Please check your credentials."
            
        case .sessionExpired:
            return "Your session has expired. Please log in again."
            
        case .forbidden(let reason):
            return reason ?? "You don't have permission to perform this action."
            
        case .notFound:
            return "The requested information could not be found."
            
        case .timeout:
            return "The request timed out. Please check your connection and try again."
            
        case .noConnection:
            return "No internet connection. Please check your network settings."
            
        case .invalidResponse:
            return "We received an unexpected response. Please try again."
            
        case .unknown(let message):
            return message.isEmpty
                ? "An unexpected error occurred. Please try again."
                : message
        }
    }
    
    // MARK: - Helper Properties
    
    /// Returns true if the error is an authentication-related failure.
    /// Used by ViewModels to decide whether to force logout.
    public var isAuthError: Bool {
        switch self {
        case .unauthorized, .sessionExpired:
            return true
        default:
            return false
        }
    }
    
    /// Returns true if the error is likely temporary and
    /// the request could succeed if retried.
    public var isRetryable: Bool {
        switch self {
        case .timeout, .noConnection, .invalidResponse:
            return true
        case .httpError(let statusCode, _):
            // 5xx errors are server-side and often temporary
            return statusCode >= 500
        default:
            return false
        }
    }
    
    // MARK: - Factory Method
    
    /// Creates a NetworkError from a URLError.
    /// Maps common URLError codes to specific NetworkError cases.
    public static func from(_ urlError: URLError) -> NetworkError {
        switch urlError.code {
        case .timedOut:
            return .timeout
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnection
        case .badURL, .unsupportedURL:
            return .invalidURL
        case .cancelled:
            return .unknown("Request was cancelled.")
        default:
            return .unknown(urlError.localizedDescription)
        }
    }
    
    /// Creates a NetworkError from an HTTP status code.
    /// Maps standard HTTP error codes to specific cases.
    public static func from(statusCode: Int, data: Data? = nil) -> NetworkError {
        // Try to extract a message from the response body
        let message = Self.extractMessage(from: data)
        
        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .forbidden(message)
        case 404:
            return .notFound
        case 408:
            return .timeout
        case 400, 405...499:
            return .httpError(statusCode: statusCode, message: message)
        case 500...599:
            return .httpError(statusCode: statusCode, message: message)
        default:
            return .unknown(message ?? "HTTP \(statusCode)")
        }
    }
    
    // MARK: - Private Helpers
    
    /// Attempts to extract an error message from JSON response data.
    /// Looks for common patterns like {"error": "..."} or {"message": "..."}
    private static func extractMessage(from data: Data?) -> String? {
        guard let data else { return nil }
        
        // Try to decode as a dictionary with common error keys
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // Check common error message fields
            if let message = json["message"] as? String { return message }
            if let error = json["error"] as? String { return error }
            if let detail = json["detail"] as? String { return detail }
        }
        
        return nil
    }
}
