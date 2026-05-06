//
//  AppConstants.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

// AppConstants.swift
// EcoPayApp/Utilities/AppConstants.swift
//
// Centralized constants for the Eco-Pay app.
// Keeps magic strings, configuration values, and mock identifiers
// in one place so they're easy to find and update.

import Foundation

enum AppConstants {
    
    // MARK: - App Info
    
    enum App {
        static let name = "Eco-Pay"
        static let tagline = "Your smart digital wallet"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - Keychain Keys
    // Used by EcoPayAuthKit to store and retrieve secure data.
    // Each key maps to one piece of sensitive information in Keychain.
    
    enum Keychain {
        static let accessToken = "com.ecopay.accessToken"
        static let refreshToken = "com.ecopay.refreshToken"
        static let userId = "com.ecopay.userId"
        static let passkeyCredential = "com.ecopay.passkeyCredential"
    }
    
    // MARK: - API Configuration
    // Base URL and timeout for the networking layer.
    // Points to mock endpoints for the portfolio demo.
    
    enum API {
        // In a real app, this would point to your backend server.
        // For this demo, we use MockAPIClient instead of hitting a live server.
        static let baseURL = "https://api.ecopay.demo"
        static let timeoutInterval: TimeInterval = 30
        static let maxRetryAttempts = 3
    }
    
    // MARK: - Validation Rules
    // Input validation constants used in payment and card forms.
    
    enum Validation {
        static let minPasswordLength = 8
        static let maxPasswordLength = 64
        static let cardNumberLength = 4  // We only store last 4 digits
        static let minPaymentAmount: Decimal = 0.01
        static let maxPaymentAmount: Decimal = 10_000.00
        static let maxNoteLength = 140
    }
    
    // MARK: - Date Formats
    // Consistent date formatting across the app.
    
    enum DateFormat {
        static let transactionDisplay = "MMM d, yyyy"
        static let transactionDetailDisplay = "MMMM d, yyyy 'at' h:mm a"
        static let cardExpiry = "MM/yy"
        static let apiFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    }
    
    // MARK: - Currency
    
    enum Currency {
        static let defaultCode = "USD"
        static let defaultSymbol = "$"
        static let defaultLocale = Locale(identifier: "en_US")
    }
    
    // MARK: - Mock User
    // Default demo user for login simulation.
    // Used by MockAPIClient and preview providers.
    
    enum MockUser {
        static let email = "demo@ecopay.com"
        static let password = "Demo1234!"
        static let name = "Pratik Solanki"
        static let userId = "user_001"
    }
    
    // MARK: - SF Symbols
    // Centralized icon names so a typo here is caught once, not everywhere.
    
    enum Icons {
        // Tab and navigation
        static let home = "house.fill"
        static let wallet = "creditcard.fill"
        static let transactions = "list.bullet.rectangle.portrait.fill"
        static let profile = "person.circle.fill"
        static let settings = "gearshape.fill"
        
        // Actions
        static let send = "paperplane.fill"
        static let addCard = "plus.rectangle.fill"
        static let scan = "qrcode.viewfinder"
        static let logout = "rectangle.portrait.and.arrow.right"
        
        // Transaction types
        static let sent = "arrow.up.right.circle.fill"
        static let received = "arrow.down.left.circle.fill"
        static let refund = "arrow.uturn.backward.circle.fill"
        static let payment = "dollarsign.circle.fill"
        
        // Status
        static let completed = "checkmark.circle.fill"
        static let pending = "clock.fill"
        static let failed = "xmark.circle.fill"
        
        // Security
        static let passkey = "person.badge.key.fill"
        static let biometric = "faceid"
        static let lock = "lock.fill"
        static let shield = "shield.checkered"
        
        // Misc
        static let chevronRight = "chevron.right"
        static let search = "magnifyingglass"
        static let close = "xmark"
        static let info = "info.circle"
    }
    
    // MARK: - Animation Durations
    
    enum AnimationDuration {
        static let splash: TimeInterval = 2.0
        static let transition: TimeInterval = 0.3
        static let feedback: TimeInterval = 1.5
    }
}
