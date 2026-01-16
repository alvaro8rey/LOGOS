//
//  View+LiquidGlass.swift
//  Logos
//
//  Liquid Glass Design Modifiers (CORREGIDO)
//

import SwiftUI

extension View {
    
    /// Aplica efecto de cristal líquido (glassmorphism)
    func liquidGlass(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.logosCard)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
    }
    
    /// Botón con estilo liquid glass
    func liquidButton(isEnabled: Bool = true) -> some View {
        self
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isEnabled ?
                          LinearGradient(
                            colors: [Color.logosPrimary, Color.logosSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ) :
                          LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                    )
            )
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .shadow(color: Color.logosPrimary.opacity(isEnabled ? 0.4 : 0), radius: 15, x: 0, y: 8)
    }
    
    /// Card con efecto de profundidad
    func liquidCard(padding: CGFloat = 20) -> some View {
        self
            .padding(padding)
            .liquidGlass()
    }
    
    /// Efecto shimmer para loading
    func shimmer(isLoading: Bool) -> some View {
        self.overlay(
            isLoading ?
                ShimmerView()
                    .mask(self)
            : nil
        )
    }
}

// MARK: - Shimmer Effect
struct ShimmerView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.white.opacity(0.3),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 2)
            .offset(x: -geometry.size.width + (phase * geometry.size.width * 2))
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
        }
    }
}
