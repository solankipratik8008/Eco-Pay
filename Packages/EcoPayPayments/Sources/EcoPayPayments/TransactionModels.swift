//
//  TransactionModels.swift
//  EcoPayPayments
//
//  Created by Pratik Solanki on 2026-05-06.
//

// TransactionModels.swift
// EcoPayPayments/Sources/EcoPayPayments/TransactionModels.swift
//
// Data models for transactions — list responses, individual
// transactions, types, statuses, categories, and filtering.
// These match the JSON from /transactions endpoints in MockAPIClient.

import Foundation
import SwiftUI

// MARK: - Transaction List Response

/// The response from the /transactions endpoint.
/// Includes pagination info for loading more transactions.
public struct TransactionListResponse: Codable, Sendable {
    public let transactions: [Transaction]
    public let totalCount: Int
    public let page: Int
    public let hasMore: Bool
    
    public init(
        transactions: [Transaction],
        totalCount: Int,
        page: Int,
        hasMore: Bool
    ) {
        self.transactions = transactions
        self.totalCount = totalCount
        self.page = page
        self.hasMore = hasMore
    }
}

// MARK: - Transaction Model

/// A single financial transaction.
/// Used in transaction list, detail view, and after payment creation.
public struct Transaction: Codable, Sendable, Identifiable {
    public let id: String
    public let type: TransactionType
    public let status: TransactionStatus
    public let amount: Decimal
    public let currency: String
    public let description: String
    public let recipient: String
    public let date: Date
    public let category: TransactionCategory
    
    // Detail-only fields (optional — not present in list responses)
    public let note: String?
    public let referenceNumber: String?
    public let cardLastFour: String?
    
    public init(
        id: String,
        type: TransactionType,
        status: TransactionStatus,
        amount: Decimal,
        currency: String,
        description: String,
        recipient: String,
        date: Date,
        category: TransactionCategory,
        note: String? = nil,
        referenceNumber: String? = nil,
        cardLastFour: String? = nil
    ) {
        self.id = id
        self.type = type
        self.status = status
        self.amount = amount
        self.currency = currency
        self.description = description
        self.recipient = recipient
        self.date = date
        self.category = category
        self.note = note
        self.referenceNumber = referenceNumber
        self.cardLastFour = cardLastFour
    }
    
    // MARK: - Display Helpers
    
    /// Returns true if money was received (positive amount)
    public var isIncoming: Bool {
        return type == .received || type == .refund
    }
    
    /// Formatted amount string with sign and currency.
    /// Incoming: "+$3,500.00" in green
    /// Outgoing: "-$250.00" in default color
    public var formattedAmount: String {
        let absAmount = amount < 0 ? -amount : amount
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let formatted = formatter.string(from: absAmount as NSDecimalNumber) ?? "$0.00"
        
        if isIncoming {
            return "+\(formatted)"
        } else {
            return "-\(formatted)"
        }
    }
    
    /// Color for the amount text based on transaction direction.
    public var amountColor: Color {
        if status == .failed {
            return .secondary
        }
        return isIncoming ? .green : .primary
    }
    
    /// SF Symbol name based on transaction type.
    public var iconName: String {
        return type.iconName
    }
    
    /// Icon background color based on transaction type.
    public var iconColor: Color {
        return type.iconColor
    }
}

// MARK: - Transaction Type

/// The direction/nature of a transaction.
public enum TransactionType: String, Codable, Sendable, CaseIterable {
    case sent
    case received
    case payment
    case refund
    
    /// Display name for UI.
    public var displayName: String {
        switch self {
        case .sent: return "Sent"
        case .received: return "Received"
        case .payment: return "Payment"
        case .refund: return "Refund"
        }
    }
    
    /// SF Symbol for this transaction type.
    public var iconName: String {
        switch self {
        case .sent: return "arrow.up.right.circle.fill"
        case .received: return "arrow.down.left.circle.fill"
        case .payment: return "dollarsign.circle.fill"
        case .refund: return "arrow.uturn.backward.circle.fill"
        }
    }
    
    /// Color associated with this transaction type.
    public var iconColor: Color {
        switch self {
        case .sent: return .orange
        case .received: return .green
        case .payment: return .blue
        case .refund: return .purple
        }
    }
}

