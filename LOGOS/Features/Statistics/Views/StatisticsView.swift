//
//  StatisticsView.swift
//  Logos
//
//  Vista de estadísticas del usuario (ACTUALIZADA)
//

import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = StatisticsViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.logosBackground
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else {
                    contentView
                }
            }
            .navigationTitle("Estadísticas")
            .navigationBarTitleDisplayMode(.large)
            .task {
                if let userId = authViewModel.user?.id {
                    await viewModel.loadData(for: userId)
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.logosPrimary)
            
            Text("Cargando estadísticas...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.logosTextSecondary)
        }
    }
    
    // MARK: - Content View
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Overall Stats
                overallStatsSection
                
                // Progress by Type
                progressByTypeSection
                
                // Achievements (placeholder)
                achievementsSection
            }
            .padding()
        }
    }
    
    // MARK: - Overall Stats
    private var overallStatsSection: some View {
        VStack(spacing: 16) {
            Text("Estadísticas Globales")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.logosTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                statCard(
                    icon: "puzzlepiece.fill",
                    title: "Total Completados",
                    value: "\(viewModel.totalCompleted)",
                    color: .logosPrimary
                )
                
                statCard(
                    icon: "flame.fill",
                    title: "Racha Actual",
                    value: "\(viewModel.currentStreak) días",
                    color: .logosAccent
                )
                
                statCard(
                    icon: "clock.fill",
                    title: "Tiempo Total",
                    value: viewModel.formatTime(viewModel.totalTimeSpent),
                    color: .logosSecondary
                )
                
                statCard(
                    icon: "lightbulb.fill",
                    title: "Pistas Usadas",
                    value: "\(viewModel.totalHintsUsed)",
                    color: .logosWarning
                )
            }
            
            // Additional stats
            HStack(spacing: 12) {
                statCard(
                    icon: "gauge.with.dots.needle.67percent",
                    title: "Tiempo Promedio",
                    value: viewModel.formatTime(viewModel.averageTimePerPuzzle),
                    color: .logosPrimary
                )
                
                statCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Tasa de Éxito",
                    value: String(format: "%.0f%%", viewModel.completionRate * 100),
                    color: .logosSuccess
                )
            }
        }
    }
    
    // MARK: - Progress by Type
    private var progressByTypeSection: some View {
        VStack(spacing: 16) {
            Text("Progreso por Tipo")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.logosTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(UserProgress.PuzzleType.allCases, id: \.self) { type in
                    progressRow(for: type)
                }
            }
        }
    }
    
    // MARK: - Achievements
    private var achievementsSection: some View {
        VStack(spacing: 16) {
            Text("Logros")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.logosTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                achievementCard(
                    icon: "star.fill",
                    title: "Primer Puzzle",
                    description: "Completa tu primer puzzle",
                    isUnlocked: viewModel.totalCompleted > 0
                )
                
                achievementCard(
                    icon: "flame.fill",
                    title: "Racha de 7 días",
                    description: "Juega 7 días consecutivos",
                    isUnlocked: viewModel.longestStreak >= 7
                )
                
                achievementCard(
                    icon: "crown.fill",
                    title: "Maestro",
                    description: "Completa 100 puzzles",
                    isUnlocked: viewModel.totalCompleted >= 100
                )
                
                achievementCard(
                    icon: "bolt.fill",
                    title: "Velocista",
                    description: "Completa un puzzle en menos de 1 minuto",
                    isUnlocked: viewModel.puzzleHistory.contains { $0.timeSpent < 60 && $0.isSolved }
                )
                
                achievementCard(
                    icon: "brain.fill",
                    title: "Sin Ayuda",
                    description: "Completa 10 puzzles sin usar pistas",
                    isUnlocked: viewModel.puzzleHistory.filter { $0.isSolved && $0.hintsUsed == 0 }.count >= 10
                )
            }
        }
    }
    
    // MARK: - Stat Card
    private func statCard(
        icon: String,
        title: String,
        value: String,
        color: Color
    ) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.logosTextPrimary)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.logosTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .liquidGlass()
    }
    
    // MARK: - Progress Row
    private func progressRow(for type: UserProgress.PuzzleType) -> some View {
        let stats = viewModel.progressByType[type]
        let percentage = viewModel.getCompletionPercentage(for: type)
        
        return HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.primaryGradient)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(type.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.logosTextPrimary)
                
                if let stats = stats {
                    HStack(spacing: 8) {
                        Text("\(stats.completed) completados")
                        Text("•")
                        Text("Nivel \(stats.currentDifficulty)")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.logosTextSecondary)
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.logosTextTertiary.opacity(0.2))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.primaryGradient)
                                .frame(width: geometry.size.width * CGFloat(percentage) / 100, height: 6)
                        }
                    }
                    .frame(height: 6)
                } else {
                    Text("No iniciado")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.logosTextSecondary)
                }
            }
            
            Spacer()
            
            Text("\(percentage)%")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.logosPrimary)
        }
        .padding(16)
        .liquidGlass()
    }
    
    // MARK: - Achievement Card
    private func achievementCard(
        icon: String,
        title: String,
        description: String,
        isUnlocked: Bool
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(isUnlocked ? .logosAccent : .logosTextTertiary)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(isUnlocked ? Color.logosAccent.opacity(0.1) : Color.gray.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.logosTextPrimary)
                
                Text(description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.logosTextSecondary)
            }
            
            Spacer()
            
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.logosSuccess)
            }
        }
        .padding(16)
        .liquidGlass()
        .opacity(isUnlocked ? 1 : 0.6)
    }
}

#Preview {
    StatisticsView()
        .environmentObject(AuthViewModel())
}
