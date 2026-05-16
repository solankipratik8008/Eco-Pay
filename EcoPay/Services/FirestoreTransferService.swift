//
//  FirestoreTransferService.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-15.
//

import Foundation
import FirebaseFirestore
import EcoPayPayments

final class FirestoreTransferService {
    
    private let db = Firestore.firestore()
    
    private enum Collection {
        static let users = "users"
        static let wallets = "wallets"
        static let transactions = "transactions"
    }
    
    // MARK: - Public Transfer Method
    
    func sendMoney(
        senderId: String,
        senderEmail: String,
        recipientEmail: String,
        amount: Decimal,
        note: String?
    ) async throws -> EcoPayPayments.Transaction {
        
        let cleanedRecipientEmail = recipientEmail
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        guard !cleanedRecipientEmail.isEmpty else {
            throw makeError("Please enter the recipient email.")
        }
        
        guard cleanedRecipientEmail != senderEmail.lowercased() else {
            throw makeError("You cannot send money to yourself.")
        }
        
        guard amount > 0 else {
            throw makeError("Amount must be greater than $0.00.")
        }
        
        // Find receiver user by email.
        let receiverProfile = try await findUserByEmail(cleanedRecipientEmail)
        
        let transactionId = UUID().uuidString
        let now = Date()
        let amountDouble = decimalToDouble(amount)
        
        let outgoingTransaction = EcoPayPayments.Transaction(
            id: transactionId,
            type: .sent,
            status: .completed,
            amount: -amount,
            currency: "CAD",
            description: "Sent money",
            recipient: receiverProfile.name,
            date: now,
            category: .transfer,
            note: note,
            referenceNumber: "ECO-\(transactionId.prefix(8).uppercased())",
            cardLastFour: nil
        )
        
        try await performWalletTransfer(
            senderId: senderId,
            receiverId: receiverProfile.userId,
            senderEmail: senderEmail,
            receiverEmail: receiverProfile.email,
            receiverName: receiverProfile.name,
            transactionId: transactionId,
            amountDouble: amountDouble,
            amount: amount,
            note: note,
            createdAt: now
        )
        
        return outgoingTransaction
    }
    
    // MARK: - User Lookup
    
    private func findUserByEmail(_ email: String) async throws -> FirestoreUserProfile {
        let snapshot = try await db
            .collection(Collection.users)
            .whereField("email", isEqualTo: email)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            throw makeError("No EcoPay user found with this email.")
        }
        
        let data = document.data()
        
        let userId = data["userId"] as? String ?? document.documentID
        let userEmail = data["email"] as? String ?? email
        let name = data["name"] as? String ?? "EcoPay User"
        
        return FirestoreUserProfile(
            userId: userId,
            email: userEmail,
            name: name
        )
    }
    
    // MARK: - Firestore Transaction
    
    private func performWalletTransfer(
        senderId: String,
        receiverId: String,
        senderEmail: String,
        receiverEmail: String,
        receiverName: String,
        transactionId: String,
        amountDouble: Double,
        amount: Decimal,
        note: String?,
        createdAt: Date
    ) async throws {
        
        let senderWalletRef = db.collection(Collection.wallets).document(senderId)
        let receiverWalletRef = db.collection(Collection.wallets).document(receiverId)
        
        let senderTransactionRef = db.collection(Collection.transactions).document("\(transactionId)_sender")
        let receiverTransactionRef = db.collection(Collection.transactions).document("\(transactionId)_receiver")
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.runTransaction({ transaction, errorPointer -> Any? in
                
                do {
                    let senderSnapshot = try transaction.getDocument(senderWalletRef)
                    let receiverSnapshot = try transaction.getDocument(receiverWalletRef)
                    
                    // rest of your code...
                    
                    guard let senderData = senderSnapshot.data(),
                          let receiverData = receiverSnapshot.data() else {
                        errorPointer?.pointee = self.makeNSError("Wallet not found.")
                        return nil
                    }
                    
                    let senderBalance = senderData["balance"] as? Double ?? 0.0
                    let receiverBalance = receiverData["balance"] as? Double ?? 0.0
                    
                    guard senderBalance >= amountDouble else {
                        errorPointer?.pointee = self.makeNSError("Insufficient wallet balance.")
                        return nil
                    }
                    
                    let newSenderBalance = senderBalance - amountDouble
                    let newReceiverBalance = receiverBalance + amountDouble
                    
                    transaction.updateData([
                        "balance": newSenderBalance,
                        "updatedAt": FieldValue.serverTimestamp()
                    ], forDocument: senderWalletRef)
                    
                    transaction.updateData([
                        "balance": newReceiverBalance,
                        "updatedAt": FieldValue.serverTimestamp()
                    ], forDocument: receiverWalletRef)
                    
                    let senderTransactionData: [String: Any] = [
                        "userId": senderId,
                        "counterpartyUserId": receiverId,
                        "counterpartyEmail": receiverEmail,
                        "amount": -amountDouble,
                        "currency": "CAD",
                        "type": TransactionType.sent.rawValue,
                        "status": TransactionStatus.completed.rawValue,
                        "category": TransactionCategory.transfer.rawValue,
                        "description": "Sent money",
                        "recipient": receiverName,
                        "note": note ?? "",
                        "referenceNumber": "ECO-\(transactionId.prefix(8).uppercased())",
                        "createdAt": Timestamp(date: createdAt)
                    ]
                    
                    let receiverTransactionData: [String: Any] = [
                        "userId": receiverId,
                        "counterpartyUserId": senderId,
                        "counterpartyEmail": senderEmail,
                        "amount": amountDouble,
                        "currency": "CAD",
                        "type": TransactionType.received.rawValue,
                        "status": TransactionStatus.completed.rawValue,
                        "category": TransactionCategory.transfer.rawValue,
                        "description": "Received money",
                        "recipient": senderEmail,
                        "note": note ?? "",
                        "referenceNumber": "ECO-\(transactionId.prefix(8).uppercased())",
                        "createdAt": Timestamp(date: createdAt)
                    ]
                    
                    transaction.setData(senderTransactionData, forDocument: senderTransactionRef)
                    transaction.setData(receiverTransactionData, forDocument: receiverTransactionRef)
                    
                    return nil
                    
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
                
            }, completion: { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            })
        }
    }
    
    // MARK: - Helpers
    
    private func decimalToDouble(_ decimal: Decimal) -> Double {
        return NSDecimalNumber(decimal: decimal).doubleValue
    }
    
    private func makeError(_ message: String) -> Error {
        NSError(
            domain: "FirestoreTransferService",
            code: 400,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
    
    private func makeNSError(_ message: String) -> NSError {
        NSError(
            domain: "FirestoreTransferService",
            code: 400,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}

// MARK: - Firestore User Profile

private struct FirestoreUserProfile {
    let userId: String
    let email: String
    let name: String
}
