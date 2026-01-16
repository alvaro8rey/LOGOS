//
//  Color+Theme.swift
//  Logos
//
//  Liquid Glass Design System (ACTUALIZADO CON NUEVOS NOMBRES)
//

import SwiftUI

extension Color {
    
    // MARK: - Primary Colors
    static let logosPrimary = Color("AppPrimary")
    static let logosSecondary = Color("AppSecondary")
    static let logosAccent = Color("AppAccent")
    
    // MARK: - Semantic Colors
    static let logosBackground = Color("AppBackground")
    static let logosSurface = Color("AppSurface")
    static let logosCard = Color("AppCard")
    
    // MARK: - Text Colors
    static let logosTextPrimary = Color("AppTextPrimary")
    static let logosTextSecondary = Color("AppTextSecondary")
    static let logosTextTertiary = Color("AppTextTertiary")
    
    // MARK: - State Colors
    static let logosSuccess = Color("AppSuccess")
    static let logosWarning = Color("AppWarning")
    static let logosError = Color("AppError")
    
    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [Color.logosPrimary, Color.logosSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [Color.logosSecondary, Color.logosAccent],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let glassGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.1),
            Color.white.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
