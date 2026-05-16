//
//  SendPaymentView.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

// SendPaymentView.swift
// EcoPayApp/Views/SendPaymentView.swift
//
// Payment form with recipient, amount, note, confirmation
// dialog, processing state, and success screen.

import SwiftUI
import EcoPayPayments

// MARK: - Send Payment View

struct SendPaymentView: View {
    
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel: SendPaymentViewModel
    @Environment(\.dismiss) var dismiss
    
    var onPaymentCompleted: ((EcoPayPayments.Transaction) -> Void)?
    
    // MARK: - Initialization
    
    init(
        appViewModel: AppViewModel,
        onPaymentCompleted: ((EcoPayPayments.Transaction) -> Void)? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: SendPaymentViewModel(appViewModel: appViewModel)
        )
        self.onPaymentCompleted = onPaymentCompleted
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isSuccess {
                    successView
                } else {
                    formView
                }
            }
            .navigationTitle(viewModel.isSuccess ? "Payment Sent" : "Send Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(viewModel.isSuccess ? "Done" : "Cancel") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Confirm Payment",
                isPresented: $viewModel.showConfirmation,
                titleVisibility: .visible
            ) {
                Button("Send \(viewModel.formattedAmount)") {
                    Task {
                        await viewModel.sendPayment()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Send \(viewModel.formattedAmount) to \(viewModel.recipientName)?")            }
            .onAppear {
                viewModel.onPaymentCompleted = onPaymentCompleted
            }
        }
    }
}

// MARK: - Form View

private extension SendPaymentView {
    var formView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Amount display
                amountHeader
                
                // Form fields
                formFields
                
                // Error message
                if let error = viewModel.errorMessage {
                    errorBanner(error)
                }
                
                // Send button
                PrimaryButton(
                    title: "Review Payment",
                    icon: AppConstants.Icons.send,
                    isLoading: viewModel.paymentState.isProcessing,
                    isEnabled: viewModel.isSendEnabled
                ) {
                    viewModel.validateAndConfirm()
                }
                .padding(.top, AppTheme.Spacing.sm)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.top, AppTheme.Spacing.lg)
        }
        .background(AppTheme.Colors.groupedBackground)
        .dismissKeyboardOnTap()
    }
    
    var amountHeader: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text("Amount")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$")
                    .font(AppTheme.Typography.title)
                    .foregroundStyle(
                        viewModel.errorField == .amount
                            ? .red
                            : AppTheme.Colors.primaryText
                    )
                
                TextField("0.00", text: $viewModel.amountString)
                    .font(AppTheme.Typography.balance)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(
                        viewModel.errorField == .amount
                            ? .red
                            : AppTheme.Colors.primaryText
                    )
                    .frame(maxWidth: 200)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.lg)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
    }
    
    var formFields: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Recipient field
            AppTextField(
                placeholder: "Recipient email",
                icon: "envelope.fill",
                text: $viewModel.recipientName,
                hasError: viewModel.errorField == .recipient,
                textContentType: .emailAddress,
                autocapitalization: .never
            )
            
            // Note field
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack {
                    Text("Note (optional)")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(viewModel.noteCharacterCount)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(
                            viewModel.isNoteAtLimit ? .orange : .secondary
                        )
                }
                
                TextField("Add a note...", text: $viewModel.note, axis: .vertical)
                    .font(AppTheme.Typography.body)
                    .lineLimit(3...5)
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.secondaryBackground)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    .onChange(of: viewModel.note) { _, newValue in
                        if newValue.count > AppConstants.Validation.maxNoteLength {
                            viewModel.note = String(
                                newValue.prefix(AppConstants.Validation.maxNoteLength)
                            )
                        }
                    }
            }
        }
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
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

// MARK: - Success View

private extension SendPaymentView {
    var successView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()
            
            // Success icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
            }
            
            // Amount sent
            Text(viewModel.formattedAmount)
                .font(AppTheme.Typography.balance)
                .foregroundStyle(AppTheme.Colors.primaryText)
            
            // Recipient
            VStack(spacing: AppTheme.Spacing.xxs) {
                Text("Sent to email")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(viewModel.recipientName)
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(AppTheme.Colors.primaryText)
            }
            
            // Status
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                Text("Completed")
                    .font(AppTheme.Typography.subheadline)
            }
            .foregroundStyle(.green)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(Color.green.opacity(0.1))
            .cornerRadius(AppTheme.CornerRadius.small)
            
            Spacer()
            
            // Send another button
            PrimaryButton(
                title: "Send Another Payment",
                icon: AppConstants.Icons.send,
                style: .secondary
            ) {
                withAnimation {
                    viewModel.resetForm()
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Send Payment") {
    SendPaymentView(appViewModel: AppViewModel())
        .environmentObject(AppViewModel())
}

#Preview("Success State") {
    let vm = AppViewModel()
    SendPaymentView(appViewModel: vm)
        .environmentObject(vm)
}
