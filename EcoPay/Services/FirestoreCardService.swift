//
//  FirestoreCardService.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-15.
//

import Foundation
import FirebaseFirestore
import EcoPayPayments

final class FirestoreCardService {
    
    private let db = Firestore.firestore()
    
    private enum Collection {
        static let users = "users"
        static let cards = "cards"
    }
    
    // MARK: - Add Card
    
    func addCard(
        userId: String,
        request: AddCardRequest
    ) async throws -> Card {
        
        guard request.isValid else {
            throw makeError("Please enter valid card details.")
        }
        
        let cardsCollection = db
            .collection(Collection.users)
            .document(userId)
            .collection(Collection.cards)
        
        let existingCards = try await cardsCollection.getDocuments()
        let shouldBeDefault = existingCards.documents.isEmpty
        
        let cardRef = cardsCollection.document()
        
        let card = Card(
            id: cardRef.documentID,
            brand: request.brand,
            lastFour: request.lastFour,
            cardholderName: request.cardholderName,
            expiryMonth: request.expiryMonth,
            expiryYear: request.expiryYear,
            isDefault: shouldBeDefault
        )
        
        try await cardRef.setData([
            "id": card.id,
            "brand": card.brand.rawValue,
            "lastFour": card.lastFour,
            "cardholderName": card.cardholderName,
            "expiryMonth": card.expiryMonth,
            "expiryYear": card.expiryYear,
            "isDefault": card.isDefault,
            "createdAt": FieldValue.serverTimestamp()
        ])
        
        return card
    }
    
    // MARK: - Fetch Cards
    
    func fetchCards(userId: String) async throws -> [Card] {
        let snapshot = try await db
            .collection(Collection.users)
            .document(userId)
            .collection(Collection.cards)
            .getDocuments()
        
        let cards: [Card] = snapshot.documents.compactMap { document in
            let data = document.data()
            
            guard
                let brandRaw = data["brand"] as? String,
                let lastFour = data["lastFour"] as? String,
                let cardholderName = data["cardholderName"] as? String,
                let expiryMonth = data["expiryMonth"] as? Int,
                let expiryYear = data["expiryYear"] as? Int
            else {
                return nil
            }
            
            return Card(
                id: data["id"] as? String ?? document.documentID,
                brand: CardBrand(rawValue: brandRaw) ?? .unknown,
                lastFour: lastFour,
                cardholderName: cardholderName,
                expiryMonth: expiryMonth,
                expiryYear: expiryYear,
                isDefault: data["isDefault"] as? Bool ?? false
            )
        }
        
        return cards.sorted { first, second in
            if first.isDefault != second.isDefault {
                return first.isDefault && !second.isDefault
            }
            return first.id < second.id
        }
    }
    
    // MARK: - Helper
    
    private func makeError(_ message: String) -> Error {
        NSError(
            domain: "FirestoreCardService",
            code: 400,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}
