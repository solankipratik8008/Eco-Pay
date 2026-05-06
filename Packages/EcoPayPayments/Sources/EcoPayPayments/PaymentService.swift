//
//  PaymentService.swift
//  EcoPayPayments
//
//  Created by Pratik Solanki on 2026-05-06.
//
// PaymentService.swift
// EcoPayPayments/Sources/EcoPayPayments/PaymentService.swift
//
// Service layer for wallet, transaction, and payment operations.
// Coordinates between ViewModels and the API client.
// Protocol-based for dependency injection and testability.

import Foundation
import EcoPayNetworking

// MARK: - Payment Service Protocol

/// Contract for all wallet and payment operations.
/// WalletViewModel, TransactionViewModel, and SendPaymentViewModel
/// depend on this protocol.
public protocol PaymentServiceProtocol: Sendable {
    
    /// Fetches the current wallet balance and linked cards.
    func fetchWallet() async throws -> WalletResponse
    
    /// Fetches the transaction history with pagination.
    func fetchTransactions(page: Int, limit: Int) async throws -> TransactionListResponse
    
    /// Fetches a single transaction by ID.
    func fetchTransaction(id: String) async throws -> Transaction
    
    /// Sends a payment to a recipient.
    /// Returns the created transaction.
    func sendPayment(request: SendPaymentRequest) async throws -> Transaction
    
    /// Adds a new card to the wallet.
    /// Returns the created card.
    func addCard(request: AddCardRequest) async throws -> Card
}

// MARK: - Payment Service Implementation

public final class PaymentService: PaymentServiceProtocol, @unchecked Sendable {
    
    // MARK: - Dependencies
    
    private let apiClient: APIClientProtocol
    
    // MARK: - Initialization
    
    /// Creates a PaymentService with an injectable API client.
    ///
    /// - Parameter apiClient: The API client for network requests
    public init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    // MARK: - Wallet
    
    public func fetchWallet() async throws -> WalletResponse {
        do {
            let endpoint = EcoPayEndpoint.GetWallet()
            return try await apiClient.request(
                endpoint,
                responseType: WalletResponse.self
            )
        } catch let error as NetworkError {
            throw PaymentError.from(error)
        } catch {
            throw PaymentError.unknown(error.localizedDescription)
        }
    }
    
    // MARK: - Transactions
    
    public func fetchTransactions(page: Int = 1, limit: Int = 20) async throws -> TransactionListResponse {
        do {
            let endpoint = EcoPayEndpoint.GetTransactions(
                page: page,
                limit: limit
            )
            return try await apiClient.request(
                endpoint,
                responseType: TransactionListResponse.self
            )
        } catch let error as NetworkError {
            throw PaymentError.from(error)
        } catch {
            throw PaymentError.unknown(error.localizedDescription)
        }
    }
    
    public func fetchTransaction(id: String) async throws -> Transaction {
        do {
            let endpoint = EcoPayEndpoint.GetTransaction(transactionId: id)
            return try await apiClient.request(
                endpoint,
                responseType: Transaction.self
            )
        } catch let error as NetworkError {
            throw PaymentError.from(error)
        } catch {
            throw PaymentError.unknown(error.localizedDescription)
        }
    }
    
    // MARK: - Payments
    
    public func sendPayment(request: SendPaymentRequest) async throws -> Transaction {
        // Validate before sending
        guard request.isValid else {
            if request.recipientName
                .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw PaymentError.invalidRecipient
            }
            if request.amount <= 0 {
                throw PaymentError.invalidAmount("Amount must be greater than zero.")
            }
            if request.amount > 10_000 {
                throw PaymentError.invalidAmount("Amount cannot exceed $10,000.00.")
            }
            throw PaymentError.validationFailed("Please check your payment details.")
        }
        
