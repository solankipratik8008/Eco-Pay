//
//  EmptyStateView.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

// EmptyStateView.swift
// EcoPayApp/Components/EmptyStateView.swift
//
// Reusable empty state view shown when a list has no data
// or when an error occurs. Used in transaction list,
// wallet, and other screens. Supports optional action button.

import SwiftUI

struct EmptyStateView: View {
    
    // MARK: - Properties
    
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String?
    var buttonAction: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            // Title
            Text(title)
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.primaryText)
            
            // Message
            Text(message)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)
            
            // Optional action button
            if let buttonTitle, let buttonAction {
                Button(action: buttonAction) {
                    Text(buttonTitle)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(.blue)
                }
                .padding(.top, AppTheme.Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppTheme.Spacing.xl)
    }
}

// MARK: - Predefined Empty States

extension EmptyStateView {
    /// Empty state for when there are no transactions.
    static func noTransactions(onAction: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "list.bullet.rectangle.portrait",
            title: "No Transactions",
            message: "Your transaction history will appear here once you start making payments.",
            buttonTitle: onAction != nil ? "Send Payment" : nil,
            buttonAction: onAction
        )
    }
    
    /// Empty state for search with no results.
    static func noSearchResults(query: String) -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            message: "No transactions found for \"\(query)\". Try a different search term."
        )
    }
    
    /// Empty state for network errors.
    static func networkError(onRetry: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "Connection Error",
            message: "Unable to load data. Please check your connection and try again.",
            buttonTitle: "Try Again",
            buttonAction: onRetry
        )
    }
    
    /// Empty state for no cards.
    static func noCards(onAddCard: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "creditcard",
            title: "No Cards",
            message: "Add a card to start making payments.",
            buttonTitle: onAddCard != nil ? "Add Card" : nil,
            buttonAction: onAddCard
        )
    }
}

// MARK: - Preview

#Preview("Empty States") {
    ScrollView {
        VStack(spacing: 40) {
            EmptyStateView.noTransactions()
                .frame(height: 250)
            
            Divider()
            
            EmptyStateView.noSearchResults(query: "coffee")
                .frame(height: 250)
            
            Divider()
            
            EmptyStateView.networkError(onRetry: {})
                .frame(height: 250)
        }
    }
}
