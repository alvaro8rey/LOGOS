//
//  ContentView.swift
//  Logos
//
//  Vista principal de la aplicación
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                mainTabView
            } else {
                AuthView()
            }
        }
    }
    
    // MARK: - Main Tab View
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            // Home
            HomeView()
                .tabItem {
                    Label("Puzzles", systemImage: "square.grid.3x3.fill")
                }
                .tag(0)
            
            // Statistics
            StatisticsView()
                .tabItem {
                    Label("Estadísticas", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            // Store
            StoreView()
                .tabItem {
                    Label("Tienda", systemImage: "cart.fill")
                }
                .tag(2)
            
            // Profile
            ProfileView()
                .tabItem {
                    Label("Perfil", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(.logosPrimary)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.logosPrimary.opacity(0.1),
                    Color.logosSecondary.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.logosPrimary)
                
                Text("Cargando...")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.logosTextSecondary)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
