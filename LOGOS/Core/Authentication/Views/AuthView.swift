//
//  AuthView.swift
//  Logos
//
//  Vista de autenticación con diseño Liquid Glass
//

import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUp = false
    @State private var showingConvertSheet = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.logosPrimary.opacity(0.1),
                    Color.logosSecondary.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if viewModel.isAuthenticated {
                // Usuario autenticado - mostrar perfil
                authenticatedUserView
            } else {
                // Sin autenticar - mostrar login/signup
                authenticationFormView
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .sheet(isPresented: $showingConvertSheet) {
            convertAccountSheet
        }
    }
    
    // MARK: - Anonymous User View
    private var anonymousUserView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 80))
                .foregroundStyle(Color.primaryGradient)
            
            VStack(spacing: 12) {
                Text("Sesión Anónima")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.logosTextPrimary)
                
                Text("Crea una cuenta para guardar tu progreso en todos tus dispositivos")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.logosTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            
            VStack(spacing: 16) {
                Button {
                    showingConvertSheet = true
                } label: {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text("Crear Cuenta con Email")
                    }
                    .frame(maxWidth: .infinity)
                }
                .liquidButton()
                
                Button {
                    // TODO: Implement Apple Sign In
                } label: {
                    HStack {
                        Image(systemName: "applelogo")
                        Text("Continuar con Apple")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.logosCard)
                    )
                    .foregroundColor(.logosTextPrimary)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                
                Button {
                    Task {
                        await viewModel.signOut()
                    }
                } label: {
                    Text("Continuar como Anónimo")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.logosTextSecondary)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
    }
    
    // MARK: - Authenticated User View
    private var authenticatedUserView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // User Icon
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.primaryGradient)
            
            VStack(spacing: 8) {
                Text(viewModel.user?.displayName ?? "Usuario")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.logosTextPrimary)
                
                if let email = viewModel.user?.email {
                    Text(email)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.logosTextSecondary)
                }
            }
            
            // Stats Card
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    statCard(
                        icon: "lightbulb.fill",
                        title: "Pistas",
                        value: "\(viewModel.user?.hintsAvailable ?? 0)"
                    )
                    
                    statCard(
                        icon: viewModel.user?.isPremium ?? false ? "crown.fill" : "crown",
                        title: "Estado",
                        value: viewModel.user?.isPremium ?? false ? "Premium" : "Gratuito"
                    )
                }
            }
            .padding(.horizontal, 30)
            
            // Actions
            VStack(spacing: 12) {
                Button {
                    viewModel.signOut()
                } label: {
                    Text("Cerrar Sesión")
                        .frame(maxWidth: .infinity)
                }
                .liquidButton()
                
                Button {
                    Task {
                        _ = await viewModel.deleteAccount()
                    }
                } label: {
                    Text("Eliminar Cuenta")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.logosError)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
    }
    
    // MARK: - Authentication Form View
    private var authenticationFormView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo / Title
            VStack(spacing: 12) {
                Text("LOGOS")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(Color.primaryGradient)
                
                Text("Puzzles Algorítmicos")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.logosTextSecondary)
            }
            
            // Form
            VStack(spacing: 16) {
                // Email Field
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.logosTextSecondary)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }
                .padding()
                .liquidGlass(cornerRadius: 16)
                .padding(.horizontal, 30)
                
                // Password Field
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.logosTextSecondary)
                    SecureField("Contraseña", text: $password)
                        .textContentType(isSignUp ? .newPassword : .password)
                }
                .padding()
                .liquidGlass(cornerRadius: 16)
                .padding(.horizontal, 30)
                
                // Confirm Password (only for sign up)
                if isSignUp {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.logosTextSecondary)
                        SecureField("Confirmar Contraseña", text: $confirmPassword)
                            .textContentType(.newPassword)
                    }
                    .padding()
                    .liquidGlass(cornerRadius: 16)
                    .padding(.horizontal, 30)
                }
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                Button {
                    Task {
                        if isSignUp {
                            guard password == confirmPassword else {
                                viewModel.errorMessage = "Las contraseñas no coinciden"
                                return
                            }
                            _ = await viewModel.signUpWithEmail(email: email, password: password)
                        } else {
                            _ = await viewModel.signInWithEmail(email: email, password: password)
                        }
                    }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(isSignUp ? "Crear Cuenta" : "Iniciar Sesión")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .liquidButton(isEnabled: !viewModel.isLoading && isFormValid)
                .disabled(!isFormValid || viewModel.isLoading)
                
                Button {
                    withAnimation {
                        isSignUp.toggle()
                        confirmPassword = ""
                    }
                } label: {
                    Text(isSignUp ? "¿Ya tienes cuenta? Inicia sesión" : "¿No tienes cuenta? Regístrate")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.logosTextSecondary)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
    }
    
    // MARK: - Convert Account Sheet
    private var convertAccountSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.primaryGradient)
                    
                    Text("Convertir a Cuenta Permanente")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.logosTextPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Tu progreso se guardará y podrás acceder desde cualquier dispositivo")
                        .font(.system(size: 15))
                        .foregroundColor(.logosTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 30)
                
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.logosTextSecondary)
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                    }
                    .padding()
                    .liquidGlass(cornerRadius: 16)
                    
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.logosTextSecondary)
                        SecureField("Contraseña", text: $password)
                            .textContentType(.newPassword)
                    }
                    .padding()
                    .liquidGlass(cornerRadius: 16)
                    
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.logosTextSecondary)
                        SecureField("Confirmar Contraseña", text: $confirmPassword)
                            .textContentType(.newPassword)
                    }
                    .padding()
                    .liquidGlass(cornerRadius: 16)
                }
                .padding(.horizontal, 30)
                
                Button {
                    Task {
                        guard password == confirmPassword else {
                            viewModel.errorMessage = "Las contraseñas no coinciden"
                            return
                        }
                        
                        let success = await viewModel.convertToEmailAccount(
                            email: email,
                            password: password
                        )
                        
                        if success {
                            showingConvertSheet = false
                            email = ""
                            password = ""
                            confirmPassword = ""
                        }
                    }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Convertir Cuenta")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .liquidButton(isEnabled: !viewModel.isLoading && isFormValid)
                .disabled(!isFormValid || viewModel.isLoading)
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") {
                        showingConvertSheet = false
                        email = ""
                        password = ""
                        confirmPassword = ""
                    }
                }
            }
        }
    }
    
    // MARK: - Stat Card
    private func statCard(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundStyle(Color.accentGradient)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.logosTextSecondary)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.logosTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .liquidCard()
    }
    
    // MARK: - Validation
    private var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 6
        
        if isSignUp {
            return emailValid && passwordValid && password == confirmPassword
        } else {
            return emailValid && passwordValid
        }
    }
}

#Preview {
    AuthView()
}
