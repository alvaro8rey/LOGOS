//
//  AuthViewModel.swift
//  Logos
//
//  ViewModel para autenticación
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var isAnonymous = false
    
    // MARK: - Services
    private let authService = AuthService.shared
    private let supabaseService = SupabaseService.shared
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupBindings()
        checkAuthenticationStatus()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        authService.$isAuthenticated
            .assign(to: &$isAuthenticated)
        
        authService.$isAnonymous
            .assign(to: &$isAnonymous)
        
        authService.$currentUser
            .compactMap { $0 }
            .sink { [weak self] firebaseUser in
                Task {
                    await self?.syncUserWithSupabase(firebaseUser)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Authentication Status
    func checkAuthenticationStatus() {
        authService.checkAuthStatus()

        // NO hacer login anónimo automático - el usuario debe elegir registrarse o iniciar sesión
    }
    
    // MARK: - Sign In Anonymously
    func signInAnonymously() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signInAnonymously()
            print("✅ Usuario anónimo creado")
        } catch {
            errorMessage = "Error al crear sesión anónima"
            print("❌ Error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out (FIX CLAVE)
    func signOut() {
        isLoading = true
        errorMessage = nil
        
        do {
            try authService.signOut()
            user = nil
            isAuthenticated = false
            isAnonymous = false
            print("✅ Sesión cerrada correctamente")
        } catch {
            errorMessage = "Error al cerrar sesión"
            print("❌ Error al cerrar sesión: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Convert to Email Account
    func convertToEmailAccount(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.linkEmailPassword(email: email, password: password)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    // MARK: - Sign In with Email
    func signInWithEmail(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signInWithEmail(email: email, password: password)
            isLoading = false
            return true
        } catch {
            errorMessage = "Email o contraseña incorrectos"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Sign Up with Email
    func signUpWithEmail(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signUpWithEmail(email: email, password: password)
            isLoading = false
            return true
        } catch {
            errorMessage = "No se pudo crear la cuenta"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Delete Account
    func deleteAccount() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            if let userId = user?.id {
                try await supabaseService.deleteUser(userId: userId)
            }
            
            try await authService.deleteAccount()
            user = nil
            isLoading = false
            return true
        } catch {
            errorMessage = "Error al eliminar cuenta"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Sync with Supabase
    private func syncUserWithSupabase(_ firebaseUser: FirebaseAuth.User) async {
        // Crear usuario local siempre
        let newUser = User(
            id: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            isAnonymous: firebaseUser.isAnonymous
        )
        self.user = newUser

        // Intentar sincronizar con Supabase de forma opcional (sin bloquear si falla)
        Task.detached(priority: .background) {
            do {
                try await self.supabaseService.upsertUser(newUser)
                print("✅ Usuario sincronizado con Supabase")
            } catch {
                print("⚠️ No se pudo sincronizar con Supabase (opcional): \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Update User Data
    func updateUserData() async {
        guard let user = user else { return }
        
        do {
            var updatedUser = user
            updatedUser.lastSyncAt = Date()
            try await supabaseService.upsertUser(updatedUser)
            self.user = updatedUser
        } catch {
            print("❌ Error al actualizar usuario: \(error)")
        }
    }
}
