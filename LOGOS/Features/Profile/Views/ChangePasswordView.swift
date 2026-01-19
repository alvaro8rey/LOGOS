//
//  ChangePasswordView.swift
//  LOGOS
//
//  Vista para cambiar la contraseña del usuario
//

import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isChanging = false
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
                        // Header Icon
                        headerSection

                        // Form Section
                        formSection

                        // Password Requirements
                        requirementsSection

                        // Change Password Button
                        changePasswordButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Cambiar Contraseña")
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
            .alert("Contraseña Actualizada", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Tu contraseña ha sido cambiada correctamente")
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.logosPrimary.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "lock.rotation")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.primaryGradient)
            }

            Text("Actualiza tu contraseña")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.logosTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 16) {
            // Current Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Contraseña Actual")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.logosTextSecondary)

                SecureField("Ingresa tu contraseña actual", text: $currentPassword)
                    .textFieldStyle(LogosTextFieldStyle())
                    .textContentType(.password)
            }

            Divider()
                .padding(.vertical, 8)

            // New Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Nueva Contraseña")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.logosTextSecondary)

                SecureField("Ingresa tu nueva contraseña", text: $newPassword)
                    .textFieldStyle(LogosTextFieldStyle())
                    .textContentType(.newPassword)
            }

            // Confirm Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirmar Nueva Contraseña")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.logosTextSecondary)

                SecureField("Confirma tu nueva contraseña", text: $confirmPassword)
                    .textFieldStyle(LogosTextFieldStyle())
                    .textContentType(.newPassword)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Requirements Section
    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Requisitos de contraseña:")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.logosTextSecondary)

            VStack(alignment: .leading, spacing: 8) {
                RequirementRow(
                    text: "Mínimo 8 caracteres",
                    isMet: newPassword.count >= 8
                )
                RequirementRow(
                    text: "Las contraseñas coinciden",
                    isMet: !newPassword.isEmpty && newPassword == confirmPassword
                )
                RequirementRow(
                    text: "Diferente a la contraseña actual",
                    isMet: !newPassword.isEmpty && newPassword != currentPassword
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.logosCard.opacity(0.5))
        )
    }

    // MARK: - Change Password Button
    private var changePasswordButton: some View {
        Button {
            changePassword()
        } label: {
            if isChanging {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity)
            } else {
                Text("Cambiar Contraseña")
                    .frame(maxWidth: .infinity)
            }
        }
        .liquidButton(isEnabled: !isChanging && isFormValid)
        .disabled(isChanging || !isFormValid)
    }

    // MARK: - Computed Properties
    private var isFormValid: Bool {
        !currentPassword.isEmpty &&
        newPassword.count >= 8 &&
        newPassword == confirmPassword &&
        newPassword != currentPassword
    }

    // MARK: - Methods
    private func changePassword() {
        guard isFormValid else { return }

        isChanging = true

        Task {
            do {
                // TODO: Implementar cambio de contraseña en Firebase/Supabase
                // Por ahora simulamos el proceso
                try await Task.sleep(nanoseconds: 1_500_000_000)

                // Aquí iría la lógica real:
                // try await authViewModel.updatePassword(
                //     currentPassword: currentPassword,
                //     newPassword: newPassword
                // )

                await MainActor.run {
                    isChanging = false
                    showSuccess = true

                    // Limpiar campos
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                }
            } catch {
                await MainActor.run {
                    isChanging = false
                    errorMessage = "Error al cambiar contraseña: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Requirement Row
struct RequirementRow: View {
    let text: String
    let isMet: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(isMet ? .green : .logosTextTertiary)

            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isMet ? .logosTextPrimary : .logosTextSecondary)
        }
    }
}

#Preview {
    ChangePasswordView()
        .environmentObject(AuthViewModel())
}
