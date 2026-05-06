//
//  TransactionListView.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

// TransactionListView.swift
// EcoPayApp/Views/TransactionListView.swift
//
// Full transaction history with search, type/status filters,
// date-grouped sections, and transaction detail sheet.
// Presented as a sheet from the dashboard.

import SwiftUI
import EcoPayPayments

// MARK: - Transaction List View

struct TransactionListView: View {
    
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel: TransactionViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var showFilters = false
    @State private var selectedTransaction: EcoPayPayments.Transaction?
    
    // MARK: - Initialization
    
    init(appViewModel: AppViewModel) {
        _viewModel = StateObject(
            wrappedValue: TransactionViewModel(appViewModel: appViewModel)
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Filter chips
                if showFilters {
                    filterSection
                }
                
                // Transaction list
                transactionContent
            }
            .background(AppTheme.Colors.groupedBackground)
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    filterButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await viewModel.loadTransactions()
            }
            .sheet(item: $selectedTransaction) { transaction in
                TransactionDetailView(transaction: transaction)
            }
        }
    }
}

// MARK: - Search Bar

private extension TransactionListView {
    var searchBar: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: AppConstants.Icons.search)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            
            TextField("Search transactions...", text: viewModel.searchText)
                .font(AppTheme.Typography.body)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            if !viewModel.filter.searchText.isEmpty {
                Button(action: {
                    viewModel.filter.searchText = ""
                }) {
                    Image(systemName: AppConstants.Icons.close)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

// MARK: - Filter Button

private extension TransactionListView {
    var filterButton: some View {
        Button(action: {
            withAnimation(AppTheme.Animation.standard) {
                showFilters.toggle()
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 16))
                
                if viewModel.activeFilterCount > 0 {
                    Text("\(viewModel.activeFilterCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(.blue)
                        .clipShape(Circle())
                }
            }
        }
    }
}

// MARK: - Filter Section

private extension TransactionListView {
    var filterSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Type filters
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text("Type")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            filterChip(
                                title: type.displayName,
                                icon: type.iconName,
                                isSelected: viewModel.filter.type == type,
                                color: type.iconColor
                            ) {
                                viewModel.filterByType(type)
                            }
                        }
                    }
                }
            }
            
            // Status filters
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text("Status")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        ForEach(TransactionStatus.allCases, id: \.self) { status in
                            filterChip(
                                title: status.displayName,
                                icon: status.iconName,
                                isSelected: viewModel.filter.status == status,
                                color: status.statusColor
                            ) {
                                viewModel.filterByStatus(status)
                            }
                        }
                    }
                }
            }
            
            // Clear filters button
            if viewModel.hasActiveFilters {
                Button(action: {
                    viewModel.clearFilters()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Clear All Filters")
                            .font(AppTheme.Typography.caption)
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.bottom, AppTheme.Spacing.sm)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    func filterChip(
        title: String,
        icon: String,
        isSelected: Bool,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(isSelected ? color.opacity(0.15) : AppTheme.Colors.secondaryBackground)
            .foregroundStyle(isSelected ? color : .secondary)
            .cornerRadius(AppTheme.CornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(isSelected ? color.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - Transaction Content

private extension TransactionListView {
    @ViewBuilder
    var transactionContent: some View {
        if viewModel.listState.isLoading && !viewModel.isRefreshing {
            loadingView
        } else if case .error(let message) = viewModel.listState {
            EmptyStateView.networkError {
                Task { await viewModel.refresh() }
            }
        } else if viewModel.isTrulyEmpty {
            EmptyStateView.noTransactions()
        } else if viewModel.isFilteredEmpty {
            if !viewModel.filter.searchText.isEmpty {
                EmptyStateView.noSearchResults(
                    query: viewModel.filter.searchText
                )
            } else {
                EmptyStateView(
                    icon: "line.3.horizontal.decrease.circle",
                    title: "No Matches",
                    message: "No transactions match your current filters.",
                    buttonTitle: "Clear Filters",
                    buttonAction: { viewModel.clearFilters() }
                )
            }
        } else {
            groupedList
        }
    }
    
    var groupedList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(viewModel.groupedTransactions, id: \.0) { group in
                    Section {
                        VStack(spacing: 0) {
                            ForEach(group.1) { transaction in
                                Button(action: {
                                    selectedTransaction = transaction
                                }) {
                                    TransactionRowView(
                                        transaction: transaction
                                    )
                                    .padding(.horizontal, AppTheme.Spacing.md)
                                }
                                .buttonStyle(.plain)
                                
                                if transaction.id != group.1.last?.id {
                                    Divider()
                                        .padding(.leading, 70)
                                }
                            }
                        }
                        .background(AppTheme.Colors.secondaryBackground)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.bottom, AppTheme.Spacing.sm)
                    } header: {
                        sectionHeader(title: group.0)
                    }
                }
            }
            .padding(.top, AppTheme.Spacing.xs)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.Typography.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(AppTheme.Colors.groupedBackground)
    }
    
    var loadingView: some View {
        VStack(spacing: 0) {
            ForEach(0..<6, id: \.self) { _ in
                HStack(spacing: AppTheme.Spacing.sm) {
                    Circle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 42, height: 42)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(width: .random(in: 100...160), height: 14)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.1))
                            .frame(width: .random(in: 70...110), height: 12)
                    }
                    
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: .random(in: 50...80), height: 14)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
            }
        }
        .padding(.top, AppTheme.Spacing.md)
        .redacted(reason: .placeholder)
    }
}

