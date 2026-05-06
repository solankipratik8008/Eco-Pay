//
//   TransactionRowView.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//
// TransactionRowView.swift
// EcoPayApp/Components/TransactionRowView.swift
//
// A single transaction row used in the dashboard's recent
// transactions and the full transaction list. Shows icon,
// description, recipient, date, amount, and status badge.

import SwiftUI
import EcoPayPayments

struct TransactionRowView: View {
    
    // MARK: - Properties
    
    let transaction: EcoPayPayments.Transaction
    var showDate: Bool = true
    var compact: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            // Transaction type icon
            transactionIcon
            
            // Description and details
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(compact ? AppTheme.Typography.subheadline : AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .lineLimit(1)
                
                HStack(spacing: AppTheme.Spacing.xxs) {
                    Text(transaction.recipient)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    if showDate {
                        Text("·")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(transaction.date.asRelativeDate())
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Amount and status
            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.formattedAmount)
                    .font(compact ? AppTheme.Typography.subheadline : AppTheme.Typography.headline)
                    .foregroundStyle(transaction.amountColor)
                
                // Status badge for non-completed transactions
                if transaction.status != .completed {
                    statusBadge
                }
            }
        }
        .padding(.vertical, compact ? AppTheme.Spacing.xs : AppTheme.Spacing.sm)
    }
}

// MARK: - Subviews

private extension TransactionRowView {
    
    var transactionIcon: some View {
        ZStack {
            Circle()
                .fill(transaction.iconColor.opacity(0.15))
                .frame(width: compact ? 36 : 42, height: compact ? 36 : 42)
            
            Image(systemName: transaction.iconName)
                .font(.system(size: compact ? 14 : 16, weight: .semibold))
                .foregroundStyle(transaction.iconColor)
        }
    }
    
    var statusBadge: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(transaction.status.statusColor)
                .frame(width: 6, height: 6)
            
            Text(transaction.status.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(transaction.status.statusColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(transaction.status.statusColor.opacity(0.1))
        .cornerRadius(4)
    }
}

// MARK: - Preview

#Preview("Transaction Rows") {
    List {
        TransactionRowView(
            transaction: EcoPayPayments.Transaction.sampleSalary
        )
        
        TransactionRowView(
            transaction: EcoPayPayments.Transaction.sampleRent
        )
        
        TransactionRowView(
            transaction: EcoPayPayments.Transaction.samplePending
        )
        
        TransactionRowView(
            transaction: EcoPayPayments.Transaction.sampleFailed
        )
        
        TransactionRowView(
            transaction: EcoPayPayments.Transaction.sampleRefund
        )
        
        TransactionRowView(
            transaction: EcoPayPayments.Transaction.sampleNetflix,
            compact: true
        )
    }
}
