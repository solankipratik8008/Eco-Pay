//
//  File.swift
//  EcoPayNetworking
//
//  Created by Pratik Solanki on 2026-05-06.
//

// APIClient.swift
// EcoPayNetworking/Sources/EcoPayNetworking/APIClient.swift
//
// Defines the APIClient protocol and a production URLSession-based
// implementation. The protocol allows ViewModels and services to
// depend on an abstraction rather than a concrete class, making
// it easy to swap in MockAPIClient for demos and testing.

import Foundation

// MARK: - API Client Protocol

/// The contract that any API client must follow.
/// Both URLSessionAPIClient (production) and MockAPIClient (demo)
/// conform to this protocol.
///
/// Usage in a ViewModel:
///   class WalletViewModel {
///       private let apiClient: APIClientProtocol
///       init(apiClient: APIClientProtocol = URLSessionAPIClient()) { ... }
///   }
public protocol APIClientProtocol: Sendable {
    
    /// Sends a request to the given endpoint and decodes the response.
    ///
    /// - Parameters:
    ///   - endpoint: The API endpoint to call
    ///   - responseType: The Decodable type to decode the response into
    /// - Returns: The decoded response object
    /// - Throws: NetworkError if the request fails at any stage
    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> T
    
    /// Sends a request that doesn't expect a response body.
    /// Used for operations like logout or delete.
    ///
    /// - Parameter endpoint: The API endpoint to call
    /// - Throws: NetworkError if the request fails
    func requestVoid(_ endpoint: APIEndpoint) async throws
}

// MARK: - URLSession API Client

/// Production API client that uses URLSession for real network requests.
/// In this portfolio demo, we primarily use MockAPIClient instead,
/// but this class shows a complete production-ready networking layer.
public final class URLSessionAPIClient: APIClientProtocol {
    
    // MARK: - Properties
    
    private let session: URLSession
    private let baseURL: String
    private let decoder: JSONDecoder
    
    /// Optional auth token injected for authenticated requests.
    /// Services set this after login; it's included in every subsequent request.
    public nonisolated(unsafe) var authToken: String?
    
    // MARK: - Initialization
    
    /// Creates a new API client.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL for all API requests
    ///   - session: URLSession instance (injectable for testing)
    ///   - decoder: JSONDecoder instance (injectable for custom date strategies)
    public init(
        baseURL: String = "https://api.ecopay.demo",
        session: URLSession = .shared,
        decoder: JSONDecoder? = nil
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder ?? Self.defaultDecoder()
    }
    
    // MARK: - APIClientProtocol
    
    public func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> T {
        // Build the URLRequest from the endpoint
        let urlRequest = try buildRequest(from: endpoint)
        
        // Execute the request using async/await
        let (data, response) = try await executeRequest(urlRequest)
        
        // Validate HTTP response
        try validateResponse(response, data: data)
        
        // Decode the response body
        do {
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
        } catch let decodingError {
            throw NetworkError.decodingFailed(decodingError.localizedDescription)
        }
    }
    
    public func requestVoid(_ endpoint: APIEndpoint) async throws {
        let urlRequest = try buildRequest(from: endpoint)
        let (_, response) = try await executeRequest(urlRequest)
        try validateResponse(response, data: nil)
    }
    
    // MARK: - Private Helpers
    
    /// Builds a URLRequest from an endpoint and injects the auth token if present.
    private func buildRequest(from endpoint: APIEndpoint) throws -> URLRequest {
        do {
            var request = try endpoint.asURLRequest(baseURL: baseURL)
            
            // Inject authorization header if token exists
            if let authToken, !authToken.isEmpty {
                request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            }
            
            // Set timeout from configuration
            request.timeoutInterval = 30
            
            return request
        } catch {
            throw NetworkError.invalidURL
        }
    }
    
    /// Executes the URLRequest and maps URLSession errors to NetworkError.
    private func executeRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let urlError as URLError {
            throw NetworkError.from(urlError)
        } catch {
            throw NetworkError.unknown(error.localizedDescription)
        }
    }
    
    /// Validates the HTTP response status code.
    /// Throws a specific NetworkError for non-2xx responses.
    private func validateResponse(_ response: URLResponse, data: Data?) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        // 2xx status codes are success
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.from(statusCode: httpResponse.statusCode, data: data)
        }
    }
    
    // MARK: - Default Decoder
    
    /// Creates a JSONDecoder configured for the API's date format.
    /// Handles both ISO 8601 dates and Unix timestamps.
    private static func defaultDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            
            // Try ISO 8601 first
            if let dateString = try? container.decode(String.self) {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                if let date = formatter.date(from: dateString) {
                    return date
                }
                
                // Try without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            // Try Unix timestamp
            if let timestamp = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: timestamp)
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unable to decode date"
            )
        }
        return decoder
    }
}
