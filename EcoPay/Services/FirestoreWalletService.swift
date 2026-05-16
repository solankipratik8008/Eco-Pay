//
//  FirestoreWalletService.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-15.
//

import Foundation
import FirebaseFirestore
import EcoPayPayments

final class FirestoreWalletService {
    
    private let db = Firestore.firestore()
    
    private enum Collection {
        static let wallets = "wallets"
        static let transactions = "transactions"
    }
    
    // MARK: - Fetch Wallet
    
    func fetchWallet(for userId: String) async throws -> WalletResponse {
        let document = try await db
            .collection(Collection.wallets)
            .document(userId)
            .getDocument()
        
        guard let data = document.data() else {
            throw NSError(
                domain: "FirestoreWalletService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Wallet not found."]
            )
        }
        
        let balanceDouble = data["balance"] as? Double ?? 0.0
        let currency = data["currency"] as? String ?? "CAD"
        
        return WalletResponse(
            balance: Decimal(balanceDouble),
            currency: currency,
            cards: []
        )
    }
    
    // MARK: - Fetch Recent Transactions
    
    /// Temporary placeholder.
    /// We will connect this after checking your exact Transaction model.
    func fetchRecentTransactions(
        for userId: String,
        limit: Int = 5
    ) async throws -> [EcoPayPayments.Transaction] {
        return []
    }
}
