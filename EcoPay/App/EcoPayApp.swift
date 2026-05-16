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
import FirebaseCore

@main
struct EcoPayApp: App {
    
    @StateObject private var appViewModel: AppViewModel
    
    init() {
        FirebaseApp.configure()
        _appViewModel = StateObject(wrappedValue: AppViewModel())
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
        }
    }
}
