//
//  StoreView.swift
//  Logos
//
//  Vista de la tienda (placeholder para FASE 4)
//

import SwiftUI

struct StoreView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.logosBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Premium Banner
                        premiumBanner
                        
                        // Hint Packs
                        hintPacksSection
                        
                        // Subscriptions
                        subscriptionsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Tienda")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Premium Banner
    private var premiumBanner: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.accentGradient)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Desbloquea Todo")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.logosTextPrimary)
                
                Text("Pistas ilimitadas y acceso a puzzles premium")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.logosTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button {
                // TODO: Implement subscription
            } label: {
                Text("Suscribirse")
                    .frame(maxWidth: .infinity)
            }
            .liquidButton(isEnabled: !(authViewModel.user?.isPremium ?? false))
            .disabled(authViewModel.user?.isPremium ?? false)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.primaryGradient)
                .shadow(color: Color.logosPrimary.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .foregroundColor(.white)
    }
    
    // MARK: - Hint Packs
    private var hintPacksSection: some View {
        VStack(spacing: 16) {
            Text("Paquetes de Pistas")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.logosTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(0..<4) { index in
                    hintPackCard(
                        hints: AppConstants.Hints.hintPackSizes[index],
                        price: AppConstants.Hints.hintPrices[index]
                    )
                }
            }
        }
    }
    
    // MARK: - Subscriptions
    private var subscriptionsSection: some View {
        VStack(spacing: 16) {
            Text("Suscripciones")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.logosTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                subscriptionCard(
                    title: "Mensual",
                    price: "$4.99",
                    period: "mes",
                    features: ["Pistas ilimitadas", "Sin anuncios", "Puzzles premium"]
                )
                
                subscriptionCard(
                    title: "Anual",
                    price: "$39.99",
                    period: "año",
                    features: ["Pistas ilimitadas", "Sin anuncios", "Puzzles premium", "Ahorra 33%"],
                    isRecommended: true
                )
            }
        }
    }
    
    // MARK: - Hint Pack Card
    private func hintPackCard(hints: Int, price: Double) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color.accentGradient)
            
            Text("\(hints) Pistas")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.logosTextPrimary)
            
            Text("$\(String(format: "%.2f", price))")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.logosTextSecondary)
            
            Button {
                // TODO: Implement purchase
            } label: {
                Text("Comprar")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.logosPrimary)
                    )
            }
        }
        .padding(20)
        .liquidGlass()
    }
    
    // MARK: - Subscription Card
    private func subscriptionCard(
        title: String,
        price: String,
        period: String,
        features: [String],
        isRecommended: Bool = false
    ) -> some View {
        VStack(spacing: 16) {
            if isRecommended {
                HStack {
                    Spacer()
                    Text("RECOMENDADO")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.logosAccent)
                        )
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.logosTextPrimary)
                    
                    HStack(spacing: 4) {
                        Text(price)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(Color.primaryGradient)
                        
                        Text("/ \(period)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.logosTextSecondary)
                    }
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.logosSuccess)
                        
                        Text(feature)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.logosTextPrimary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button {
                // TODO: Implement subscription
            } label: {
                Text("Suscribirse")
                    .frame(maxWidth: .infinity)
            }
            .liquidButton()
        }
        .padding(20)
        .liquidGlass()
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isRecommended ? Color.logosAccent : Color.clear,
                    lineWidth: 2
                )
        )
    }
}

#Preview {
    StoreView()
        .environmentObject(AuthViewModel())
}
