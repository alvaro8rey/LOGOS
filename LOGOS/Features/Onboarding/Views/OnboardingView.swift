//
//  OnboardingView.swift
//  LOGOS
//
//  Tutorial inicial para nuevos usuarios
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPage = 0
    @AppStorage("has_seen_onboarding") private var hasSeenOnboarding = false

    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "brain.head.profile",
            title: "Bienvenido a LOGOS",
            description: "Desafía tu mente con 5 tipos diferentes de puzzles lógicos diseñados para entrenar tu cerebro",
            gradient: Color.primaryGradient
        ),
        OnboardingPage(
            icon: "puzzlepiece.fill",
            title: "5 Tipos de Puzzles",
            description: "Nonogram, Simetría, Puentes, Binario y más. Cada uno con mecánicas únicas y desafíos crecientes",
            gradient: Color.accentGradient
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            title: "Sigue tu Progreso",
            description: "Estadísticas detalladas, rachas diarias y gráficos para visualizar tu evolución",
            gradient: Color.secondaryGradient
        ),
        OnboardingPage(
            icon: "trophy.fill",
            title: "Desbloquea Logros",
            description: "Completa desafíos especiales y colecciona logros mientras avanzas en dificultad",
            gradient: Color.accentGradient
        ),
        OnboardingPage(
            icon: "lightbulb.fill",
            title: "Sistema de Pistas",
            description: "¿Te quedaste atascado? Usa pistas inteligentes para recibir ayuda sin arruinar el desafío",
            gradient: Color.primaryGradient
        )
    ]

    var body: some View {
        ZStack {
            Color.logosBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Saltar") {
                        completeOnboarding()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.logosTextSecondary)
                    .padding()
                }

                // Pages
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.logosPrimary : Color.logosTextTertiary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.vertical, 20)

                // Action button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.3)) {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(currentPage < pages.count - 1 ? "Siguiente" : "Comenzar")
                            .font(.system(size: 18, weight: .bold, design: .rounded))

                        if currentPage < pages.count - 1 {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.logosPrimary, Color.logosAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .interactiveDismissDisabled()
    }

    private func completeOnboarding() {
        hasSeenOnboarding = true
        dismiss()
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let gradient: LinearGradient
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(page.gradient)
                    .frame(width: 140, height: 140)
                    .blur(radius: 30)
                    .opacity(0.6)

                Circle()
                    .fill(page.gradient)
                    .frame(width: 120, height: 120)

                Image(systemName: page.icon)
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.top, 40)

            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.logosTextPrimary)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.logosTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
