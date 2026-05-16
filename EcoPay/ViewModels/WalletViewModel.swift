//
//  WalletViewModel.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

// WalletViewModel.swift
// EcoPayApp/ViewModels/WalletViewModel.swift
//
// Manages wallet data, recent transactions, and cards.
// Provides the data for HomeDashboardView including
// balance, card list, and recent transaction list.
// Handles loading, refresh, and error states.

import SwiftUI
import EcoPayNetworking
import EcoPayPayments
import EcoPayAnalytics
import Combine
import EcoPayAuthKit

// MARK: - Wallet ViewModel

@MainActor
final class WalletViewModel: ObservableObject {
    
    // MARK: - Published State
    
    /// Current wallet state (idle, loading, loaded, error)
    @Published var walletState: WalletState = .idle
    
    /// Recent transactions for the dashboard (limited to 5)
    @Published var recentTransactions: [EcoPayPayments.Transaction] = []
    
    /// Whether transactions are loading
    @Published var isLoadingTransactions: Bool = false
    
    /// Error message for transactions
    @Published var transactionError: String?
    
    /// Whether a pull-to-refresh is in progress
    @Published var isRefreshing: Bool = false
    
    // MARK: - Dependencies
    
    private let paymentService: PaymentServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let firestoreWalletService = FirestoreWalletService()
    private weak var appViewModel: AppViewModel?
    
    // MARK: - Computed Properties
    
    /// Wallet balance formatted as currency string
    var formattedBalance: String {
        guard let balance = walletState.balance else {
            return "$0.00"
        }
        return balance.asCurrency()
    }
    
    /// List of cards from the wallet
    var cards: [Card] {
        return walletState.cards
    }
    
    /// The default card, if one exists
    var defaultCard: Card? {
        return cards.first(where: { $0.isDefault }) ?? cards.first
    }
    
    /// Whether wallet data has been loaded
    var isLoaded: Bool {
        if case .loaded = walletState { return true }
        return false
    }
    
    /// Whether wallet is in loading state
    var isLoading: Bool {
        return walletState.isLoading
    }
    
    /// Whether there's an error
    var hasError: Bool {
        if case .error = walletState { return true }
        return false
    }
    
    /// Error message if wallet failed to load
    var errorMessage: String? {
        if case .error(let message) = walletState { return message }
        return nil
    }
    
    /// Quick action items for the dashboard
    var quickActions: [QuickAction] {
        return [
            QuickAction(
                title: "Send",
                icon: AppConstants.Icons.send,
                color: .blue,
                destination: .sendPayment
            ),
            QuickAction(
                title: "Cards",
                icon: AppConstants.Icons.addCard,
                color: .purple,
                destination: .addCard
            ),
            QuickAction(
                title: "History",
                icon: AppConstants.Icons.transactions,
                color: .orange,
                destination: .transactions
            ),
            QuickAction(
                title: "Security",
                icon: AppConstants.Icons.shield,
                color: .green,
                destination: .security
            )
        ]
    }
    
    // MARK: - Initialization
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        self.paymentService = appViewModel.paymentService
        self.analyticsService = appViewModel.analyticsService
    }
    
    // MARK: - Load All Data
    
    /// Loads wallet and recent transactions together.
    /// Called when the dashboard first appears.
    func loadDashboardData() async {
        // Skip if already loaded and not refreshing
        guard !isLoaded || isRefreshing else { return }
        
        walletState = .loading
        isLoadingTransactions = true
        
        // Load wallet and transactions concurrently
        async let walletResult = loadWallet()
        async let transactionsResult = loadRecentTransactions()
        
        // Await both results
        let _ = await (walletResult, transactionsResult)
        
        isRefreshing = false
    }
    
    /// Pull-to-refresh handler.
    /// Reloads all data regardless of current state.
    func refresh() async {
        isRefreshing = true
        
        // Reset states to force reload
        walletState = .loading
        isLoadingTransactions = true
        
        async let walletResult = loadWallet()
        async let transactionsResult = loadRecentTransactions()
        
        let _ = await (walletResult, transactionsResult)
        
        isRefreshing = false
    }
    
    // MARK: - Wallet Loading
    
    /// Fetches wallet balance and cards from the API.
    private func loadWallet() async {
        guard let userId = appViewModel?.currentUser?.userId else {
            walletState = .error("User session not found. Please log in again.")
            return
        }
        
        do {
            let wallet = try await firestoreWalletService.fetchWallet(for: userId)
            walletState = .loaded(wallet)
            
            analyticsService.track(
                .walletViewed(balance: wallet.balance.asCurrency())
            )
        } catch {
            walletState = .error("Unable to load Firestore wallet: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Recent Transactions Loading
    
    /// Fetches the 5 most recent transactions for the dashboard.
    private func loadRecentTransactions() async {
        isLoadingTransactions = true
        transactionError = nil
        
        guard let userId = appViewModel?.currentUser?.userId else {
            recentTransactions = []
            transactionError = "User session not found."
            isLoadingTransactions = false
            return
        }
        
        do {
            let transactions = try await firestoreWalletService.fetchRecentTransactions(
                for: userId,
                limit: 5
            )
            
            recentTransactions = transactions
            isLoadingTransactions = false
            
            analyticsService.track(
                .transactionsViewed(count: transactions.count)
            )
        } catch {
            transactionError = "Unable to load Firestore transactions: \(error.localizedDescription)"
            isLoadingTransactions = false
        }
    }
    
    // MARK: - Card Added Callback
    
    /// Called when a new card is added from AddCardView.
    /// Refreshes wallet data to show the new card.
    func onCardAdded(_ card: Card) {
        // If wallet is loaded, add the card locally for instant UI update
        if case .loaded(let wallet) = walletState {
            var updatedCards = wallet.cards
            updatedCards.append(card)
            let updatedWallet = WalletResponse(
                balance: wallet.balance,
                currency: wallet.currency,
                cards: updatedCards
            )
            walletState = .loaded(updatedWallet)
        }
        
        analyticsService.track(.cardAdded(brand: card.brand.rawValue))
    }
    
    // MARK: - Payment Completed Callback
    
    /// Called when a payment is sent from SendPaymentView.
    /// Adds the transaction locally and refreshes balance.
    func onPaymentCompleted(_ transaction: EcoPayPayments.Transaction)  {
        // Add to recent transactions for instant UI update
        recentTransactions.insert(transaction, at: 0)
        
        // Keep only 5 recent
        if recentTransactions.count > 5 {
            recentTransactions = Array(recentTransactions.prefix(5))
        }
        
        // Refresh wallet to update balance
        Task {
            await loadWallet()
        }
    }
}

// MARK: - Quick Action Model

/// Represents a quick action button on the dashboard.
struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let destination: QuickActionDestination
}

/// Navigation destinations for quick actions.
enum QuickActionDestination {
    case sendPayment
    case addCard
    case transactions
    case security
}
