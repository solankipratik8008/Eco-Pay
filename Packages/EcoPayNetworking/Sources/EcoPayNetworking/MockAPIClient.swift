//
//  MockAPIClient.swift
//  EcoPayNetworking
//
//  Created by Pratik Solanki on 2026-05-06.
//

// MockAPIClient.swift
// EcoPayNetworking/Sources/EcoPayNetworking/MockAPIClient.swift
//
// Mock implementation of APIClientProtocol that returns realistic
// sample data without hitting any real server. Powers the entire
// portfolio demo. Includes simulated network delay to make the
// app feel realistic with loading states.

import Foundation

// MARK: - Mock API Client

/// A fake API client that returns hardcoded responses for every endpoint.
/// Conforms to the same APIClientProtocol as the real client, so
/// ViewModels don't know the difference.
///
/// Usage:
///   let viewModel = WalletViewModel(apiClient: MockAPIClient())
public final class MockAPIClient: APIClientProtocol, @unchecked Sendable {
    
    // MARK: - Configuration
    
    /// Simulated network delay range in seconds.
    /// Makes loading states visible in the UI.
    private let minDelay: TimeInterval
    private let maxDelay: TimeInterval
    
    /// When true, certain requests will fail to test error handling.
    /// Useful for verifying that error states display correctly.
    public var shouldSimulateErrors: Bool
    
    /// Tracks the simulated auth state.
    /// Login sets this to true, logout sets it to false.
    public var isAuthenticated: Bool = true
    
    // MARK: - Initialization
    
    public init(
        minDelay: TimeInterval = 0.3,
        maxDelay: TimeInterval = 1.0,
        shouldSimulateErrors: Bool = false
    ) {
        self.minDelay = minDelay
        self.maxDelay = maxDelay
        self.shouldSimulateErrors = shouldSimulateErrors
    }
    
    // MARK: - APIClientProtocol
    
    public func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> T {
        // Simulate network delay
        try await simulateDelay()
        
        // Simulate errors if enabled
        if shouldSimulateErrors {
            throw NetworkError.httpError(statusCode: 500, message: "Simulated server error")
        }
        
        // Route to the correct mock response based on the endpoint path
        let jsonData = try mockResponse(for: endpoint)
        
        // Decode using the same decoder configuration as production
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let decoded = try decoder.decode(T.self, from: jsonData)
            return decoded
        } catch {
            throw NetworkError.decodingFailed(error.localizedDescription)
        }
    }
    
    public func requestVoid(_ endpoint: APIEndpoint) async throws {
        try await simulateDelay()
        
        if shouldSimulateErrors {
            throw NetworkError.httpError(statusCode: 500, message: "Simulated server error")
        }
        
        // Handle logout
        if endpoint.path == "/auth/logout" {
            isAuthenticated = false
        }
    }
    
    // MARK: - Mock Response Router
    
    /// Routes each endpoint path to the correct mock JSON response.
    /// Add new endpoints here as the app grows.
    private func mockResponse(for endpoint: APIEndpoint) throws -> Data {
        switch endpoint.path {
            
        // ── Auth ──
        case "/auth/login":
            return try loginResponse(for: endpoint)
            
        case "/auth/passkey":
            isAuthenticated = true
            return MockResponses.passkeyLoginResponse
            
        case "/auth/refresh":
            return MockResponses.refreshTokenResponse
            
        // ── Wallet ──
        case "/wallet":
            guard isAuthenticated else { throw NetworkError.unauthorized }
            return MockResponses.walletResponse
            
        case "/wallet/cards":
            guard isAuthenticated else { throw NetworkError.unauthorized }
            return MockResponses.addCardResponse
            
        // ── Transactions ──
        case "/transactions":
            guard isAuthenticated else { throw NetworkError.unauthorized }
            return MockResponses.transactionsResponse
            
        case let path where path.starts(with: "/transactions/"):
            guard isAuthenticated else { throw NetworkError.unauthorized }
            return MockResponses.transactionDetailResponse
            
        // ── Payments ──
        case "/payments/send":
            guard isAuthenticated else { throw NetworkError.unauthorized }
            return MockResponses.sendPaymentResponse
            
        default:
            throw NetworkError.notFound
        }
    }
    
    /// Handles login by checking mock credentials.
    private func loginResponse(for endpoint: APIEndpoint) throws -> Data {
        // Extract credentials from the request body
        if let body = endpoint.body,
           let credentials = try? JSONSerialization.jsonObject(with: body) as? [String: String],
           let email = credentials["email"],
           let password = credentials["password"] {
            
            // Check against mock credentials
            if email == "demo@ecopay.com" && password == "Demo1234!" {
                isAuthenticated = true
                return MockResponses.loginSuccessResponse
            } else {
                throw NetworkError.unauthorized
            }
        }
        throw NetworkError.encodingFailed
    }
    
    // MARK: - Delay Simulation
    
    /// Adds a random delay between minDelay and maxDelay seconds.
    /// This makes the app feel realistic — loading spinners appear
    /// briefly before data loads, just like a real networked app.
    private func simulateDelay() async throws {
        let delay = Double.random(in: minDelay...maxDelay)
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }
}

// MARK: - Mock Response Data

/// All mock JSON responses used by the MockAPIClient.
/// Each response mirrors the structure that a real backend would return.
/// Keeping them in a separate enum keeps MockAPIClient readable.
enum MockResponses {
    
