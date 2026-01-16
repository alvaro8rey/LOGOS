//
//  ProfileView.swift
//  Logos
//
//  Vista de perfil del usuario
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingAuthView = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.logosBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // User Header
                        userHeader
                        
                        // Account Section
                        accountSection
                        
                        // Settings Section
                        settingsSection
                        
                        // About Section
                        aboutSection
                        
                        // Danger Zone
                        if authViewModel.isAuthenticated {
                            dangerZoneSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAuthView) {
                AuthView()
            }
            .alert("Eliminar Cuenta", isPresented: $showingDeleteAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Eliminar", role: .destructive) {
                    Task {
                        _ = await authViewModel.deleteAccount()
                    }
                }
            } message: {
                Text("Esta acción no se puede deshacer. Se eliminarán todos tus datos y progreso.")
            }
        }
    }
    
    // MARK: - User Header
    private var userHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            Image(systemName: authViewModel.isAnonymous ? "person.crop.circle.badge.questionmark" : "person.crop.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.primaryGradient)
            
            // Name and Email
            VStack(spacing: 4) {
                Text(authViewModel.user?.displayName ?? (authViewModel.isAnonymous ? "Usuario Anónimo" : "Usuario"))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.logosTextPrimary)
                
                if let email = authViewModel.user?.email {
                    Text(email)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.logosTextSecondary)
                }
            }
            
            // Premium Badge
            if authViewModel.user?.isPremium ?? false {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                    Text("Miembro Premium")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.accentGradient)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.logosAccent.opacity(0.1))
                )
            }
        }
        .padding(.vertical, 20)
        .liquidCard()
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        VStack(spacing: 12) {
            Text("Cuenta")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.logosTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 1) {
                if authViewModel.isAnonymous {
                    settingRow(
                        icon: "envelope.fill",
                        title: "Crear cuenta permanente",
                        color: .logosPrimary
                    ) {
                        showingAuthView = true
                    }
                } else {
                    settingRow(
                        icon: "person.fill",
                        title: "Editar perfil",
                        color: .logosPrimary
                    ) {
                        // TODO: Implement edit profile
                    }
                    
                    settingRow(
                        icon: "lock.fill",
                        title: "Cambiar contraseña",
                        color: .logosPrimary
                    ) {
                        // TODO: Implement change password
                    }
                }
            }
            .liquidGlass()
        }
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(spacing: 12) {
            Text("Configuración")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.logosTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 1) {
                settingRow(
                    icon: "bell.fill",
                    title: "Notificaciones",
                    color: .logosAccent
                ) {
                    // TODO: Implement notifications
                }
                
                settingRow(
                    icon: "speaker.wave.2.fill",
                    title: "Sonido",
                    color: .logosSecondary
                ) {
                    // TODO: Implement sound settings
                }
                
                settingRow(
                    icon: "moon.fill",
                    title: "Tema",
                    color: .logosPrimary
                ) {
                    // TODO: Implement theme settings
                }
            }
            .liquidGlass()
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(spacing: 12) {
            Text("Acerca de")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.logosTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 1) {
                settingRow(
                    icon: "info.circle.fill",
                    title: "Versión \(AppConstants.appVersion)",
                    color: .logosTextSecondary,
                    showChevron: false
                ) { }
                
                settingRow(
                    icon: "doc.text.fill",
                    title: "Términos y condiciones",
                    color: .logosTextSecondary
                ) {
                    // TODO: Implement terms
                }
                
                settingRow(
                    icon: "hand.raised.fill",
                    title: "Política de privacidad",
                    color: .logosTextSecondary
                ) {
                    // TODO: Implement privacy policy
                }
            }
            .liquidGlass()
        }
    }
    
    // MARK: - Danger Zone
    private var dangerZoneSection: some View {
        VStack(spacing: 12) {
            VStack(spacing: 1) {
                if !authViewModel.isAnonymous {
                    settingRow(
                        icon: "rectangle.portrait.and.arrow.right",
                        title: "Cerrar sesión",
                        color: .logosWarning
                    ) {
                        authViewModel.signOut()
                    }
                }
                
                settingRow(
                    icon: "trash.fill",
                    title: "Eliminar cuenta",
                    color: .logosError
                ) {
                    showingDeleteAlert = true
                }
            }
            .liquidGlass()
        }
    }
    
    // MARK: - Setting Row
    private func settingRow(
        icon: String,
        title: String,
        color: Color,
        showChevron: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.logosTextPrimary)
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.logosTextTertiary)
                }
            }
            .padding(16)
            .background(Color.logosCard.opacity(0.01))
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
