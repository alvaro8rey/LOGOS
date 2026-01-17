//
//  NotificationsView.swift
//  LOGOS
//
//  Vista de configuración de notificaciones
//

import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("notifications_enabled") private var notificationsEnabled = true
    @AppStorage("daily_puzzle_reminder") private var dailyPuzzleReminder = true
    @AppStorage("achievement_notifications") private var achievementNotifications = true
    @AppStorage("streak_reminder") private var streakReminder = true
    @AppStorage("new_puzzles_alert") private var newPuzzlesAlert = false
    @AppStorage("competitive_updates") private var competitiveUpdates = false
    @AppStorage("reminder_time_hour") private var reminderTimeHour = 20
    @AppStorage("sound_enabled") private var soundEnabled = true
    @AppStorage("vibration_enabled") private var vibrationEnabled = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.logosBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Master Toggle
                        masterToggleSection

                        // Push Notifications
                        if notificationsEnabled {
                            pushNotificationsSection
                        }

                        // Reminder Time
                        if notificationsEnabled && dailyPuzzleReminder {
                            reminderTimeSection
                        }

                        // Sound & Haptics
                        soundHapticsSection

                        // Info Section
                        infoSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Notificaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                    .foregroundColor(.logosPrimary)
                }
            }
        }
    }

    // MARK: - Master Toggle Section
    private var masterToggleSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    if notificationsEnabled {
                        Circle()
                            .fill(Color.primaryGradient)
                            .frame(width: 60, height: 60)
                    } else {
                        Circle()
                            .fill(Color.logosTextTertiary.opacity(0.3))
                            .frame(width: 60, height: 60)
                    }

                    Image(systemName: notificationsEnabled ? "bell.fill" : "bell.slash.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Notificaciones")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.logosTextPrimary)

                    Text(notificationsEnabled ? "Activadas" : "Desactivadas")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.logosTextSecondary)
                }

                Spacer()

                Toggle("", isOn: $notificationsEnabled)
                    .labelsHidden()
                    .tint(.logosPrimary)
            }
            .padding(20)
            .liquidCard()
        }
    }

    // MARK: - Push Notifications Section
    private var pushNotificationsSection: some View {
        VStack(spacing: 12) {
            Text("Notificaciones Push")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.logosTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 1) {
                NotificationToggleRow(
                    icon: "calendar.badge.clock",
                    title: "Recordatorio Diario",
                    subtitle: "Recibe un recordatorio para jugar",
                    isOn: $dailyPuzzleReminder,
                    color: .logosPrimary
                )

                NotificationToggleRow(
                    icon: "trophy.fill",
                    title: "Logros",
                    subtitle: "Notificaciones de nuevos logros",
                    isOn: $achievementNotifications,
                    color: .logosAccent
                )

                NotificationToggleRow(
                    icon: "flame.fill",
                    title: "Racha en Riesgo",
                    subtitle: "Aviso cuando tu racha está por terminar",
                    isOn: $streakReminder,
                    color: .logosWarning
                )

                NotificationToggleRow(
                    icon: "sparkles",
                    title: "Nuevos Puzzles",
                    subtitle: "Alerta cuando hay contenido nuevo",
                    isOn: $newPuzzlesAlert,
                    color: .logosSecondary
                )

                NotificationToggleRow(
                    icon: "chart.bar.fill",
                    title: "Actualizaciones Competitivas",
                    subtitle: "Rankings y competiciones",
                    isOn: $competitiveUpdates,
                    color: .logosPrimary
                )
            }
            .liquidGlass()
        }
    }

    // MARK: - Reminder Time Section
    private var reminderTimeSection: some View {
        VStack(spacing: 12) {
            Text("Hora del Recordatorio")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.logosTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.logosPrimary)

                    Text("Recordatorio a las:")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.logosTextPrimary)

                    Spacer()

                    Picker("", selection: $reminderTimeHour) {
                        ForEach(0..<24) { hour in
                            Text(String(format: "%02d:00", hour))
                                .tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.logosPrimary)
                }
                .padding(16)
            }
            .liquidGlass()
        }
    }

    // MARK: - Sound & Haptics Section
    private var soundHapticsSection: some View {
        VStack(spacing: 12) {
            Text("Sonido y Hápticos")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.logosTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 1) {
                NotificationToggleRow(
                    icon: "speaker.wave.2.fill",
                    title: "Sonidos",
                    subtitle: "Efectos de sonido en notificaciones",
                    isOn: $soundEnabled,
                    color: .logosSecondary
                )

                NotificationToggleRow(
                    icon: "iphone.radiowaves.left.and.right",
                    title: "Vibración",
                    subtitle: "Feedback háptico en notificaciones",
                    isOn: $vibrationEnabled,
                    color: .logosPrimary
                )
            }
            .liquidGlass()
        }
    }

    // MARK: - Info Section
    private var infoSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.logosTextSecondary)

                Text("Puedes cambiar los permisos de notificaciones en Configuración del sistema")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.logosTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.logosCard.opacity(0.5))
            )

            Button {
                openSystemSettings()
            } label: {
                HStack {
                    Image(systemName: "gearshape.fill")
                    Text("Abrir Configuración")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.logosPrimary)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.logosPrimary.opacity(0.1))
                )
            }
        }
    }

    // MARK: - Methods
    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Notification Toggle Row
struct NotificationToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 30)

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.logosTextPrimary)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.logosTextSecondary)
            }

            Spacer()

            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.logosPrimary)
        }
        .padding(16)
        .background(Color.logosCard.opacity(0.01))
    }
}

#Preview {
    NotificationsView()
}
