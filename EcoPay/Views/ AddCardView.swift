//
//   AddCardView.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

// SecuritySettingsView.swift
// EcoPayApp/Views/SecuritySettingsView.swift
//
// Security settings screen for managing passkey login,
// viewing session info, and security status.

import SwiftUI
import EcoPayAuthKit
import EcoPayAnalytics

// MARK: - Security Settings View

struct SecuritySettingsView: View {
    
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State
    
    @State private var isPasskeyEnabled: Bool = false
    @State private var isProcessing: Bool = false
    @State private var showRemoveConfirmation: Bool = false
    @State private var statusMessage: String?
    @State private var isError: Bool = false
    @State private var passkeyInfo: PasskeyInfo?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                // Passkey section
                passkeySection
                
                // Session info section
                sessionSection
                
                // Security info section
                securityInfoSection
                
                // App info section
                appInfoSection
            }
            .navigationTitle("Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                loadPasskeyState()
            }
            .confirmationDialog(
                "Remove Passkey",
                isPresented: $showRemoveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove Passkey", role: .destructive) {
                    Task { await removePasskey() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You will need to use your password to log in after removing the passkey.")
            }
        }
    }
}

// MARK: - Passkey Section

private extension SecuritySettingsView {
    var passkeySection: some View {
        Section {
            // Passkey toggle
            HStack(spacing: AppTheme.Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: AppConstants.Icons.passkey)
                        .font(.system(size: 16))
                        .foregroundStyle(.blue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Passkey Login")
                        .font(AppTheme.Typography.headline)
                    
                    Text(
                        isPasskeyEnabled
                            ? "Passwordless login is active"
                            : "Enable passwordless login"
                    )
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isProcessing {
                    ProgressView()
                } else {
                    Toggle("", isOn: Binding(
                        get: { isPasskeyEnabled },
                        set: { newValue in
                            Task {
                                if newValue {
                                    await registerPasskey()
                                } else {
                                    showRemoveConfirmation = true
                                }
                            }
                        }
                    ))
                    .labelsHidden()
                }
            }
            
            // Passkey info if registered
            if let info = passkeyInfo, isPasskeyEnabled {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Registered")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(info.createdDateString)
                            .font(AppTheme.Typography.subheadline)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                }
            }
            
            // Status message
            if let message = statusMessage {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(
                        systemName: isError
                            ? "exclamationmark.circle.fill"
                            : "checkmark.circle.fill"
                    )
                    .font(.system(size: 14))
                    .foregroundStyle(isError ? .red : .green)
                    
                    Text(message)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(isError ? .red : .green)
                }
            }
        } header: {
            Text("Authentication")
        } footer: {
            Text("Passkeys use Face ID or Touch ID for secure, passwordless login. Your passkey is stored securely on this device.")
        }
    }
}

// MARK: - Session Section

private extension SecuritySettingsView {
    var sessionSection: some View {
        Section {
            // Auth method
            HStack {
                Label("Login Method", systemImage: "person.badge.key")
                    .font(AppTheme.Typography.body)
                
                Spacer()
                
                Text(appViewModel.currentUser?.authMethod.rawValue.capitalized ?? "Password")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // User email
            HStack {
                Label("Account", systemImage: "envelope.fill")
                    .font(AppTheme.Typography.body)
                
                Spacer()
                
                Text(appViewModel.currentUser?.email ?? "")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Session status
            HStack {
                Label("Session", systemImage: "lock.fill")
                    .font(AppTheme.Typography.body)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    
                    Text("Active")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(.green)
                }
            }
        } header: {
            Text("Session")
        }
    }
}

// MARK: - Security Info Section

private extension SecuritySettingsView {
    var securityInfoSection: some View {
        Section {
            infoRow(
                icon: "lock.shield.fill",
                title: "Keychain Storage",
                description: "Auth tokens are stored in the iOS Keychain with hardware-level encryption.",
                color: .blue
            )
            
            infoRow(
                icon: "iphone.and.arrow.forward",
                title: "Device-Bound",
                description: "Credentials never leave this device and are excluded from backups.",
                color: .purple
            )
            
            infoRow(
                icon: "network.badge.shield.half.filled",
                title: "Secure Transport",
                description: "All API communication uses HTTPS with certificate validation.",
                color: .green
            )
        } header: {
            Text("Security Features")
        }
    }
    
    func infoRow(
        icon: String,
        title: String,
        description: String,
        color: Color
    ) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.headline)
                
                Text(description)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xxs)
    }
}

// MARK: - App Info Section

private extension SecuritySettingsView {
    var appInfoSection: some View {
        Section {
            HStack {
                Text("App Version")
                    .font(AppTheme.Typography.body)
                
                Spacer()
                
                Text("v\(AppConstants.App.version) (\(AppConstants.App.buildNumber))")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text("Environment")
                    .font(AppTheme.Typography.body)
                
                Spacer()
                
                Text("Demo")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(.orange)
            }
        } header: {
            Text("App Info")
        }
    }
}

// MARK: - Passkey Actions

private extension SecuritySettingsView {
    func loadPasskeyState() {
        isPasskeyEnabled = appViewModel.passkeyService.isRegistered
        passkeyInfo = appViewModel.passkeyService.getPasskeyInfo()
    }
    
    func registerPasskey() async {
        guard let userId = appViewModel.currentUser?.userId else { return }
        
        isProcessing = true
        statusMessage = nil
        
        do {
            let _ = try await appViewModel.passkeyService.register(
                userId: userId,
                displayName: "EcoPay Passkey"
            )
            
            isPasskeyEnabled = true
            passkeyInfo = appViewModel.passkeyService.getPasskeyInfo()
            statusMessage = "Passkey registered successfully!"
            isError = false
            
            appViewModel.analyticsService.track(.passkeyRegistered())
        } catch {
            isPasskeyEnabled = false
            statusMessage = error.localizedDescription
            isError = true
        }
        
        isProcessing = false
    }
    
    func removePasskey() async {
        isProcessing = true
        statusMessage = nil
        
        do {
            try await appViewModel.passkeyService.removePasskey()
            
            isPasskeyEnabled = false
            passkeyInfo = nil
            statusMessage = "Passkey removed."
            isError = false
            
            appViewModel.analyticsService.track(.passkeyRemoved())
        } catch {
            isPasskeyEnabled = true
            statusMessage = error.localizedDescription
            isError = true
        }
        
        isProcessing = false
    }
}

// MARK: - Preview

#Preview("Security Settings") {
    SecuritySettingsView()
        .environmentObject(AppViewModel())
}
