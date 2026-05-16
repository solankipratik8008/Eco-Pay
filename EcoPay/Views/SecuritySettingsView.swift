//
//  SecuritySettingsView.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-16.
//

//
//  SecuritySettingsView.swift
//  EcoPay
//

import SwiftUI
import EcoPayAuthKit

struct SecuritySettingsView: View {
    
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                
                // MARK: - Account Section
                
                Section("Account") {
                    HStack {
                        Label("Name", systemImage: "person.fill")
                        Spacer()
                        Text(appViewModel.currentUser?.name ?? "User")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Email", systemImage: "envelope.fill")
                        Spacer()
                        Text(appViewModel.currentUser?.email ?? "")
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    
                    HStack {
                        Label("Session", systemImage: "lock.fill")
                        Spacer()
                        Text("Active")
                            .foregroundStyle(.green)
                    }
                }
                
                // MARK: - Security Section
                
                Section("Security Features") {
                    securityInfoRow(
                        icon: "key.fill",
                        title: "Firebase Authentication",
                        message: "Email/password login is handled through Firebase Auth."
                    )
                    
                    securityInfoRow(
                        icon: "creditcard.fill",
                        title: "Safe Card Storage",
                        message: "Only demo card metadata such as brand and last 4 digits is stored. Full card numbers and CVV are not saved."
                    )
                    
                    securityInfoRow(
                        icon: "externaldrive.fill.badge.checkmark",
                        title: "Firestore Data",
                        message: "Wallet balance, transfer records, and demo card metadata are stored in Firestore."
                    )
                }
                
                // MARK: - App Section
                
                Section("App") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("v\(AppConstants.App.version)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Environment")
                        Spacer()
                        Text("Demo")
                            .foregroundStyle(.orange)
                    }
                }
                
                // MARK: - Logout Section
                
                Section {
                    Button(role: .destructive) {
                        Task {
                            await appViewModel.logout()
                            dismiss()
                        }
                    } label: {
                        Label("Log Out", systemImage: AppConstants.Icons.logout)
                    }
                }
            }
            .navigationTitle("Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func securityInfoRow(
        icon: String,
        title: String,
        message: String
    ) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.headline)
                
                Text(message)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SecuritySettingsView()
        .environmentObject(AppViewModel())
}
