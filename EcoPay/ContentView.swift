//
//  ContentView.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//
//
//  ContentView.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

//
//  ContentView.swift
//  EcoPay
//
//  Created by Pratik Solanki on 2026-05-06.
//

//
//  ContentView.swift
//  EcoPay
//

import SwiftUI
import EcoPayAuthKit

struct ContentView: View {
    
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        Group {
            if appViewModel.isInitializing {
                SplashView()
                    .task {
                        // Safety fallback: never allow splash to stay forever.
                        try? await Task.sleep(nanoseconds: 2_500_000_000)
                        
                        if appViewModel.isInitializing {
                            print("Splash fallback triggered")
                            appViewModel.authState = .unauthenticated
                            appViewModel.isInitializing = false
                        }
                    }
            } else if appViewModel.isAuthenticated {
                HomeDashboardView(appViewModel: appViewModel)
                    .environmentObject(appViewModel)
            } else {
                LoginView(appViewModel: appViewModel)
                    .environmentObject(appViewModel)
            }
        }
        .alert("EcoPay", isPresented: $appViewModel.showGlobalError) {
            Button("OK") {
                appViewModel.clearError()
            }
        } message: {
            Text(appViewModel.globalError ?? "Something went wrong.")
        }
    }
}

#Preview {
    let appViewModel = AppViewModel()
    
    ContentView()
        .environmentObject(appViewModel)
}
