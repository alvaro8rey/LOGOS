//
//  LogosApp.swift
//  Logos
//
//  Main App Entry Point (CORREGIDO)
//

import SwiftUI
import FirebaseCore

@main
struct LogosApp: App {
    
    // MARK: - State
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        // Intentar configurar Firebase si está disponible
        if FirebaseApp.app() == nil && fileExists(named: "GoogleService-Info") {
            FirebaseApp.configure()
            print("✅ Firebase configurado")
        } else {
            print("⚠️ Firebase no configurado - usando modo local")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .onAppear {
                    configureApp()
                }
        }
    }
    
    // MARK: - Configuration
    private func configureApp() {
        print("🚀 Logos App Iniciando...")
        
        // Verificar configuración de Supabase
        if !SupabaseService.shared.isConfigured {
            print("⚠️ Supabase no configurado - trabajando solo en local")
        }
        
        print("✅ App configurada correctamente")
    }
    
    // MARK: - Helper
    private func fileExists(named name: String) -> Bool {
        return Bundle.main.path(forResource: name, ofType: "plist") != nil
    }
}
