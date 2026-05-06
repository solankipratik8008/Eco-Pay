//
//  AnalyticsService.swift
//  EcoPayAnalytics
//
//  Created by Pratik Solanki on 2026-05-06.
//

// AnalyticsService.swift
// EcoPayAnalytics/Sources/EcoPayAnalytics/AnalyticsService.swift
//
// Lightweight analytics module for tracking user events.
// Protocol-based so the app can swap between console logging
// (demo) and a real analytics backend (production).
// Completely independent — no dependencies on other packages.

import Foundation

// MARK: - Analytics Event

/// Represents a single trackable event in the app.
/// Each event has a name, optional properties, and a timestamp.
public struct AnalyticsEvent: Sendable {
    /// Event name used for identification and grouping.
    /// Examples: "login_success", "payment_sent", "card_added"
    public let name: String
    
    /// Optional key-value properties attached to the event.
    /// Examples: ["method": "passkey"], ["amount": "250.00"]
    public let properties: [String: String]
    
    /// When the event occurred.
    public let timestamp: Date
    
    public init(
        name: String,
        properties: [String: String] = [:],
        timestamp: Date = Date()
    ) {
        self.name = name
        self.properties = properties
        self.timestamp = timestamp
    }
}

// MARK: - Predefined Events
// Factory methods for common events. Using these instead of
// raw strings prevents typos and keeps event names consistent.

public extension AnalyticsEvent {
    
    // ── Auth Events ──
    
    static func loginSuccess(method: String) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "login_success",
            properties: ["method": method]
        )
    }
    
    static func loginFailed(reason: String) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "login_failed",
            properties: ["reason": reason]
        )
    }
    
    static func logout() -> AnalyticsEvent {
        return AnalyticsEvent(name: "logout")
    }
    
    static func sessionRestored() -> AnalyticsEvent {
        return AnalyticsEvent(name: "session_restored")
    }
    
    // ── Passkey Events ──
    
    static func passkeyRegistered() -> AnalyticsEvent {
        return AnalyticsEvent(name: "passkey_registered")
    }
    
    static func passkeyRemoved() -> AnalyticsEvent {
        return AnalyticsEvent(name: "passkey_removed")
    }
    
    static func passkeyLoginAttempt() -> AnalyticsEvent {
        return AnalyticsEvent(name: "passkey_login_attempt")
    }
    
    // ── Wallet Events ──
    
    static func walletViewed(balance: String) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "wallet_viewed",
            properties: ["balance": balance]
        )
    }
    
    static func cardAdded(brand: String) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "card_added",
            properties: ["brand": brand]
        )
    }
    
    // ── Transaction Events ──
    
    static func transactionsViewed(count: Int) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "transactions_viewed",
            properties: ["count": "\(count)"]
        )
    }
    
    static func transactionDetailViewed(id: String) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "transaction_detail_viewed",
            properties: ["transaction_id": id]
        )
    }
    
    // ── Payment Events ──
    
    static func paymentInitiated(amount: String) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "payment_initiated",
            properties: ["amount": amount]
        )
    }
    
    static func paymentCompleted(amount: String, recipient: String) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "payment_completed",
            properties: [
                "amount": amount,
                "recipient": recipient
            ]
        )
    }
    
    static func paymentFailed(reason: String) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "payment_failed",
            properties: ["reason": reason]
        )
    }
    
    // ── Navigation Events ──
    
    static func screenViewed(_ screenName: String) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "screen_viewed",
            properties: ["screen": screenName]
        )
    }
}

// MARK: - Analytics Service Protocol

/// Contract for analytics tracking.
/// ViewModels call track() to log events.
public protocol AnalyticsServiceProtocol: Sendable {
    
    /// Tracks a single event.
    func track(_ event: AnalyticsEvent)
    
    /// Tracks a simple event by name with no properties.
    func track(name: String)
    
    /// Returns all tracked events (useful for debugging).
    func getEventLog() -> [AnalyticsEvent]
    
    /// Clears the event log.
    func clearEventLog()
}

// MARK: - Console Analytics Service

/// Demo implementation that prints events to the Xcode console.
/// In a real app, this would send events to Firebase Analytics,
/// Mixpanel, Amplitude, or a custom backend.
public final class ConsoleAnalyticsService: AnalyticsServiceProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    
    /// Stores all tracked events for debugging and review.
    private var eventLog: [AnalyticsEvent] = []
    
    /// When true, events are printed to the console.
    private let printToConsole: Bool
    
    /// Maximum number of events to keep in the log.
    /// Prevents unbounded memory growth in long sessions.
    private let maxLogSize: Int
    
    // MARK: - Initialization
    
    public init(printToConsole: Bool = true, maxLogSize: Int = 500) {
        self.printToConsole = printToConsole
        self.maxLogSize = maxLogSize
    }
    
    // MARK: - Tracking
    
    public func track(_ event: AnalyticsEvent) {
        // Add to log
        eventLog.append(event)
        
        // Trim if over max size
        if eventLog.count > maxLogSize {
            eventLog.removeFirst(eventLog.count - maxLogSize)
        }
        
        // Print to console for demo visibility
        if printToConsole {
            let timestamp = formatTimestamp(event.timestamp)
            var output = "📊 [Analytics] \(timestamp) — \(event.name)"
            
            if !event.properties.isEmpty {
                let props = event.properties
                    .sorted(by: { $0.key < $1.key })
                    .map { "\($0.key): \($0.value)" }
                    .joined(separator: ", ")
                output += " {\(props)}"
            }
            
            print(output)
        }
    }
    
    public func track(name: String) {
        track(AnalyticsEvent(name: name))
    }
    
    // MARK: - Event Log Access
    
    public func getEventLog() -> [AnalyticsEvent] {
        return eventLog
    }
    
    public func clearEventLog() {
        eventLog.removeAll()
    }
    
    // MARK: - Private Helpers
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}

// MARK: - Mock Analytics Service

/// Silent mock for testing — tracks events without printing.
/// Use getEventLog() to verify events were tracked correctly.
public final class MockAnalyticsService: AnalyticsServiceProtocol, @unchecked Sendable {
    
    private var eventLog: [AnalyticsEvent] = []
    
    public init() {}
    
    public func track(_ event: AnalyticsEvent) {
        eventLog.append(event)
    }
    
    public func track(name: String) {
        track(AnalyticsEvent(name: name))
    }
    
    public func getEventLog() -> [AnalyticsEvent] {
        return eventLog
    }
    
    public func clearEventLog() {
        eventLog.removeAll()
    }
    
    /// Convenience: check if a specific event was tracked.
    /// Useful in tests: assert(analytics.hasTracked("login_success"))
    public func hasTracked(_ eventName: String) -> Bool {
        return eventLog.contains(where: { $0.name == eventName })
    }
    
    /// Convenience: count how many times an event was tracked.
    public func countOf(_ eventName: String) -> Int {
        return eventLog.filter({ $0.name == eventName }).count
    }
}
