//
//  KeychainService.swift
//  EcoPayAuthKit
//
//  Created by Pratik Solanki on 2026-05-06.
//

// KeychainService.swift
// EcoPayAuthKit/Sources/EcoPayAuthKit/KeychainService.swift
//
// Provides secure read/write/delete access to the iOS Keychain.
// Used by AuthService to store access tokens, refresh tokens,
// user IDs, and passkey credentials. Protocol-based so it can
// be mocked for testing.

import Foundation
import Security

// MARK: - Keychain Service Protocol

/// Contract for secure storage operations.
/// AuthService depends on this protocol, not the concrete class.
public protocol KeychainServiceProtocol: Sendable {
    
    /// Saves a string value to Keychain under the given key.
    /// Overwrites existing value if the key already exists.
    func save(key: String, value: String) throws
    
    /// Saves raw Data to Keychain under the given key.
    /// Used for storing encoded objects like PasskeyCredential.
    func saveData(key: String, value: Data) throws
    
    /// Reads a string value from Keychain for the given key.
    /// Returns nil if the key doesn't exist.
    func read(key: String) throws -> String?
    
    /// Reads raw Data from Keychain for the given key.
    /// Returns nil if the key doesn't exist.
    func readData(key: String) throws -> Data?
    
    /// Deletes the value stored under the given key.
    /// Does not throw if the key doesn't exist.
    func delete(key: String) throws
    
    /// Deletes all Keychain items for this app.
    /// Used during logout to clear all stored credentials.
    func deleteAll() throws
    
    /// Checks if a value exists for the given key.
    func exists(key: String) -> Bool
}

// MARK: - Keychain Service Implementation

/// Production Keychain service using Apple's Security framework.
/// All operations use kSecClassGenericPassword for simple key-value storage.
public final class KeychainService: KeychainServiceProtocol {
    
    // MARK: - Properties
    
    /// Bundle identifier used as the service name in Keychain queries.
    /// Groups all this app's Keychain items together.
    private let service: String
    
    // MARK: - Initialization
    
    /// Creates a KeychainService.
    /// - Parameter service: The service identifier (defaults to app bundle ID)
    public init(service: String = Bundle.main.bundleIdentifier ?? "com.ecopay.app") {
        self.service = service
    }
    
    // MARK: - Save Operations
    
    public func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw AuthError.keychainSaveFailed
        }
        try saveData(key: key, value: data)
    }
    
    public func saveData(key: String, value: Data) throws {
        // First try to delete any existing value for this key.
        // Keychain doesn't have an "upsert" — you must delete then add.
        let deleteQuery = baseQuery(for: key)
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Build the query to add the new item
        var query = baseQuery(for: key)
        query[kSecValueData as String] = value
        
        // kSecAttrAccessible determines when the item is readable.
        // afterFirstUnlockThisDeviceOnly means:
        // - Available after the user unlocks the phone once after boot
        // - Not included in backups or transferred to other devices
        // - Good balance of security and availability for auth tokens
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw AuthError.keychainSaveFailed
        }
    }
    
    // MARK: - Read Operations
    
    public func read(key: String) throws -> String? {
        guard let data = try readData(key: key) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    public func readData(key: String) throws -> Data? {
        var query = baseQuery(for: key)
        
        // kSecReturnData: return the actual data
        // kSecMatchLimit: only return one item
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            // Key doesn't exist — this is not an error, just return nil
            return nil
        default:
            throw AuthError.keychainReadFailed
        }
    }
    
    // MARK: - Delete Operations
    
    public func delete(key: String) throws {
        let query = baseQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)
        
        // errSecItemNotFound is fine — we're deleting something that
        // doesn't exist, which is the desired end state anyway
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthError.keychainDeleteFailed
        }
    }
    
    public func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthError.keychainDeleteFailed
        }
    }
    
    // MARK: - Exists Check
    
    public func exists(key: String) -> Bool {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = kCFBooleanFalse
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Private Helpers
    
    /// Builds the base Keychain query dictionary used by all operations.
    /// Every query identifies items by class, service, and account (key).
    private func baseQuery(for key: String) -> [String: Any] {
        return [
            // kSecClass: the type of Keychain item (generic password = key-value)
            kSecClass as String: kSecClassGenericPassword,
            
            // kSecAttrService: groups items by app (like a namespace)
            kSecAttrService as String: service,
            
            // kSecAttrAccount: the unique key within this service
            kSecAttrAccount as String: key
        ]
    }
}

// MARK: - Mock Keychain Service

/// In-memory mock of KeychainService for SwiftUI previews and testing.
/// Stores values in a dictionary instead of the real Keychain.
/// The real Keychain isn't available in preview or test environments.
public final class MockKeychainService: KeychainServiceProtocol, @unchecked Sendable {
    
    /// In-memory storage that replaces the real Keychain
    private var storage: [String: Data] = [:]
    
    public init() {}
    
    public func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw AuthError.keychainSaveFailed
        }
        storage[key] = data
    }
    
    public func saveData(key: String, value: Data) throws {
        storage[key] = value
    }
    
    public func read(key: String) throws -> String? {
        guard let data = storage[key] else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    public func readData(key: String) throws -> Data? {
        return storage[key]
    }
    
    public func delete(key: String) throws {
        storage.removeValue(forKey: key)
    }
    
    public func deleteAll() throws {
        storage.removeAll()
    }
    
    public func exists(key: String) -> Bool {
        return storage[key] != nil
    }
}
