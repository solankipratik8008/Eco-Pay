//
//  HomeDashboardView.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

// HomeDashboardView.swift
// EcoPayApp/Views/HomeDashboardView.swift
//
// The main dashboard screen shown after login. Displays wallet
// balance, quick action buttons, and recent transactions.
// Uses WalletViewModel for data and supports pull-to-refresh.

import SwiftUI
import EcoPayPayments
import EcoPayAuthKit

// MARK: - Home Dashboard View

struct HomeDashboardView: View {
    
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel: WalletViewModel
    
    // MARK: - Navigation State
    
    @State private var showSendPayment = false
    @State private var showAddCard = false
    @State private var showTransactions = false
    @State private var showSecurity = false
    @State private var showProfile = false
    @State private var selectedTransaction: EcoPayPayments.Transaction?
    
    // MARK: - Initialization
    
    init(appViewModel: AppViewModel) {
        _viewModel = StateObject(
            wrappedValue: WalletViewModel(appViewModel: appViewModel)
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Balance card
                    balanceSection
                    
                    // Quick actions
                    quickActionsSection
                    
                    // Recent transactions
                    recentTransactionsSection
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.xl)
            }
            .background(AppTheme.Colors.groupedBackground)
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    profileButton
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadDashboardData()
            }
            .sheet(isPresented: $showAddCard) {
                AddCardView(
                    onCardAdded: { card in
                        viewModel.onCardAdded(card)
                        
                        Task {
                            await viewModel.refresh()
                        }
                    }
                )
                .environmentObject(appViewModel)
            }
            .sheet(isPresented: $showAddCard) {
                AddCardView(
                    onCardAdded: { card in
                        viewModel.onCardAdded(card)
                    }
                )
                .environmentObject(appViewModel)
            }
            .sheet(isPresented: $showTransactions) {
                TransactionListView(appViewModel: appViewModel)
                    .environmentObject(appViewModel)
            }
            .sheet(isPresented: $showSecurity) {
                SecuritySettingsView()
                    .environmentObject(appViewModel)
            }
            .sheet(isPresented: $showProfile) {
                profileSheet
            }
            .sheet(item: $selectedTransaction) { transaction in
                TransactionDetailView(transaction: transaction)
            }
        }
    }
}

// MARK: - Balance Section

private extension HomeDashboardView {
    var balanceSection: some View {
        Group {
            if viewModel.isLoading && !viewModel.isRefreshing {
                BalanceCardLoadingView()
            } else if viewModel.hasError {
                errorCard
            } else {
                BalanceCardView(
                    balance: viewModel.formattedBalance,
                    card: viewModel.defaultCard,
                    cards: viewModel.cards,
                    currencyCode: "CAD"
                )
            }
        }
        .padding(.top, AppTheme.Spacing.xs)
    }
    
    var errorCard: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.orange)
            
            Text("Unable to load wallet")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.white)
            
            Text(viewModel.errorMessage ?? "Please try again.")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await viewModel.refresh()
                }
            }
            .font(AppTheme.Typography.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(.white.opacity(0.2))
            .cornerRadius(AppTheme.CornerRadius.button)
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(AppTheme.Colors.cardGradient)
        .cornerRadius(AppTheme.CornerRadius.card)
        .cardShadow()
    }
}

// MARK: - Quick Actions Section

