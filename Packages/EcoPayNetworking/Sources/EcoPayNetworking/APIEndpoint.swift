//
//  File.swift
//  EcoPayNetworking
//
//  Created by Pratik Solanki on 2026-05-06.
//

// APIEndpoint.swift
// EcoPayNetworking/Sources/EcoPayNetworking/APIEndpoint.swift
//
// Defines the structure of every API endpoint in the app.
// Each endpoint knows its HTTP method, path, headers, body,
// and how to construct a URLRequest. This keeps networking
// details out of ViewModels and services.

import Foundation

// MARK: - HTTP Method

/// Standard HTTP methods used by the API client.
public enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
    case PATCH
}

// MARK: - API Endpoint Protocol

/// Any API endpoint in the app conforms to this protocol.
/// It provides everything the APIClient needs to build
/// and execute a URLRequest.
///
/// Usage:
///   struct LoginEndpoint: APIEndpoint {
///       let email: String
///       let password: String
///       var path: String { "/auth/login" }
///       var method: HTTPMethod { .POST }
///       var body: Data? {
///           try? JSONEncoder().encode(["email": email, "password": password])
///       }
///   }
public protocol APIEndpoint {
    /// The URL path relative to the base URL.
    /// Example: "/auth/login"
    var path: String { get }
    
    /// The HTTP method for this request.
    var method: HTTPMethod { get }
    
    /// Optional request headers.
    /// Content-Type is set automatically by APIClient.
    var headers: [String: String]? { get }
    
    /// Optional request body as raw Data.
    /// Used for POST/PUT/PATCH requests.
    var body: Data? { get }
    
    /// Optional query parameters appended to the URL.
    /// Example: ["page": "1", "limit": "20"]
    var queryParameters: [String: String]? { get }
}

// MARK: - Default Implementations
// Provides sensible defaults so endpoints only need to
// specify what's different from the norm.

public extension APIEndpoint {
    var headers: [String: String]? { nil }
    var body: Data? { nil }
    var queryParameters: [String: String]? { nil }
}

// MARK: - URLRequest Builder

public extension APIEndpoint {
    
    /// Constructs a URLRequest from the endpoint's properties.
    /// The APIClient calls this method before executing the request.
    ///
    /// - Parameter baseURL: The base URL string (e.g., "https://api.ecopay.demo")
    /// - Returns: A configured URLRequest ready to be sent
    /// - Throws: URLError if the URL cannot be constructed
    func asURLRequest(baseURL: String) throws -> URLRequest {
        // Build URL with path
        guard var components = URLComponents(string: baseURL + path) else {
            throw URLError(.badURL)
        }
        
        // Add query parameters if present
        if let queryParameters, !queryParameters.isEmpty {
            components.queryItems = queryParameters.map {
                URLQueryItem(name: $0.key, value: $0.value)
            }
        }
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        // Configure request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Apply custom headers (overrides defaults if same key)
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
}

// MARK: - Concrete Endpoints
// All API endpoints used in the app are defined here.
// Grouping them in one place makes it easy to see
// every network call the app can make.

public enum EcoPayEndpoint {
    
    // MARK: - Auth Endpoints
    
    /// Login with email and password
    public struct Login: APIEndpoint {
        public let email: String
        public let password: String
        
        public var path: String { "/auth/login" }
        public var method: HTTPMethod { .POST }
        
        public var body: Data? {
            let payload = ["email": email, "password": password]
            return try? JSONEncoder().encode(payload)
        }
        
        public init(email: String, password: String) {
            self.email = email
            self.password = password
        }
    }
    
    /// Login with passkey credential
    public struct PasskeyLogin: APIEndpoint {
        public let credentialId: String
        
        public var path: String { "/auth/passkey" }
        public var method: HTTPMethod { .POST }
        
        public var body: Data? {
            let payload = ["credentialId": credentialId]
            return try? JSONEncoder().encode(payload)
        }
        
        public init(credentialId: String) {
            self.credentialId = credentialId
        }
    }
    
    /// Refresh the access token
    public struct RefreshToken: APIEndpoint {
        public let refreshToken: String
        
        public var path: String { "/auth/refresh" }
        public var method: HTTPMethod { .POST }
        
        public var body: Data? {
            let payload = ["refreshToken": refreshToken]
            return try? JSONEncoder().encode(payload)
        }
        
        public init(refreshToken: String) {
            self.refreshToken = refreshToken
        }
    }
    
    /// Logout and invalidate tokens
    public struct Logout: APIEndpoint {
        public var path: String { "/auth/logout" }
        public var method: HTTPMethod { .POST }
        
        public init() {}
    }
    
    // MARK: - Wallet Endpoints
    
    /// Fetch wallet balance and card info
    public struct GetWallet: APIEndpoint {
        public var path: String { "/wallet" }
        public var method: HTTPMethod { .GET }
        
        public init() {}
    }
    
    /// Add a new card to the wallet
    public struct AddCard: APIEndpoint {
        public let cardData: Data
        
        public var path: String { "/wallet/cards" }
        public var method: HTTPMethod { .POST }
        public var body: Data? { cardData }
        
        public init(cardData: Data) {
            self.cardData = cardData
        }
    }
    
    // MARK: - Transaction Endpoints
    
    /// Fetch transaction history
    public struct GetTransactions: APIEndpoint {
        public let page: Int
        public let limit: Int
        
        public var path: String { "/transactions" }
        public var method: HTTPMethod { .GET }
        
        public var queryParameters: [String: String]? {
            ["page": "\(page)", "limit": "\(limit)"]
        }
        
        public init(page: Int = 1, limit: Int = 20) {
            self.page = page
            self.limit = limit
        }
    }
    
    /// Fetch a single transaction by ID
    public struct GetTransaction: APIEndpoint {
        public let transactionId: String
        
        public var path: String { "/transactions/\(transactionId)" }
        public var method: HTTPMethod { .GET }
        
        public init(transactionId: String) {
            self.transactionId = transactionId
        }
    }
    
    // MARK: - Payment Endpoints
    
    /// Send a payment
    public struct SendPayment: APIEndpoint {
        public let paymentData: Data
        
        public var path: String { "/payments/send" }
        public var method: HTTPMethod { .POST }
        public var body: Data? { paymentData }
        
        public init(paymentData: Data) {
            self.paymentData = paymentData
        }
    }
}
