//
//  LoginView.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

// LoginView.swift
// EcoPayApp/Views/LoginView.swift
//
// The login screen for Eco-Pay. Supports email/password login,
// passkey login, and demo account autofill. Uses LoginViewModel
// for state management and input validation.
//
//  LoginView.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

import SwiftUI

// MARK: - Login View

struct LoginView: View {
    
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var viewModel: LoginViewModel
    
    // MARK: - Initialization
    
    init(appViewModel: AppViewModel) {
        _viewModel = StateObject(wrappedValue: LoginViewModel(appViewModel: appViewModel))
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Auth form
                formSection
                
                // Action buttons
                buttonSection
                
                // Footer
                footerSection
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
        }
        .background(AppTheme.Colors.background)
        .dismissKeyboardOnTap()
        .animation(AppTheme.Animation.standard, value: viewModel.errorMessage)
        .animation(AppTheme.Animation.standard, value: viewModel.isLoading)
        .animation(AppTheme.Animation.standard, value: viewModel.mode)
    }
}

// MARK: - Header Section

private extension LoginView {
    var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Spacer()
                .frame(height: 60)
            
            // App icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, AppTheme.Spacing.xs)
            
            // App name
            Text(AppConstants.App.name)
                .font(AppTheme.Typography.title)
                .foregroundStyle(AppTheme.Colors.primaryText)
            
            // Dynamic title
            Text(viewModel.mode.title)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.primaryText)
            
            // Dynamic subtitle
            Text(viewModel.mode.subtitle)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
                .frame(height: AppTheme.Spacing.xl)
        }
    }
}

// MARK: - Form Section

private extension LoginView {
    var formSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            
            // Full name field only appears during registration
            // Full name field only appears during registration
            if viewModel.isRegisterMode {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(viewModel.errorField == .fullName ? .red : .secondary)
                        .frame(width: 20)
                    
                    TextField("Enter your full name", text: $viewModel.fullName)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .font(AppTheme.Typography.body)
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(
                            viewModel.errorField == .fullName ? Color.red : Color.clear,
                            lineWidth: 1
                        )
                )
                .cornerRadius(AppTheme.CornerRadius.medium)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Email field
            AppTextField.email(
                text: $viewModel.email,
                hasError: viewModel.errorField == .email
            )
            
            // Password field
            AppTextField.password(
                text: $viewModel.password,
                isVisible: viewModel.isPasswordVisible,
                hasError: viewModel.errorField == .password,
                onToggleVisibility: {
                    viewModel.togglePasswordVisibility()
                }
            )
            
            // Password hint for registration
            if viewModel.isRegisterMode {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13))
                    
                    Text("Password must be at least 8 characters.")
                        .font(AppTheme.Typography.caption)
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
            }
            
            // Error message
            if let errorMessage = viewModel.errorMessage {
                errorBanner(message: errorMessage)
            }
        }
    }
    
    func errorBanner(message: String) -> some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(.red)
            
            Text(message)
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(.red)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(AppTheme.Spacing.sm)
        .background(Color.red.opacity(0.1))
        .cornerRadius(AppTheme.CornerRadius.small)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

// MARK: - Button Section

private extension LoginView {
    var buttonSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Spacer()
                .frame(height: AppTheme.Spacing.md)
            
            // Primary auth button
            PrimaryButton(
                title: viewModel.showSuccess ? "Success!" : viewModel.mode.primaryButtonTitle,
                icon: viewModel.showSuccess ? "checkmark.circle.fill" : primaryButtonIcon,
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.isPrimaryButtonEnabled
            ) {
                Task {
                    await viewModel.submit()
                }
            }
            
            // Switch login/register mode
            HStack(spacing: 4) {
                Text(viewModel.mode.switchPrompt)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.secondary)
                
                Button {
                    viewModel.toggleMode()
                } label: {
                    Text(viewModel.mode.switchButtonTitle)
                        .font(AppTheme.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
                .disabled(viewModel.isLoading)
            }
            .padding(.top, AppTheme.Spacing.xs)
            
            // Passkey login button only shown in login mode
            if viewModel.isLoginMode && viewModel.isPasskeyAvailable {
                PrimaryButton(
                    title: "Sign In with Passkey",
                    icon: AppConstants.Icons.passkey,
                    isLoading: false,
                    isEnabled: !viewModel.isLoading,
                    style: .secondary
                ) {
                    Task {
                        await viewModel.loginWithPasskey()
                    }
                }
                .transition(.opacity)
            }
            
            // Divider
            if viewModel.isLoginMode {
                dividerRow
                
                // Demo account button only for login mode
                Button(action: {
                    viewModel.fillDemoCredentials()
                }) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 14))
                        
                        Text("Use Demo Account")
                            .font(AppTheme.Typography.subheadline)
                    }
                    .foregroundStyle(.blue)
                }
                .disabled(viewModel.isLoading)
                .padding(.top, AppTheme.Spacing.xs)
                .transition(.opacity)
            }
        }
    }
    
    var primaryButtonIcon: String {
        switch viewModel.mode {
        case .login:
            return "arrow.right"
        case .register:
            return "person.badge.plus"
        }
    }
    
    var dividerRow: some View {
        HStack {
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
            
            Text("or")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppTheme.Spacing.sm)
            
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

// MARK: - Footer Section

private extension LoginView {
    var footerSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Spacer()
                .frame(height: AppTheme.Spacing.xl)
            
            if viewModel.isLoginMode {
                // Demo credentials hint
                VStack(spacing: AppTheme.Spacing.xxs) {
                    Text("Demo Credentials")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                    
                    Text("\(AppConstants.MockUser.email)")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\(AppConstants.MockUser.password)")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(AppTheme.Spacing.md)
                .frame(maxWidth: .infinity)
                .background(AppTheme.Colors.secondaryBackground)
                .cornerRadius(AppTheme.CornerRadius.medium)
                .transition(.opacity)
            } else {
                // Register mode info
                VStack(spacing: AppTheme.Spacing.xxs) {
                    Text("New Wallet Account")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                    
                    Text("A Firebase account, user profile, and starter wallet balance will be created.")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(AppTheme.Spacing.md)
                .frame(maxWidth: .infinity)
                .background(AppTheme.Colors.secondaryBackground)
                .cornerRadius(AppTheme.CornerRadius.medium)
                .transition(.opacity)
            }
            
            // App version
            Text("v\(AppConstants.App.version)")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, AppTheme.Spacing.sm)
            
            Spacer()
                .frame(height: AppTheme.Spacing.xl)
        }
    }
}

// MARK: - Preview

#Preview("Login Screen") {
    let appViewModel = AppViewModel()
    
    LoginView(appViewModel: appViewModel)
        .environmentObject(appViewModel)
}