// MARK: - Transaction Detail View

struct TransactionDetailView: View {
    
    let transaction: EcoPayPayments.Transaction
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Amount header
                    amountHeader
                    
                    // Detail rows
                    detailCard
                    
                    // Note section
                    if let note = transaction.note {
                        noteSection(note)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.lg)
            }
            .background(AppTheme.Colors.groupedBackground)
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

// MARK: - Detail Subviews

private extension TransactionDetailView {
    
    var amountHeader: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Type icon
            ZStack {
                Circle()
                    .fill(transaction.iconColor.opacity(0.15))
                    .frame(width: 64, height: 64)
                
                Image(systemName: transaction.iconName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(transaction.iconColor)
            }
            
            // Amount
            Text(transaction.formattedAmount)
                .font(AppTheme.Typography.balance)
                .foregroundStyle(transaction.amountColor)
            
            // Status badge
            HStack(spacing: 6) {
                Image(systemName: transaction.status.iconName)
                    .font(.system(size: 14))
                
                Text(transaction.status.displayName)
                    .font(AppTheme.Typography.subheadline)
            }
            .foregroundStyle(transaction.status.statusColor)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xxs)
            .background(transaction.status.statusColor.opacity(0.1))
            .cornerRadius(AppTheme.CornerRadius.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.md)
    }
    
    var detailCard: some View {
        VStack(spacing: 0) {
            detailRow(
                label: "Description",
                value: transaction.description,
                icon: "text.alignleft"
            )
            
            Divider().padding(.leading, 44)
            
            detailRow(
                label: transaction.isIncoming ? "From" : "To",
                value: transaction.recipient,
                icon: "person.fill"
            )
            
            Divider().padding(.leading, 44)
            
            detailRow(
                label: "Date",
                value: transaction.date.asTransactionDetail(),
                icon: "calendar"
            )
            
            Divider().padding(.leading, 44)
            
            detailRow(
                label: "Type",
                value: transaction.type.displayName,
                icon: transaction.type.iconName
            )
            
            Divider().padding(.leading, 44)
            
            detailRow(
                label: "Category",
                value: transaction.category.displayName,
                icon: transaction.category.iconName
            )
            
            if let refNumber = transaction.referenceNumber {
                Divider().padding(.leading, 44)
                
                detailRow(
                    label: "Reference",
                    value: refNumber,
                    icon: "number"
                )
            }
            
            if let cardLastFour = transaction.cardLastFour {
                Divider().padding(.leading, 44)
                
                detailRow(
                    label: "Card Used",
                    value: "•••• \(cardLastFour)",
                    icon: "creditcard.fill"
                )
            }
        }
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
    }
    
    func detailRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.primaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
    }
    
    func noteSection(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "note.text")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                
                Text("Note")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(note)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
    }
}

// MARK: - Preview

#Preview("Transaction List") {
    TransactionListView(appViewModel: AppViewModel())
        .environmentObject(AppViewModel())
}

#Preview("Transaction Detail") {
    TransactionDetailView(
        transaction: EcoPayPayments.Transaction.sampleRent
    )
}
