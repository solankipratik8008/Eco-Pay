//
//  FirebaseAuthService.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-15.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import EcoPayAuthKit

final class FirebaseAuthService: AuthServiceProtocol, @unchecked Sendable {
    
    // MARK: - Firestore
    
    private let db = Firestore.firestore()
    
    private enum Collection {
        static let users = "users"
        static let wallets = "wallets"
    }
    
    // MARK: - Login
    
    func login(credentials: LoginCredentials) async throws -> UserProfile {
        guard credentials.isValid else {
            if credentials.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                !credentials.email.contains("@") {
                throw AuthError.invalidEmail
            }
            
            throw AuthError.invalidPassword
        }
        
        do {
            let result = try await Auth.auth().signIn(
                withEmail: credentials.email,
                password: credentials.password
            )
            
            let user = result.user
            return try await fetchOrCreateUserProfile(firebaseUser: user)
        } catch {
            throw AuthError.unknown(cleanFirebaseError(error))
        }
    }
    
    // MARK: - Register
    
    func register(email: String, password: String, name: String) async throws -> UserProfile {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmedEmail.contains("@") else {
            throw AuthError.invalidEmail
        }
        
        guard password.count >= 8 else {
            throw AuthError.invalidPassword
        }
        
        guard !trimmedName.isEmpty else {
            throw AuthError.unknown("Please enter your full name.")
        }
        
        do {
            let result = try await Auth.auth().createUser(
                withEmail: trimmedEmail,
                password: password
            )
            
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = trimmedName
            try await changeRequest.commitChanges()
            
            let profile = UserProfile(
                userId: result.user.uid,
                email: trimmedEmail,
                name: trimmedName,
                authMethod: .password
            )
            
            try await createUserProfileIfNeeded(profile)
            try await createWalletIfNeeded(userId: profile.userId)
            
            return profile
        } catch {
            throw AuthError.unknown(cleanFirebaseError(error))
        }
    }
    
    // MARK: - Passkey
    
    func loginWithPasskey() async throws -> UserProfile {
        throw AuthError.passkeyAuthenticationFailed(
            "Passkey login is not connected to Firebase yet."
        )
    }
    
    func registerPasskey(userId: String) async throws {
        throw AuthError.passkeyRegistrationFailed(
            "Passkey registration is not connected to Firebase yet."
        )
    }
    
    func hasPasskeyRegistered() -> Bool {
        return false
    }
    
    // MARK: - Logout
    
    func logout() async throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw AuthError.unknown(cleanFirebaseError(error))
        }
    }
    
    // MARK: - Restore Session
    
    func restoreSession() async -> UserProfile? {
        guard let user = Auth.auth().currentUser else {
            return nil
        }
        
        do {
            return try await fetchOrCreateUserProfile(firebaseUser: user)
        } catch {
            print("Failed to restore Firebase session: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Access Token
    
    func getAccessToken() -> String? {
        // Firebase ID tokens are fetched asynchronously.
        // This protocol requires a synchronous method, so this can be improved later if needed.
        return Auth.auth().currentUser?.uid
    }
    
    // MARK: - Firestore Helpers
    
    private func fetchOrCreateUserProfile(firebaseUser: FirebaseAuth.User) async throws -> UserProfile {
        let userRef = db.collection(Collection.users).document(firebaseUser.uid)
        let snapshot = try await userRef.getDocument()
        
        if snapshot.exists,
           let data = snapshot.data(),
           let email = data["email"] as? String,
           let name = data["name"] as? String {
            
            try await createWalletIfNeeded(userId: firebaseUser.uid)
            
            return UserProfile(
                userId: firebaseUser.uid,
                email: email,
                name: name,
                authMethod: .password
            )
        }
        
        let profile = UserProfile(
            userId: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            name: firebaseUser.displayName ?? "EcoPay User",
            authMethod: .password
        )
        
        try await createUserProfileIfNeeded(profile)
        try await createWalletIfNeeded(userId: profile.userId)
        
        return profile
    }
    
    private func createUserProfileIfNeeded(_ profile: UserProfile) async throws {
        let userRef = db.collection(Collection.users).document(profile.userId)
        let snapshot = try await userRef.getDocument()
        
        guard !snapshot.exists else {
            return
        }
        
        try await userRef.setData([
            "userId": profile.userId,
            "email": profile.email,
            "name": profile.name,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }
    
    private func createWalletIfNeeded(userId: String) async throws {
        let walletRef = db.collection(Collection.wallets).document(userId)
        let snapshot = try await walletRef.getDocument()
        
        guard !snapshot.exists else {
            return
        }
        
        try await walletRef.setData([
            "userId": userId,
            "balance": 1000.00,
            "currency": "CAD",
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
    // MARK: - Error Helpers
    
    private func cleanFirebaseError(_ error: Error) -> String {
        let nsError = error as NSError
        
        switch AuthErrorCode(rawValue: nsError.code) {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .userNotFound:
            return "No account found with this email."
        case .emailAlreadyInUse:
            return "This email is already registered."
        case .weakPassword:
            return "Password is too weak. Use at least 8 characters."
        case .networkError:
            return "Network error. Please check your connection."
        default:
            return error.localizedDescription
        }
    }
}
