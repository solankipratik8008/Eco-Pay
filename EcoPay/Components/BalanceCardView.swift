//
//  BalanceCardView.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

// BalanceCardView.swift
// EcoPayApp/Components/BalanceCardView.swift
//
// Premium wallet card showing balance, card info, and gradient
// background. Used on the dashboard as the hero element.
// Designed to look like Apple Wallet or Ramp's card UI.

import SwiftUI
import EcoPayPayments

struct BalanceCardView: View {
    
    // MARK: - Properties
    
    let balance: String
    let card: Card?
    let currencyCode: String
    
    init(
        balance: String,
        card: Card? = nil,
        currencyCode: String = "USD"
    ) {
        self.balance = balance
        self.card = card
        self.currencyCode = currencyCode
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top row — label and card brand
            topRow
            
            Spacer()
                .frame(height: AppTheme.Spacing.md)
            
            // Balance amount
            balanceRow
            
            Spacer()
                .frame(height: AppTheme.Spacing.lg)
            
            // Bottom row — card info
            bottomRow
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 200)
        .background(
            AppTheme.Colors.cardGradient
        )
        .cornerRadius(AppTheme.CornerRadius.card)
        .cardShadow()
    }
}

// MARK: - Subviews

private extension BalanceCardView {
    
    var topRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Available Balance")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.white.opacity(0.7))
                
                Text(currencyCode)
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Card brand icon
            Image(systemName: "wave.3.right")
                .font(.system(size: 24))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    var balanceRow: some View {
        Text(balance)
            .font(AppTheme.Typography.balance)
            .foregroundStyle(.white)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
    }
    
    var bottomRow: some View {
        HStack {
            if let card {
                // Card number and brand
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.maskedNumber)
                        .font(AppTheme.Typography.cardNumber)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Text(card.brand.rawValue)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Expiry
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Expires")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Text(card.expiryString)
                        .font(AppTheme.Typography.cardNumber)
                        .foregroundStyle(.white.opacity(0.9))
                }
            } else {
                Text("No card linked")
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(.white.opacity(0.5))
                
                Spacer()
            }
        }
    }
}

// MARK: - Loading Variant

struct BalanceCardLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Shimmer placeholders
            RoundedRectangle(cornerRadius: 4)
                .fill(.white.opacity(0.2))
                .frame(width: 120, height: 14)
            
            Spacer()
                .frame(height: AppTheme.Spacing.lg)
            
            RoundedRectangle(cornerRadius: 6)
                .fill(.white.opacity(0.3))
                .frame(width: 200, height: 36)
            
            Spacer()
            
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.2))
                    .frame(width: 100, height: 14)
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.2))
                    .frame(width: 60, height: 14)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 200)
        .background(AppTheme.Colors.cardGradient)
        .cornerRadius(AppTheme.CornerRadius.card)
        .cardShadow()
        .opacity(isAnimating ? 0.7 : 1.0)
        .animation(
            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear { isAnimating = true }
    }
}

// MARK: - Preview

#Preview("Balance Card") {
    VStack(spacing: 20) {
        BalanceCardView(
            balance: "$12,458.50",
            card: Card.sampleVisa
        )
        
        BalanceCardView(
            balance: "$0.00",
            card: nil
        )
        
        BalanceCardLoadingView()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
