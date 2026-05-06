//
//  WalletModels.swift
//  EcoPayPayments
//
//  Created by Pratik Solanki on 2026-05-06.
//

// WalletModels.swift
// EcoPayPayments/Sources/EcoPayPayments/WalletModels.swift
//
// Data models for the wallet — balance, cards, and wallet state.
// These match the JSON structure from the /wallet endpoint
// in MockAPIClient. Used by WalletViewModel and dashboard views.

import Foundation

// MARK: - Wallet Response

/// The response from the /wallet endpoint.
/// Contains balance and all linked cards.
public struct WalletResponse: Codable, Sendable {
    public let balance: Decimal
    public let currency: String
    public let cards: [Card]
    
    public init(balance: Decimal, currency: String, cards: [Card]) {
        self.balance = balance
        self.currency = currency
        self.cards = cards
    }
}

// MARK: - Card Model

/// Represents a payment card linked to the wallet.
/// Only stores last 4 digits — never stores full card numbers.
public struct Card: Codable, Sendable, Identifiable {
    public let id: String
    public let brand: CardBrand
    public let lastFour: String
    public let cardholderName: String
    public let expiryMonth: Int
    public let expiryYear: Int
    public let isDefault: Bool
    
    public init(
        id: String,
        brand: CardBrand,
        lastFour: String,
        cardholderName: String,
        expiryMonth: Int,
        expiryYear: Int,
        isDefault: Bool = false
    ) {
        self.id = id
        self.brand = brand
        self.lastFour = lastFour
        self.cardholderName = cardholderName
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
        self.isDefault = isDefault
    }
    
    /// Formatted expiry string for display.
    /// Example: "12/27"
    public var expiryString: String {
        let month = String(format: "%02d", expiryMonth)
        let year = String(expiryYear).suffix(2)
        return "\(month)/\(year)"
    }
    
    /// Masked card number for display.
    /// Example: "•••• 4242"
    public var maskedNumber: String {
        return "\u{2022}\u{2022}\u{2022}\u{2022} \(lastFour)"
    }
    
    /// Checks if the card has expired.
    public var isExpired: Bool {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        
        if expiryYear < currentYear {
            return true
        } else if expiryYear == currentYear && expiryMonth < currentMonth {
            return true
        }
        return false
    }
}

// MARK: - Card Brand

/// Supported card brands with display properties.
public enum CardBrand: String, Codable, Sendable, CaseIterable {
    case visa = "Visa"
    case mastercard = "Mastercard"
    case amex = "Amex"
    case discover = "Discover"
    case unknown = "Unknown"
    
    /// SF Symbol name for each card brand.
    /// Used in card list and detail views.
    public var iconName: String {
        switch self {
        case .visa: return "creditcard.fill"
        case .mastercard: return "creditcard.fill"
        case .amex: return "creditcard.trianglebadge.exclamationmark"
        case .discover: return "creditcard.fill"
        case .unknown: return "creditcard.fill"
        }
    }
    
    /// Brand color for visual differentiation in the UI.
    public var colorHex: String {
        switch self {
        case .visa: return "1A1F71"
        case .mastercard: return "EB001B"
        case .amex: return "006FCF"
        case .discover: return "FF6600"
        case .unknown: return "888888"
        }
    }
}

// MARK: - Add Card Request

/// Data sent when adding a new card.
/// Only captures the last 4 digits — this is a demo app.
public struct AddCardRequest: Codable, Sendable {
    public let brand: CardBrand
    public let lastFour: String
    public let cardholderName: String
    public let expiryMonth: Int
    public let expiryYear: Int
    
    public init(
        brand: CardBrand,
        lastFour: String,
        cardholderName: String,
        expiryMonth: Int,
        expiryYear: Int
    ) {
        self.brand = brand
        self.lastFour = lastFour
        self.cardholderName = cardholderName
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
    }
    
    /// Validates that all fields are properly filled.
    public var isValid: Bool {
        return !cardholderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && lastFour.count == 4
            && lastFour.allSatisfy({ $0.isNumber })
            && expiryMonth >= 1
            && expiryMonth <= 12
            && expiryYear >= Calendar.current.component(.year, from: Date())
    }
    
    /// Encodes to JSON Data for the API request body.
    public func asData() -> Data? {
        return try? JSONEncoder().encode(self)
    }
}

// MARK: - Wallet State

/// Represents the current state of the wallet data.
/// Used by WalletViewModel to drive UI state.
public enum WalletState: Equatable, Sendable {
    /// Wallet data has not been loaded yet
    case idle
    
    /// Wallet data is being fetched
    case loading
    
    /// Wallet data loaded successfully
    case loaded(WalletResponse)
    
    /// Failed to load wallet data
    case error(String)
    
    /// Convenience check for loading state
    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    /// Extracts the wallet response if loaded
    public var walletData: WalletResponse? {
        if case .loaded(let data) = self { return data }
        return nil
    }
    
    /// Extracts the balance if loaded
    public var balance: Decimal? {
        return walletData?.balance
    }
    
    /// Extracts the cards if loaded
    public var cards: [Card] {
        return walletData?.cards ?? []
    }
    
    // Custom Equatable
    public static func == (lhs: WalletState, rhs: WalletState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.loading, .loading): return true
        case (.loaded(let a), .loaded(let b)):
            return a.balance == b.balance && a.cards.count == b.cards.count
        case (.error(let a), .error(let b)):
            return a == b
        default: return false
        }
    }
}

// MARK: - Preview / Mock Data

public extension Card {
    /// Sample cards for SwiftUI previews and testing.
    static let sampleVisa = Card(
        id: "card_001",
        brand: .visa,
        lastFour: "4242",
        cardholderName: "Pratik Solanki",
        expiryMonth: 12,
        expiryYear: 2027,
        isDefault: true
    )
    
    static let sampleMastercard = Card(
        id: "card_002",
        brand: .mastercard,
        lastFour: "8888",
        cardholderName: "Pratik Solanki",
        expiryMonth: 6,
        expiryYear: 2026,
        isDefault: false
    )
    
    static let sampleAmex = Card(
        id: "card_003",
        brand: .amex,
        lastFour: "1234",
        cardholderName: "Pratik Solanki",
        expiryMonth: 3,
        expiryYear: 2028,
        isDefault: false
    )
    
    static let allSamples = [sampleVisa, sampleMastercard, sampleAmex]
}

public extension WalletResponse {
    /// Sample wallet for SwiftUI previews.
    static let sample = WalletResponse(
        balance: 12458.50,
        currency: "USD",
        cards: Card.allSamples
    )
}
