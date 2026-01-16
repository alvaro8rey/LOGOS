//
//  PuzzleListView.swift
//  Logos
//
//  Lista de puzzles por tipo (CORREGIDO)
//

import SwiftUI

struct PuzzleListView: View {
    let puzzleType: UserProgress.PuzzleType
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.logosBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Progress card
                    progressCard
                    
                    // Daily challenge
                    dailyChallengeCard
                    
                    // Practice modes
                    practiceSection
                }
                .padding()
            }
        }
        .navigationTitle(puzzleType.displayName)
        .navigationBarTitleDisplayMode(.large)
        .task {
            if let userId = authViewModel.user?.id {
                await viewModel.loadData(for: userId)
            }
        }
    }
    
    // MARK: - Progress Card
    private var progressCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tu Progreso")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.logosTextPrimary)
                    
                    if let progress = viewModel.getProgress(for: puzzleType) {
                        HStack(spacing: 16) {
                            statPill(icon: "checkmark.circle.fill", value: "\(progress.completedCount)", label: "Completados")
                            statPill(icon: "chart.bar.fill", value: "Nivel \(progress.currentDifficulty)", label: "Dificultad")
                        }
                    } else {
                        Text("Aún no has jugado este tipo")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.logosTextSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: puzzleType.icon)
                    .font(.system(size: 50))
                    .foregroundStyle(Color.primaryGradient)
            }
        }
        .liquidCard()
    }
    
    // MARK: - Daily Challenge
    private var dailyChallengeCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                        Text("Desafío Diario")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Color.accentGradient)
                    
                    Text("Puzzle especial del día")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.logosTextSecondary)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.logosTextSecondary)
                    Text("24h")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.logosTextSecondary)
                }
            }
            
            NavigationLink {
                if let userId = authViewModel.user?.id {
                    NonogramGameView(
                        viewModel: PuzzleViewModel(
                            puzzleType: puzzleType,
                            difficulty: 3,
                            userId: userId
                        )
                    )
                }
            } label: {
                Text("Jugar Desafío")
                    .frame(maxWidth: .infinity)
            }
            .liquidButton()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.logosAccent.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.logosAccent.opacity(0.3), lineWidth: 2)
                )
        )
    }
    
    // MARK: - Practice Section
    private var practiceSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Práctica")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.logosTextPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                practiceModeCard(
                    icon: "brain.head.profile",
                    title: "Modo Aprendizaje",
                    description: "Puzzles guiados paso a paso",
                    color: .logosPrimary
                )
                
                practiceModeCard(
                    icon: "bolt.fill",
                    title: "Contrarreloj",
                    description: "Completa puzzles rápidamente",
                    color: .logosWarning
                )
                
                practiceModeCard(
                    icon: "infinity",
                    title: "Modo Zen",
                    description: "Sin límite de tiempo ni puntuación",
                    color: .logosSecondary
                )
            }
        }
    }
    
    // MARK: - Practice Mode Card
    private func practiceModeCard(icon: String, title: String, description: String, color: Color) -> some View {
        Button {
            // TODO: Implement different game modes
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.logosTextPrimary)
                    
                    Text(description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.logosTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.logosTextTertiary)
            }
            .padding(16)
            .liquidGlass()
        }
    }
    
    // MARK: - Stat Pill
    private func statPill(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.primaryGradient)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.logosTextPrimary)
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.logosTextSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.logosPrimary.opacity(0.1))
        )
    }
}

#Preview {
    NavigationStack {
        PuzzleListView(puzzleType: .constraints)
            .environmentObject(AuthViewModel())
    }
}