// MARK: - Transaction Status

/// The current state of a transaction.
public enum TransactionStatus: String, Codable, Sendable, CaseIterable {
    case completed
    case pending
    case failed
    
    /// Display name for UI.
    public var displayName: String {
        switch self {
        case .completed: return "Completed"
        case .pending: return "Pending"
        case .failed: return "Failed"
        }
    }
    
    /// SF Symbol for this status.
    public var iconName: String {
        switch self {
        case .completed: return "checkmark.circle.fill"
        case .pending: return "clock.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    /// Color for this status badge.
    public var statusColor: Color {
        switch self {
        case .completed: return .green
        case .pending: return .orange
        case .failed: return .red
        }
    }
}

// MARK: - Transaction Category

/// Spending category for a transaction.
/// Used for filtering and display grouping.
public enum TransactionCategory: String, Codable, Sendable, CaseIterable {
    case housing
    case income
    case entertainment
    case food
    case shopping
    case health
    case transport
    case transfer
    case utilities
    case other
    
    /// Display name for UI.
    public var displayName: String {
        switch self {
        case .housing: return "Housing"
        case .income: return "Income"
        case .entertainment: return "Entertainment"
        case .food: return "Food & Dining"
        case .shopping: return "Shopping"
        case .health: return "Health & Fitness"
        case .transport: return "Transport"
        case .transfer: return "Transfer"
        case .utilities: return "Utilities"
        case .other: return "Other"
        }
    }
    
    /// SF Symbol for this category.
    public var iconName: String {
        switch self {
        case .housing: return "house.fill"
        case .income: return "banknote.fill"
        case .entertainment: return "tv.fill"
        case .food: return "fork.knife"
        case .shopping: return "bag.fill"
        case .health: return "heart.fill"
        case .transport: return "car.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        case .utilities: return "bolt.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }
    
    /// Color for this category.
    public var categoryColor: Color {
        switch self {
        case .housing: return .blue
        case .income: return .green
        case .entertainment: return .purple
        case .food: return .orange
        case .shopping: return .pink
        case .health: return .red
        case .transport: return .cyan
        case .transfer: return .indigo
        case .utilities: return .yellow
        case .other: return .gray
        }
    }
}

// MARK: - Transaction Filter

/// Filtering options for the transaction list.
/// TransactionViewModel uses this to filter the displayed transactions.
public struct TransactionFilter: Equatable, Sendable {
    /// Filter by transaction type (nil = show all)
    public var type: TransactionType?
    
    /// Filter by status (nil = show all)
    public var status: TransactionStatus?
    
    /// Filter by category (nil = show all)
    public var category: TransactionCategory?
    
    /// Search text to filter by description or recipient
    public var searchText: String
    
    /// Filter transactions after this date
    public var startDate: Date?
    
    /// Filter transactions before this date
    public var endDate: Date?
    
    public init(
        type: TransactionType? = nil,
        status: TransactionStatus? = nil,
        category: TransactionCategory? = nil,
        searchText: String = "",
        startDate: Date? = nil,
        endDate: Date? = nil
    ) {
        self.type = type
        self.status = status
        self.category = category
        self.searchText = searchText
        self.startDate = startDate
        self.endDate = endDate
    }
    
    /// Returns true if no filters are active.
    public var isEmpty: Bool {
        return type == nil
            && status == nil
            && category == nil
            && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && startDate == nil
            && endDate == nil
    }
    
    /// Resets all filters to default.
    public mutating func reset() {
        type = nil
        status = nil
        category = nil
        searchText = ""
        startDate = nil
        endDate = nil
    }
    
    /// Applies all active filters to a transaction list.
    /// Returns only transactions that match every active filter.
    public func apply(to transactions: [Transaction]) -> [Transaction] {
        var filtered = transactions
        
        // Filter by type
        if let type {
            filtered = filtered.filter { $0.type == type }
        }
        
        // Filter by status
        if let status {
            filtered = filtered.filter { $0.status == status }
        }
        
        // Filter by category
        if let category {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by search text (matches description or recipient)
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let lowered = trimmed.lowercased()
            filtered = filtered.filter {
                $0.description.lowercased().contains(lowered)
                || $0.recipient.lowercased().contains(lowered)
            }
        }
        
        // Filter by date range
        if let startDate {
            filtered = filtered.filter { $0.date >= startDate }
        }
        
        if let endDate {
            filtered = filtered.filter { $0.date <= endDate }
        }
        
        return filtered
    }
    
    /// Count of active filters for showing a badge.
    public var activeFilterCount: Int {
        var count = 0
        if type != nil { count += 1 }
        if status != nil { count += 1 }
        if category != nil { count += 1 }
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
        if startDate != nil { count += 1 }
        if endDate != nil { count += 1 }
        return count
    }
}

// MARK: - Send Payment Request

/// Data sent when creating a new payment.
/// SendPaymentViewModel creates this from user input.
public struct SendPaymentRequest: Codable, Sendable {
    public let recipientName: String
    public let amount: Decimal
    public let note: String?
    public let currency: String
    
    public init(
        recipientName: String,
        amount: Decimal,
        note: String? = nil,
        currency: String = "USD"
    ) {
        self.recipientName = recipientName
        self.amount = amount
        self.note = note
        self.currency = currency
    }
    
    /// Validates that all required fields are properly filled.
    public var isValid: Bool {
        let trimmedRecipient = recipientName
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedRecipient.isEmpty
            && amount > 0
            && amount <= 10_000
    }
    
    /// Encodes to JSON Data for the API request body.
    public func asData() -> Data? {
        return try? JSONEncoder().encode(self)
    }
}

// MARK: - Transaction List State

/// Represents the state of transaction data loading.
/// Used by TransactionViewModel to drive UI state.
public enum TransactionListState: Equatable, Sendable {
    case idle
    case loading
    case loaded([Transaction])
    case error(String)
    
    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    public var transactions: [Transaction] {
        if case .loaded(let list) = self { return list }
        return []
    }
    
    public static func == (lhs: TransactionListState, rhs: TransactionListState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.loading, .loading): return true
        case (.loaded(let a), .loaded(let b)):
            return a.count == b.count
        case (.error(let a), .error(let b)):
            return a == b
        default: return false
        }
    }
}

// MARK: - Preview / Mock Data

public extension Transaction {
    /// Sample transactions for SwiftUI previews.
    static let sampleRent = Transaction(
        id: "txn_001",
        type: .sent,
        status: .completed,
        amount: -250.00,
        currency: "USD",
        description: "Rent Payment",
        recipient: "Landlord Corp",
        date: Date.now.addingTimeInterval(-86400),
        category: .housing,
        note: "May 2025 rent payment",
        referenceNumber: "REF-2025-05-001",
        cardLastFour: "4242"
    )
    
