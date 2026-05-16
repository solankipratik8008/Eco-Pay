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
        let snapshot = try await db
            .collection(Collection.transactions)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        let transactions: [EcoPayPayments.Transaction] = snapshot.documents.compactMap { document in
            let data = document.data()
            
            let amountDouble = data["amount"] as? Double ?? 0.0
            let amount = Decimal(amountDouble)
            
            let currency = data["currency"] as? String ?? "CAD"
            let typeRaw = data["type"] as? String ?? TransactionType.sent.rawValue
            let statusRaw = data["status"] as? String ?? TransactionStatus.completed.rawValue
            let categoryRaw = data["category"] as? String ?? TransactionCategory.transfer.rawValue
            
            let description = data["description"] as? String ?? "Transfer"
            let recipient = data["recipient"] as? String ?? "EcoPay User"
            let note = data["note"] as? String
            let referenceNumber = data["referenceNumber"] as? String
            let cardLastFour = data["cardLastFour"] as? String
            
            let timestamp = data["createdAt"] as? Timestamp
            let date = timestamp?.dateValue() ?? Date()
            
            return EcoPayPayments.Transaction(
                id: document.documentID,
                type: TransactionType(rawValue: typeRaw) ?? .sent,
                status: TransactionStatus(rawValue: statusRaw) ?? .completed,
                amount: amount,
                currency: currency,
                description: description,
                recipient: recipient,
                date: date,
                category: TransactionCategory(rawValue: categoryRaw) ?? .transfer,
                note: note?.isEmpty == true ? nil : note,
                referenceNumber: referenceNumber,
                cardLastFour: cardLastFour
            )
        }
        
        return Array(
            transactions
                .sorted { $0.date > $1.date }
                .prefix(limit)
        )
    }
}
