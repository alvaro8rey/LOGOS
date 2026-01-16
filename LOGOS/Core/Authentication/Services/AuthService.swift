//
//  AuthService.swift
//  Logos
//
//  Servicio de autenticación con Firebase
//

import Foundation
import FirebaseAuth
import Combine

enum AuthError: LocalizedError {
    case notAuthenticated
    case linkingFailed
    case invalidCredential
    case networkError
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "No hay sesión activa"
        case .linkingFailed:
            return "No se pudo vincular la cuenta"
        case .invalidCredential:
            return "Credenciales inválidas"
        case .networkError:
            return "Error de conexión"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

@MainActor
class AuthService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentUser: FirebaseAuth.User?
    @Published var isAuthenticated = false
    @Published var isAnonymous = false
    
    // MARK: - Private Properties
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton
    static let shared = AuthService()
    
    private init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Auth State Listener
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                self?.isAnonymous = user?.isAnonymous ?? false
                
                if let user = user {
                    print("✅ Usuario autenticado: \(user.uid)")
                    print("   Anónimo: \(user.isAnonymous)")
                }
            }
        }
    }
    
    // MARK: - Sign In Anonymously
    func signInAnonymously() async throws {
        do {
            let result = try await Auth.auth().signInAnonymously()
            print("✅ Usuario anónimo creado: \(result.user.uid)")
        } catch {
            print("❌ Error al crear usuario anónimo: \(error)")
            throw AuthError.unknown(error)
        }
    }
    
    // MARK: - Convert Anonymous to Email
    func linkEmailPassword(email: String, password: String) async throws {
        guard let currentUser = currentUser, currentUser.isAnonymous else {
            throw AuthError.notAuthenticated
        }
        
        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            let result = try await currentUser.link(with: credential)
            print("✅ Cuenta anónima convertida a email: \(result.user.email ?? "")")
        } catch let error as NSError {
            if error.code == AuthErrorCode.credentialAlreadyInUse.rawValue {
                // El email ya existe, hacer merge
                try await mergeAnonymousAccount(withEmail: email, password: password)
            } else {
                print("❌ Error al vincular email: \(error)")
                throw AuthError.linkingFailed
            }
        }
    }
    
    // MARK: - Merge Anonymous Account
    private func mergeAnonymousAccount(withEmail email: String, password: String) async throws {
        guard let anonymousUser = currentUser else {
            throw AuthError.notAuthenticated
        }
        
        // Aquí deberías guardar los datos del usuario anónimo antes de eliminarlo
        // y luego restaurarlos en la cuenta con email
        // Esto lo implementaremos en el SyncService
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await Auth.auth().signIn(with: credential)
        
        // Eliminar usuario anónimo
        try await anonymousUser.delete()
        
        print("✅ Cuentas fusionadas correctamente")
    }
    
    // MARK: - Sign In with Email
    func signInWithEmail(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            print("✅ Inicio de sesión exitoso: \(result.user.email ?? "")")
        } catch {
            print("❌ Error al iniciar sesión: \(error)")
            throw AuthError.invalidCredential
        }
    }
    
    // MARK: - Sign Up with Email
    func signUpWithEmail(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            print("✅ Usuario creado: \(result.user.email ?? "")")
        } catch {
            print("❌ Error al crear usuario: \(error)")
            throw AuthError.unknown(error)
        }
    }
    
    // MARK: - Sign Out
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            print("✅ Sesión cerrada")
        } catch {
            print("❌ Error al cerrar sesión: \(error)")
            throw AuthError.unknown(error)
        }
    }
    
    // MARK: - Delete Account
    func deleteAccount() async throws {
        guard let user = currentUser else {
            throw AuthError.notAuthenticated
        }
        
        do {
            try await user.delete()
            print("✅ Cuenta eliminada")
        } catch {
            print("❌ Error al eliminar cuenta: \(error)")
            throw AuthError.unknown(error)
        }
    }
    
    // MARK: - Check Authentication
    func checkAuthStatus() {
        if let user = Auth.auth().currentUser {
            Task { @MainActor in
                self.currentUser = user
                self.isAuthenticated = true
                self.isAnonymous = user.isAnonymous
            }
        }
    }
}