    // MARK: - Auth Responses
    
    static let loginSuccessResponse = """
    {
        "user_id": "user_001",
        "email": "demo@ecopay.com",
        "name": "Pratik Solanki",
        "access_token": "mock_access_token_abc123",
        "refresh_token": "mock_refresh_token_xyz789",
        "expires_in": 3600
    }
    """.data(using: .utf8)!
    
    static let passkeyLoginResponse = """
    {
        "user_id": "user_001",
        "email": "demo@ecopay.com",
        "name": "Pratik Solanki",
        "access_token": "mock_passkey_token_abc123",
        "refresh_token": "mock_passkey_refresh_xyz789",
        "expires_in": 3600,
        "auth_method": "passkey"
    }
    """.data(using: .utf8)!
    
    static let refreshTokenResponse = """
    {
        "access_token": "mock_refreshed_token_new123",
        "refresh_token": "mock_refreshed_refresh_new789",
        "expires_in": 3600
    }
    """.data(using: .utf8)!
    
    // MARK: - Wallet Responses
    
    static let walletResponse = """
    {
        "balance": 12458.50,
        "currency": "USD",
        "cards": [
            {
                "id": "card_001",
                "brand": "Visa",
                "last_four": "4242",
                "cardholder_name": "Pratik Solanki",
                "expiry_month": 12,
                "expiry_year": 2027,
                "is_default": true
            },
            {
                "id": "card_002",
                "brand": "Mastercard",
                "last_four": "8888",
                "cardholder_name": "Pratik Solanki",
                "expiry_month": 6,
                "expiry_year": 2026,
                "is_default": false
            }
        ]
    }
    """.data(using: .utf8)!
    
    static let addCardResponse = """
    {
        "id": "card_003",
        "brand": "Amex",
        "last_four": "1234",
        "cardholder_name": "Pratik Solanki",
        "expiry_month": 3,
        "expiry_year": 2028,
        "is_default": false
    }
    """.data(using: .utf8)!
    
    // MARK: - Transaction Responses
    
    static let transactionsResponse = """
    {
        "transactions": [
            {
                "id": "txn_001",
                "type": "sent",
                "status": "completed",
                "amount": -250.00,
                "currency": "USD",
                "description": "Rent Payment",
                "recipient": "Landlord Corp",
                "date": "2025-05-05T10:30:00Z",
                "category": "housing"
            },
            {
                "id": "txn_002",
                "type": "received",
                "status": "completed",
                "amount": 3500.00,
                "currency": "USD",
                "description": "Salary Deposit",
                "recipient": "Ramp Inc",
                "date": "2025-05-01T09:00:00Z",
                "category": "income"
            },
            {
                "id": "txn_003",
                "type": "payment",
                "status": "completed",
                "amount": -42.99,
                "currency": "USD",
                "description": "Netflix Subscription",
                "recipient": "Netflix",
                "date": "2025-04-28T14:22:00Z",
                "category": "entertainment"
            },
            {
                "id": "txn_004",
                "type": "sent",
                "status": "pending",
                "amount": -125.00,
                "currency": "USD",
                "description": "Dinner Split",
                "recipient": "Alex Johnson",
                "date": "2025-04-27T20:15:00Z",
                "category": "food"
            },
            {
                "id": "txn_005",
                "type": "refund",
                "status": "completed",
                "amount": 89.99,
                "currency": "USD",
                "description": "Amazon Return",
                "recipient": "Amazon",
                "date": "2025-04-25T11:45:00Z",
                "category": "shopping"
            },
            {
                "id": "txn_006",
                "type": "payment",
                "status": "failed",
                "amount": -200.00,
                "currency": "USD",
                "description": "Gym Membership",
                "recipient": "FitLife Gym",
                "date": "2025-04-23T08:00:00Z",
                "category": "health"
            },
            {
                "id": "txn_007",
                "type": "received",
                "status": "completed",
                "amount": 150.00,
                "currency": "USD",
                "description": "Freelance Payment",
                "recipient": "Client ABC",
                "date": "2025-04-20T16:30:00Z",
                "category": "income"
            },
            {
                "id": "txn_008",
                "type": "payment",
                "status": "completed",
                "amount": -55.00,
                "currency": "USD",
                "description": "Gas Station",
                "recipient": "Shell",
                "date": "2025-04-18T07:20:00Z",
                "category": "transport"
            }
        ],
        "total_count": 8,
        "page": 1,
        "has_more": false
    }
    """.data(using: .utf8)!
    
    static let transactionDetailResponse = """
    {
        "id": "txn_001",
        "type": "sent",
        "status": "completed",
        "amount": -250.00,
        "currency": "USD",
        "description": "Rent Payment",
        "recipient": "Landlord Corp",
        "date": "2025-05-05T10:30:00Z",
        "category": "housing",
        "note": "May 2025 rent payment",
        "reference_number": "REF-2025-05-001",
        "card_last_four": "4242"
    }
    """.data(using: .utf8)!
    
    // MARK: - Payment Responses
    
    static let sendPaymentResponse = """
    {
        "id": "txn_009",
        "type": "sent",
        "status": "completed",
        "amount": -100.00,
        "currency": "USD",
        "description": "Payment Sent",
        "recipient": "Recipient",
        "date": "2025-05-06T12:00:00Z",
        "category": "transfer",
        "reference_number": "REF-2025-05-009"
    }
    """.data(using: .utf8)!
}
