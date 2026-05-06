//
//  AddCardView.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

// AddCardView.swift
// EcoPayApp/Views/AddCardView.swift
//
// Form for adding a new demo card to the wallet.
// Captures cardholder name, last 4 digits, expiry,
// and brand. Only stores demo data — no real card numbers.

import SwiftUI
import EcoPayPayments
import EcoPayAnalytics

// MARK: - Add Card View

struct AddCardView: View {
    
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Form State
    
    @State private var cardholderName: String = ""
    @State private var lastFour: String = ""
    @State private var selectedBrand: CardBrand = .visa
    @State private var expiryMonth: Int = 1
    @State private var expiryYear: Int = Calendar.current.component(.year, from: Date())
    
    // MARK: - UI State
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showSuccess: Bool = false
    
    // MARK: - Callback
    
    var onCardAdded: ((Card) -> Void)?
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        let hasName = !cardholderName
            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasDigits = lastFour.count == 4 && lastFour.allSatisfy({ $0.isNumber })
        return hasName && hasDigits && !isLoading
    }
    
    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(currentYear...(currentYear + 10))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if showSuccess {
                    successView
                } else {
                    formView
                }
            }
            .navigationTitle(showSuccess ? "Card Added" : "Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(showSuccess ? "Done" : "Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Form View

private extension AddCardView {
    var formView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Card preview
                cardPreview
                
                // Form fields
                formFields
                
                // Error message
                if let error = errorMessage {
                    errorBanner(error)
                }
                
                // Demo notice
                demoNotice
                
                // Add button
                PrimaryButton(
                    title: "Add Card",
                    icon: AppConstants.Icons.addCard,
                    isLoading: isLoading,
                    isEnabled: isFormValid
                ) {
                    Task {
                        await addCard()
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.top, AppTheme.Spacing.md)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
        .background(AppTheme.Colors.groupedBackground)
        .dismissKeyboardOnTap()
    }
    
    var cardPreview: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(selectedBrand.rawValue)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Image(systemName: "wave.3.right")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            Text(lastFour.isEmpty ? "•••• ••••" : "•••• \(lastFour)")
                .font(AppTheme.Typography.cardNumber)
                .foregroundStyle(.white.opacity(0.9))
                .padding(.bottom, AppTheme.Spacing.sm)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CARDHOLDER")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Text(
                        cardholderName.isEmpty
                            ? "YOUR NAME"
                            : cardholderName.uppercased()
                    )
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("EXPIRES")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Text(String(format: "%02d/%d", expiryMonth, expiryYear % 100))
                        .font(AppTheme.Typography.cardNumber)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 190)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: selectedBrand.colorHex),
                    Color(hex: selectedBrand.colorHex).opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppTheme.CornerRadius.card)
        .cardShadow()
        .animation(AppTheme.Animation.standard, value: selectedBrand)
    }
    
    var formFields: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Cardholder name
            AppTextField(
                placeholder: "Cardholder name",
                icon: "person.fill",
                text: $cardholderName,
                textContentType: .name,
                autocapitalization: .words
            )
            
            // Last 4 digits
            AppTextField(
                placeholder: "Last 4 digits",
                icon: "creditcard.fill",
                text: $lastFour,
                keyboardType: .numberPad
            )
            .onChange(of: lastFour) { _, newValue in
                // Limit to 4 digits only
                let filtered = newValue.filter { $0.isNumber }
                if filtered.count > 4 {
                    lastFour = String(filtered.prefix(4))
                } else {
                    lastFour = filtered
                }
            }
            
            // Card brand picker
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Card Brand")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: AppTheme.Spacing.xs) {
                    ForEach(
                        [CardBrand.visa, .mastercard, .amex, .discover],
                        id: \.self
                    ) { brand in
                        brandButton(brand)
                    }
                }
            }
            
            // Expiry pickers
            HStack(spacing: AppTheme.Spacing.md) {
                // Month picker
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Month")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                    
                    Picker("Month", selection: $expiryMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(String(format: "%02d", month)).tag(month)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(AppTheme.Spacing.sm)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.Colors.secondaryBackground)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }
                
                // Year picker
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Year")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                    
                    Picker("Year", selection: $expiryYear) {
                        ForEach(availableYears, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(AppTheme.Spacing.sm)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.Colors.secondaryBackground)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }
            }
        }
    }
    
    func brandButton(_ brand: CardBrand) -> some View {
        Button(action: {
            withAnimation(AppTheme.Animation.quick) {
                selectedBrand = brand
            }
        }) {
            Text(brand.rawValue)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xs)
                .frame(maxWidth: .infinity)
                .background(
                    selectedBrand == brand
                        ? Color(hex: brand.colorHex).opacity(0.15)
                        : AppTheme.Colors.secondaryBackground
                )
                .foregroundStyle(
                    selectedBrand == brand
                        ? Color(hex: brand.colorHex)
                        : .secondary
                )
                .cornerRadius(AppTheme.CornerRadius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .stroke(
                            selectedBrand == brand
                                ? Color(hex: brand.colorHex).opacity(0.3)
                                : Color.clear,
                            lineWidth: 1
                        )
                )
        }
    }
    
    var demoNotice: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: AppConstants.Icons.info)
                .font(.system(size: 14))
                .foregroundStyle(.blue)
            
            Text("This is a demo app. No real card data is stored or processed.")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(AppTheme.Spacing.sm)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(AppTheme.CornerRadius.small)
    }
    
    func errorBanner(_ message: String) -> some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(.red)
            
            Text(message)
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(.red)
            
            Spacer()
        }
        .padding(AppTheme.Spacing.sm)
        .background(Color.red.opacity(0.1))
        .cornerRadius(AppTheme.CornerRadius.small)
    }
}

// MARK: - Success View

private extension AddCardView {
    var successView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
            }
            
            Text("Card Added Successfully")
                .font(AppTheme.Typography.title2)
            
            Text("\(selectedBrand.rawValue) •••• \(lastFour)")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Add Card Logic

private extension AddCardView {
    func addCard() async {
        errorMessage = nil
        isLoading = true
        
        let request = AddCardRequest(
            brand: selectedBrand,
            lastFour: lastFour,
            cardholderName: cardholderName
                .trimmingCharacters(in: .whitespacesAndNewlines),
            expiryMonth: expiryMonth,
            expiryYear: expiryYear
        )
        
        do {
            let card = try await appViewModel.paymentService.addCard(request: request)
            onCardAdded?(card)
            appViewModel.analyticsService.track(
                .cardAdded(brand: card.brand.rawValue)
            )
            
            withAnimation {
                showSuccess = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Preview

#Preview("Add Card") {
    AddCardView()
        .environmentObject(AppViewModel())
}
