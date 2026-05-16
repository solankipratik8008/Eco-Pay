//
//  SendPaymentViewModel.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

// SendPaymentViewModel.swift
// EcoPayApp/ViewModels/SendPaymentViewModel.swift
//
// Manages the send payment flow — recipient input, amount,
// note, validation, confirmation, and success/failure states.

import SwiftUI
import EcoPayPayments
import EcoPayAnalytics
import Combine
import EcoPayAuthKit

// MARK: - Send Payment ViewModel

@MainActor
final class SendPaymentViewModel: ObservableObject {
    
    // MARK: - Form State
    
    @Published var recipientName: String = ""
    @Published var amountString: String = ""
    @Published var note: String = ""
    
    // MARK: - UI State
    
    @Published var paymentState: PaymentState = .idle
    @Published var errorMessage: String?
    @Published var errorField: PaymentField?
    @Published var showConfirmation: Bool = false
    
    // MARK: - Dependencies
    
    private let paymentService: PaymentServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let firestoreTransferService = FirestoreTransferService()
    private weak var appViewModel: AppViewModel?
    
    /// Callback when payment completes — notifies WalletViewModel
    var onPaymentCompleted: ((EcoPayPayments.Transaction) -> Void)?
    
    // MARK: - Computed Properties
    
    /// Parsed amount as Decimal
    var amount: Decimal? {
        let cleaned = amountString
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Decimal(string: cleaned)
    }
    
    /// Formatted amount for display in confirmation
    var formattedAmount: String {
        guard let amount else { return "$0.00" }
        return amount.asCurrency()
    }
    
    /// Whether the send button should be enabled
    var isSendEnabled: Bool {
        let hasRecipient = !recipientName
            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAmount = amount != nil && (amount ?? 0) > 0
        let notProcessing = !paymentState.isProcessing
        return hasRecipient && hasAmount && notProcessing
    }
    
    /// Whether payment succeeded
    var isSuccess: Bool {
        return paymentState.isSuccess
    }
    
    /// The completed transaction if payment succeeded
    var completedTransaction: EcoPayPayments.Transaction? {
        return paymentState.completedTransaction
    }
    
    /// Character count for note field
    var noteCharacterCount: String {
        return "\(note.count)/\(AppConstants.Validation.maxNoteLength)"
    }
    
    /// Whether note is at max length
    var isNoteAtLimit: Bool {
        return note.count >= AppConstants.Validation.maxNoteLength
    }
    
    // MARK: - Initialization
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        self.paymentService = appViewModel.paymentService
        self.analyticsService = appViewModel.analyticsService
    }
    
    // MARK: - Validation
    
    /// Validates all fields and shows the confirmation dialog.
    func validateAndConfirm() {
        clearError()
        
        // Validate recipient
        let trimmedRecipient = recipientName
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRecipient.isEmpty else {
            showFieldError(.recipient, message: "Please enter the recipient email.")
            return
        }
        
        guard trimmedRecipient.contains("@") else {
            showFieldError(.recipient, message: "Please enter a valid recipient email.")
            return
        }
        
        // Validate amount
        guard let amount else {
            showFieldError(.amount, message: "Please enter a valid amount.")
            return
        }
        
        guard amount >= AppConstants.Validation.minPaymentAmount else {
            showFieldError(.amount, message: "Amount must be at least $0.01.")
            return
        }
        
        guard amount <= AppConstants.Validation.maxPaymentAmount else {
            showFieldError(
                .amount,
                message: "Amount cannot exceed \(AppConstants.Validation.maxPaymentAmount.asCurrency())."
            )
            return
        }
        
        // All valid — show confirmation
        analyticsService.track(.paymentInitiated(amount: formattedAmount))
        showConfirmation = true
    }
    
    // MARK: - Send Payment
    
    /// Sends the payment after user confirms.
    func sendPayment() async {
        guard let amount else { return }
        
        guard let currentUser = appViewModel?.currentUser else {
            paymentState = .failed("User session not found. Please log in again.")
            errorMessage = "User session not found. Please log in again."
            return
        }
        
        paymentState = .processing
        showConfirmation = false
        
        let recipientEmail = recipientName
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            let transaction = try await firestoreTransferService.sendMoney(
                senderId: currentUser.userId,
                senderEmail: currentUser.email,
                recipientEmail: recipientEmail,
                amount: amount,
                note: note.nilIfEmpty
            )
            
            paymentState = .success(transaction)
            
            analyticsService.track(
                .paymentCompleted(
                    amount: formattedAmount,
                    recipient: recipientEmail
                )
            )
            
            // Notify dashboard to update balance and recent transaction list.
            onPaymentCompleted?(transaction)
            
        } catch {
            let message = error.localizedDescription
            
            paymentState = .failed(message)
            errorMessage = message
            
            analyticsService.track(
                .paymentFailed(reason: message)
            )
        }
    }
    
    // MARK: - Reset
    
    /// Resets the form for a new payment.
    func resetForm() {
        recipientName = ""
        amountString = ""
        note = ""
        paymentState = .idle
        clearError()
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
        errorField = nil
    }
    
    private func showFieldError(_ field: PaymentField, message: String) {
        withAnimation(AppTheme.Animation.quick) {
            errorMessage = message
            errorField = field
        }
    }
}

// MARK: - Payment Field

enum PaymentField: Equatable {
    case recipient
    case amount
    case note
}
