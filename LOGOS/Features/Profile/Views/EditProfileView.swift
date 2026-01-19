//
//  EditProfileView.swift
//  LOGOS
//
//  Vista para editar el perfil del usuario
//

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.logosBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar Section
                        avatarSection

                        // Form Section
                        formSection

                        // Save Button
                        saveButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Editar Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Éxito", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Perfil actualizado correctamente")
            }
            .onAppear {
                loadUserData()
            }
        }
    }

    // MARK: - Avatar Section
    private var avatarSection: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.primaryGradient)
                    .frame(width: 100, height: 100)

                Image(systemName: "person.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }

            Button {
                // TODO: Implementar cambio de foto
            } label: {
                Text("Cambiar foto")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.logosPrimary)
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 16) {
            // Display Name Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Nombre")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.logosTextSecondary)

                TextField("Tu nombre", text: $displayName)
                    .textFieldStyle(LogosTextFieldStyle())
                    .textContentType(.name)
                    .autocorrectionDisabled()
            }

            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Correo Electrónico")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.logosTextSecondary)

                TextField("correo@ejemplo.com", text: $email)
                    .textFieldStyle(LogosTextFieldStyle())
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .disabled(true) // Email no se puede cambiar

                Text("El correo no se puede modificar")
                    .font(.system(size: 12))
                    .foregroundColor(.logosTextTertiary)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button {
            saveProfile()
        } label: {
            if isSaving {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity)
            } else {
                Text("Guardar Cambios")
                    .frame(maxWidth: .infinity)
            }
        }
        .liquidButton(isEnabled: !isSaving && hasChanges)
        .disabled(isSaving || !hasChanges)
    }

    // MARK: - Computed Properties
    private var hasChanges: Bool {
        displayName != (authViewModel.user?.displayName ?? "") &&
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Methods
    private func loadUserData() {
        if let user = authViewModel.user {
            displayName = user.displayName ?? ""
            email = user.email ?? ""
        }
    }

    private func saveProfile() {
        guard hasChanges else { return }

        let trimmedName = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "El nombre no puede estar vacío"
            showError = true
            return
        }

        isSaving = true

        Task {
            do {
                // Actualizar en Firebase
                // TODO: Implementar actualización en Firebase/Supabase

                // Simular guardado por ahora
                try await Task.sleep(nanoseconds: 1_000_000_000)

                await MainActor.run {
                    isSaving = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Error al guardar: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Logos Text Field Style
struct LogosTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.logosTextPrimary)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.logosCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.logosPrimary.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    EditProfileView()
        .environmentObject(AuthViewModel())
}
