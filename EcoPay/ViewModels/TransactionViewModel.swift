//
//  TransactionViewModel.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

// TransactionViewModel.swift
// EcoPayApp/ViewModels/TransactionViewModel.swift
//
// Manages the full transaction list with search, filtering,
// and detail view. Separate from WalletViewModel because
// the transaction list has its own pagination, filter state,
// and search logic that would bloat the wallet ViewModel.

import SwiftUI
import EcoPayPayments
import EcoPayAnalytics
import Combine
import EcoPayAuthKit

// MARK: - Transaction ViewModel

@MainActor
final class TransactionViewModel: ObservableObject {
    
    // MARK: - Published State
    
    /// Current state of the transaction list
    @Published var listState: TransactionListState = .idle
    
    /// All loaded transactions (unfiltered)
    @Published var allTransactions: [EcoPayPayments.Transaction] = []
    
    /// Active filter configuration
    @Published var filter: TransactionFilter = TransactionFilter()
    
    /// Selected transaction for detail view
    @Published var selectedTransaction: EcoPayPayments.Transaction?
    
    /// Whether detail is loading
    @Published var isLoadingDetail: Bool = false
    
    /// Whether a refresh is in progress
    @Published var isRefreshing: Bool = false
    
    // MARK: - Dependencies
    
    private let paymentService: PaymentServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private weak var appViewModel: AppViewModel?
    
    // MARK: - Computed Properties
    
    /// Transactions after applying all active filters.
    var filteredTransactions: [EcoPayPayments.Transaction] {
        if filter.isEmpty {
            return allTransactions
        }
        return filter.apply(to: allTransactions)
    }
    
    /// Whether any filter is active
    var hasActiveFilters: Bool {
        return !filter.isEmpty
    }
    
    /// Number of active filters (for badge display)
    var activeFilterCount: Int {
        return filter.activeFilterCount
    }
    
    /// Whether the list is empty after filtering
    var isFilteredEmpty: Bool {
        return !allTransactions.isEmpty && filteredTransactions.isEmpty
    }
    
    /// Whether the list is truly empty (no data at all)
    var isTrulyEmpty: Bool {
        return allTransactions.isEmpty && !listState.isLoading
    }
    
    /// Search text binding with debounce behavior
    var searchText: Binding<String> {
        Binding(
            get: { self.filter.searchText },
            set: { self.filter.searchText = $0 }
        )
    }
    
    // MARK: - Initialization
    
    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
        self.paymentService = appViewModel.paymentService
        self.analyticsService = appViewModel.analyticsService
    }
    
    // MARK: - Load Transactions
    
    /// Loads all transactions from the API.
    func loadTransactions() async {
        guard !listState.isLoading || isRefreshing else { return }
        
        if !isRefreshing {
            listState = .loading
        }
        
        do {
            let response = try await paymentService.fetchTransactions(
                page: 1,
                limit: 50
            )
            
            allTransactions = response.transactions
            listState = .loaded(response.transactions)
            
            analyticsService.track(
                .transactionsViewed(count: response.transactions.count)
            )
        } catch let error as PaymentError {
            if error.requiresReLogin {
                if let appViewModel {
                    await appViewModel.handleAuthError(.sessionExpired)
                }
            } else {
                listState = .error(error.localizedDescription)
            }
        } catch {
            listState = .error(error.localizedDescription)
        }
        
        isRefreshing = false
    }
    
    /// Pull-to-refresh handler.
    func refresh() async {
        isRefreshing = true
        await loadTransactions()
    }
    
    // MARK: - Transaction Detail
    
    /// Loads full detail for a single transaction.
    func loadTransactionDetail(id: String) async {
        isLoadingDetail = true
        
        do {
            let detail = try await paymentService.fetchTransaction(id: id)
            selectedTransaction = detail
            
            analyticsService.track(
                .transactionDetailViewed(id: id)
            )
        } catch {
            // Fall back to the list version if detail fetch fails
            selectedTransaction = allTransactions.first(where: { $0.id == id })
        }
        
        isLoadingDetail = false
    }
    
    // MARK: - Filter Management
    
    /// Sets a type filter.
    func filterByType(_ type: TransactionType?) {
        withAnimation(AppTheme.Animation.standard) {
            if filter.type == type {
                filter.type = nil
            } else {
                filter.type = type
            }
        }
    }
    
    /// Sets a status filter.
    func filterByStatus(_ status: TransactionStatus?) {
        withAnimation(AppTheme.Animation.standard) {
            if filter.status == status {
                filter.status = nil
            } else {
                filter.status = status
            }
        }
    }
    
    /// Sets a category filter.
    func filterByCategory(_ category: TransactionCategory?) {
        withAnimation(AppTheme.Animation.standard) {
            if filter.category == category {
                filter.category = nil
            } else {
                filter.category = category
            }
        }
    }
    
    /// Clears all active filters.
    func clearFilters() {
        withAnimation(AppTheme.Animation.standard) {
            filter.reset()
        }
    }
    
    // MARK: - Grouping
    
    /// Groups filtered transactions by date for section headers.
    /// Returns tuples of (date label, transactions).
    var groupedTransactions: [(String, [EcoPayPayments.Transaction])] {
        let sorted = filteredTransactions.sorted { $0.date > $1.date }
        
        let grouped = Dictionary(grouping: sorted) { transaction -> String in
            let calendar = Calendar.current
            if calendar.isDateInToday(transaction.date) {
                return "Today"
            } else if calendar.isDateInYesterday(transaction.date) {
                return "Yesterday"
            } else if calendar.isDate(
                transaction.date,
                equalTo: Date(),
                toGranularity: .weekOfYear
            ) {
                return "This Week"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: transaction.date)
            }
        }
        
        // Sort groups: Today first, then Yesterday, then by date
        let order = ["Today", "Yesterday", "This Week"]
        let sortedGroups = grouped.sorted { a, b in
            let aIndex = order.firstIndex(of: a.key) ?? Int.max
            let bIndex = order.firstIndex(of: b.key) ?? Int.max
            
            if aIndex != Int.max || bIndex != Int.max {
                return aIndex < bIndex
            }
            
            // For month groups, sort by actual date descending
            let aDate = a.value.first?.date ?? Date.distantPast
            let bDate = b.value.first?.date ?? Date.distantPast
            return aDate > bDate
        }
        
        return sortedGroups.map { ($0.key, $0.value) }
    }
}