private extension HomeDashboardView {
    var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Quick Actions")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.primaryText)
            
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(viewModel.quickActions) { action in
                    quickActionButton(action)
                }
            }
        }
    }
    
    func quickActionButton(_ action: QuickAction) -> some View {
        Button(action: {
            handleQuickAction(action.destination)
        }) {
            VStack(spacing: AppTheme.Spacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(action.color.opacity(0.12))
                        .frame(height: 56)
                    
                    Image(systemName: action.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(action.color)
                }
                
                Text(action.title)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.primaryText)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    func handleQuickAction(_ destination: QuickActionDestination) {
        switch destination {
        case .sendPayment:
            showSendPayment = true
        case .addCard:
            showAddCard = true
        case .transactions:
            showTransactions = true
        case .security:
            showSecurity = true
        }
    }
}

// MARK: - Recent Transactions Section

private extension HomeDashboardView {
    var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Header with "See All" button
            HStack {
                Text("Recent Transactions")
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                
                Spacer()
                
                if !viewModel.recentTransactions.isEmpty {
                    Button("See All") {
                        showTransactions = true
                    }
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.blue)
                }
            }
            
            // Content
            if viewModel.isLoadingTransactions && !viewModel.isRefreshing {
                transactionLoadingView
            } else if let error = viewModel.transactionError {
                transactionErrorView(error)
            } else if viewModel.recentTransactions.isEmpty {
                EmptyStateView.noTransactions {
                    showSendPayment = true
                }
                .frame(height: 180)
            } else {
                transactionList
            }
        }
    }
    
    var transactionList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.recentTransactions) { transaction in
                Button(action: {
                    selectedTransaction = transaction
                }) {
                    TransactionRowView(transaction: transaction)
                }
                .buttonStyle(.plain)
                
                if transaction.id != viewModel.recentTransactions.last?.id {
                    Divider()
                        .padding(.leading, 54)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
    }
    
    var transactionLoadingView: some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: AppTheme.Spacing.sm) {
                    Circle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 42, height: 42)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(width: 140, height: 14)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.1))
                            .frame(width: 90, height: 12)
                    }
                    
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 70, height: 14)
                }
                .padding(.vertical, AppTheme.Spacing.sm)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
        .redacted(reason: .placeholder)
    }
    
    func transactionErrorView(_ error: String) -> some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
            
            Text(error)
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await viewModel.refresh()
                }
            }
            .font(AppTheme.Typography.subheadline)
            .foregroundStyle(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
    }
}

// MARK: - Profile Button & Sheet

private extension HomeDashboardView {
    var profileButton: some View {
        Button(action: { showProfile = true }) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Text(userInitials)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.blue)
            }
        }
    }
    
    var userInitials: String {
        guard let name = appViewModel.currentUser?.name else { return "?" }
        let parts = name.split(separator: " ")
        let initials = parts.compactMap { $0.first }.map { String($0) }
        return initials.prefix(2).joined()
    }
    
    var profileSheet: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Profile icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 80, height: 80)
                    
                    Text(userInitials)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(.blue)
                }
                .padding(.top, AppTheme.Spacing.lg)
                
                // User info
                VStack(spacing: AppTheme.Spacing.xxs) {
                    Text(appViewModel.currentUser?.name ?? "User")
                        .font(AppTheme.Typography.title2)
                    
                    Text(appViewModel.currentUser?.email ?? "")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Logout button
                PrimaryButton(
                    title: "Log Out",
                    icon: AppConstants.Icons.logout,
                    style: .destructive
                ) {
                    Task {
                        await appViewModel.logout()
                        showProfile = false
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.xl)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showProfile = false
                    }
                }
            }
        }
    }
}

// MARK: - Placeholder Sheets
// These will be replaced with real views as we build them.

private struct SendPaymentPlaceholder: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            EmptyStateView(
                icon: AppConstants.Icons.send,
                title: "Send Payment",
                message: "Payment screen coming soon."
            )
            .navigationTitle("Send Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct AddCardPlaceholder: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            EmptyStateView(
                icon: AppConstants.Icons.addCard,
                title: "Add Card",
                message: "Add card screen coming soon."
            )
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct TransactionListPlaceholder: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            EmptyStateView(
                icon: AppConstants.Icons.transactions,
                title: "Transaction History",
                message: "Full transaction list coming soon."
            )
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct SecurityPlaceholder: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            EmptyStateView(
                icon: AppConstants.Icons.shield,
                title: "Security",
                message: "Security settings coming soon."
            )
            .navigationTitle("Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct TransactionDetailPlaceholder: View {
    let transaction: EcoPayPayments.Transaction
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.md) {
                Text(transaction.description)
                    .font(AppTheme.Typography.title2)
                Text(transaction.formattedAmount)
                    .font(AppTheme.Typography.balance)
                    .foregroundStyle(transaction.amountColor)
                Text(transaction.date.asTransactionDetail())
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Transaction Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Dashboard") {
    HomeDashboardView(appViewModel: AppViewModel())
        .environmentObject(AppViewModel())
}
