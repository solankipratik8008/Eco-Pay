//
//  EcoPayApp.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//
// EcoPayApp.swift
// EcoPayApp/App/EcoPayApp.swift
//
// Main entry point for the Eco-Pay wallet application.
// Creates AppViewModel and injects it into the SwiftUI environment.
// RootView manages navigation between splash, login, and dashboard.

import SwiftUI

@main
struct EcoPayApp: App {
    
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appViewModel)
        }
    }
}

// MARK: - Root View

struct RootView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        Group {
            if appViewModel.isInitializing {
                SplashView()
            } else if appViewModel.isAuthenticated {
                HomeDashboardView(appViewModel: appViewModel)
            } else {
                LoginView(appViewModel: appViewModel)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appViewModel.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: appViewModel.isInitializing)
        .alert(
            "Error",
            isPresented: $appViewModel.showGlobalError,
            presenting: appViewModel.globalError
        ) { _ in
            Button("OK") {
                appViewModel.clearError()
            }
        } message: { error in
            Text(error)
        }
    }
}