        do {
            guard let paymentData = request.asData() else {
                throw PaymentError.validationFailed("Unable to process payment details.")
            }
            
            let endpoint = EcoPayEndpoint.SendPayment(paymentData: paymentData)
            return try await apiClient.request(
                endpoint,
                responseType: Transaction.self
            )
        } catch let error as NetworkError {
            throw PaymentError.from(error)
        } catch let error as PaymentError {
            throw error
        } catch {
            throw PaymentError.unknown(error.localizedDescription)
        }
    }
    
    // MARK: - Cards
    
    public func addCard(request: AddCardRequest) async throws -> Card {
        // Validate before sending
        guard request.isValid else {
            if request.cardholderName
                .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw PaymentError.validationFailed("Please enter the cardholder name.")
            }
            if request.lastFour.count != 4 {
                throw PaymentError.validationFailed("Please enter the last 4 digits of the card.")
            }
            throw PaymentError.validationFailed("Please check your card details.")
        }
        
        do {
            guard let cardData = request.asData() else {
                throw PaymentError.validationFailed("Unable to process card details.")
            }
            
            let endpoint = EcoPayEndpoint.AddCard(cardData: cardData)
            return try await apiClient.request(
                endpoint,
                responseType: Card.self
            )
        } catch let error as NetworkError {
            throw PaymentError.from(error)
        } catch let error as PaymentError {
            throw error
        } catch {
            throw PaymentError.unknown(error.localizedDescription)
        }
    }
}

// MARK: - Payment Error

/// Errors specific to wallet and payment operations.
/// Separates payment concerns from network and auth errors.
public enum PaymentError: LocalizedError, Equatable {
    
    /// Recipient field is empty or invalid
    case invalidRecipient
    
    /// Amount is invalid (zero, negative, or exceeds limit)
    case invalidAmount(String)
    
    /// General validation failure
    case validationFailed(String)
    
    /// Insufficient balance for this transaction
    case insufficientFunds
    
    /// Payment was declined by the system
    case paymentDeclined(String)
    
    /// Card operation failed
    case cardError(String)
    
    /// Transaction not found
    case transactionNotFound
    
    /// User is not authenticated
    case unauthorized
    
    /// A network error occurred
    case networkError(String)
    
    /// Unexpected error
    case unknown(String)
    
    // MARK: - User-Facing Messages
    
    public var errorDescription: String? {
        switch self {
        case .invalidRecipient:
            return "Please enter a valid recipient name."
            
        case .invalidAmount(let message):
            return message
            
        case .validationFailed(let message):
            return message
            
        case .insufficientFunds:
            return "Insufficient balance to complete this payment."
            
        case .paymentDeclined(let reason):
            return "Payment declined: \(reason)"
            
        case .cardError(let message):
            return message
            
        case .transactionNotFound:
            return "Transaction could not be found."
            
        case .unauthorized:
            return "Please log in to continue."
            
        case .networkError(let message):
            return message
            
        case .unknown(let message):
            return message.isEmpty
                ? "An unexpected error occurred. Please try again."
                : message
        }
    }
    
    // MARK: - Helper Properties
    
    /// Returns true if the error means the user must log in again.
    public var requiresReLogin: Bool {
        return self == .unauthorized
    }
    
    /// Returns true if the error is a validation issue
    /// that the user can fix by correcting their input.
    public var isValidationError: Bool {
        switch self {
        case .invalidRecipient, .invalidAmount, .validationFailed:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Factory Method
    
    /// Converts a NetworkError into a PaymentError.
    public static func from(_ networkError: NetworkError) -> PaymentError {
        switch networkError {
        case .unauthorized, .sessionExpired:
            return .unauthorized
        case .notFound:
            return .transactionNotFound
        case .forbidden(let reason):
            return .paymentDeclined(reason ?? "Transaction was not authorized.")
        default:
            return .networkError(
                networkError.errorDescription ?? "A network error occurred."
            )
        }
    }
}

// MARK: - Payment State

/// Represents the state of a payment operation.
/// Used by SendPaymentViewModel to drive the payment flow UI.
public enum PaymentState: Equatable, Sendable {
    /// No payment in progress
    case idle
    
    /// Payment is being processed
    case processing
    
    /// Payment completed successfully
    case success(Transaction)
    
    /// Payment failed
    case failed(String)
    
    public var isProcessing: Bool {
        if case .processing = self { return true }
        return false
    }
    
    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    public var completedTransaction: Transaction? {
        if case .success(let transaction) = self { return transaction }
        return nil
    }
    
    public static func == (lhs: PaymentState, rhs: PaymentState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.processing, .processing): return true
        case (.success(let a), .success(let b)): return a.id == b.id
        case (.failed(let a), .failed(let b)): return a == b
        default: return false
        }
    }
}
