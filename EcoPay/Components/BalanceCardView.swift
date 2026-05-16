//
//  BalanceCardView.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

import SwiftUI
import EcoPayPayments

// MARK: - Balance Card Stack View

struct BalanceCardView: View {
    
    // MARK: - Properties
    
    let balance: String
    let card: Card?
    let cards: [Card]
    let currencyCode: String
    
    @State private var selectedCardIndex: Int = 0
    
    init(
        balance: String,
        card: Card? = nil,
        cards: [Card] = [],
        currencyCode: String = "CAD"
    ) {
        self.balance = balance
        self.card = card
        self.cards = cards
        self.currencyCode = currencyCode
    }
    
    // MARK: - Body
    
    var body: some View {
        if cards.isEmpty {
            singleCardView(card: card, balance: balance)
        } else {
            stackedCardsView
        }
    }
}

// MARK: - Stacked Cards

private extension BalanceCardView {
    
    var stackedCardsView: some View {
        ZStack {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                let visualIndex = visualIndex(for: index)
                let isSelected = index == selectedCardIndex
                
                walletCard(
                    card: card,
                    balance: displayBalance(for: index),
                    isSelected: isSelected
                )
                .offset(
                    x: CGFloat(visualIndex) * 10,
                    y: CGFloat(visualIndex) * 18
                )
                .scaleEffect(isSelected ? 1.0 : 0.94)
                .opacity(isSelected ? 1.0 : 0.82)
                .zIndex(isSelected ? 10 : Double(cards.count - visualIndex))
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        selectedCardIndex = index
                    }
                }
            }
        }
        .frame(height: cards.count > 1 ? 240 : 205)
    }
    
    func visualIndex(for index: Int) -> Int {
        if index == selectedCardIndex {
            return 0
        }
        
        let orderedIndexes = cards.indices.filter { $0 != selectedCardIndex }
        
        if let position = orderedIndexes.firstIndex(of: index) {
            return position + 1
        }
        
        return 1
    }
    
    func displayBalance(for index: Int) -> String {
        // For now, this creates a demo balance per card.
        // Later we can store real per-card balance in Firestore.
        if index == 0 {
            return balance
        }
        
        let demoBalances = [
            "$250.00",
            "$500.00",
            "$750.00",
            "$1,250.00"
        ]
        
        return demoBalances[index % demoBalances.count]
    }
}

// MARK: - Single Card

private extension BalanceCardView {
    
    func singleCardView(card: Card?, balance: String) -> some View {
        walletCard(
            card: card,
            balance: balance,
            isSelected: true
        )
    }
}

// MARK: - Wallet Card UI

private extension BalanceCardView {
    
    func walletCard(
        card: Card?,
        balance: String,
        isSelected: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            topRow(card: card)
            
            Spacer()
                .frame(height: AppTheme.Spacing.md)
            
            balanceRow(balance: balance)
            
            Spacer()
                .frame(height: AppTheme.Spacing.lg)
            
            bottomRow(card: card)
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 200)
        .background(
            cardGradient(for: card)
        )
        .cornerRadius(AppTheme.CornerRadius.card)
        .cardShadow()
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(
                    isSelected ? Color.white.opacity(0.25) : Color.clear,
                    lineWidth: 1
                )
        )
    }
    
    func topRow(card: Card?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(card == nil ? "Available Balance" : "\(card?.brand.rawValue ?? "Card") Balance")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.white.opacity(0.7))
                
                Text(currencyCode)
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            Image(systemName: "wave.3.right")
                .font(.system(size: 24))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    func balanceRow(balance: String) -> some View {
        Text(balance)
            .font(AppTheme.Typography.balance)
            .foregroundStyle(.white)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
    }
    
    func bottomRow(card: Card?) -> some View {
        HStack {
            if let card {
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.maskedNumber)
                        .font(AppTheme.Typography.cardNumber)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    HStack(spacing: 6) {
                        Text(card.brand.rawValue)
                            .font(AppTheme.Typography.caption)
                        
                        if card.isDefault {
                            Text("Default")
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.white.opacity(0.16))
                                .clipShape(Capsule())
                        }
                    }
                    .foregroundStyle(.white.opacity(0.6))
                }
                
                Spacer()
                
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
    
    func cardGradient(for card: Card?) -> LinearGradient {
        if let card {
            return LinearGradient(
                colors: [
                    Color(hex: card.brand.colorHex),
                    Color(hex: card.brand.colorHex).opacity(0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        return AppTheme.Colors.cardGradient
    }
}

// MARK: - Loading Variant

struct BalanceCardLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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

#Preview("Balance Card Stack") {
    VStack(spacing: 30) {
        BalanceCardView(
            balance: "$1,000.00",
            cards: Card.allSamples
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