    static let sampleSalary = Transaction(
        id: "txn_002",
        type: .received,
        status: .completed,
        amount: 3500.00,
        currency: "USD",
        description: "Salary Deposit",
        recipient: "Ramp Inc",
        date: Date.now.addingTimeInterval(-172800),
        category: .income
    )
    
    static let sampleNetflix = Transaction(
        id: "txn_003",
        type: .payment,
        status: .completed,
        amount: -42.99,
        currency: "USD",
        description: "Netflix Subscription",
        recipient: "Netflix",
        date: Date.now.addingTimeInterval(-259200),
        category: .entertainment
    )
    
    static let samplePending = Transaction(
        id: "txn_004",
        type: .sent,
        status: .pending,
        amount: -125.00,
        currency: "USD",
        description: "Dinner Split",
        recipient: "Alex Johnson",
        date: Date.now.addingTimeInterval(-345600),
        category: .food
    )
    
    static let sampleRefund = Transaction(
        id: "txn_005",
        type: .refund,
        status: .completed,
        amount: 89.99,
        currency: "USD",
        description: "Amazon Return",
        recipient: "Amazon",
        date: Date.now.addingTimeInterval(-432000),
        category: .shopping
    )
    
    static let sampleFailed = Transaction(
        id: "txn_006",
        type: .payment,
        status: .failed,
        amount: -200.00,
        currency: "USD",
        description: "Gym Membership",
        recipient: "FitLife Gym",
        date: Date.now.addingTimeInterval(-518400),
        category: .health
    )
    
    static let allSamples = [
        sampleRent,
        sampleSalary,
        sampleNetflix,
        samplePending,
        sampleRefund,
        sampleFailed
    ]
}
