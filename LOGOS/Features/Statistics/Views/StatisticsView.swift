//
//  StatisticsView.swift
//  Logos
//
//  Vista de estadísticas del usuario - MEJORADA con gráficos y métricas
//

import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = StatisticsViewModel()
    @State private var selectedTab = 0

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
        VStack(spacing: 0) {
            // Tabs
            tabSelector

            ScrollView {
                VStack(spacing: 24) {
                    if selectedTab == 0 {
                        // Overall Stats
                        overallStatsSection

                        // Activity Graph
                        activityGraphSection

                        // Weekly Heatmap
                        weeklyHeatmapSection
                    } else if selectedTab == 1 {
                        // Progress by Type
                        progressByTypeSection

                        // Puzzle Type Comparison Chart
                        puzzleComparisonChartSection
                    } else {
                        // Achievements
                        achievementsSection
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton(title: "General", index: 0, icon: "chart.bar.fill")
            tabButton(title: "Puzzles", index: 1, icon: "puzzlepiece.fill")
            tabButton(title: "Logros", index: 2, icon: "trophy.fill")
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.logosCard.opacity(0.5))
    }

    private func tabButton(title: String, index: Int, icon: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundColor(selectedTab == index ? .logosPrimary : .logosTextSecondary)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedTab == index ? Color.logosPrimary.opacity(0.1) : Color.clear)
            )
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

    // MARK: - Activity Graph Section
    private var activityGraphSection: some View {
        VStack(spacing: 16) {
            Text("Actividad de los Últimos 7 Días")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.logosTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(viewModel.last7DaysActivity, id: \.date) { data in
                            BarMark(
                                x: .value("Día", data.dayName),
                                y: .value("Puzzles", data.count)
                            )
                            .foregroundStyle(Color.primaryGradient)
                            .cornerRadius(6)
                        }
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine()
                            AxisValueLabel()
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel()
                        }
                    }
                } else {
                    // Fallback para iOS 15
                    simplifiedActivityView
                }
            }
            .padding(20)
            .liquidGlass()
        }
    }

    // MARK: - Simplified Activity View (iOS 15 fallback)
    private var simplifiedActivityView: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.last7DaysActivity, id: \.date) { data in
                HStack {
                    Text(data.dayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.logosTextSecondary)
                        .frame(width: 40, alignment: .leading)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.logosTextTertiary.opacity(0.2))
                                .frame(height: 20)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.primaryGradient)
                                .frame(
                                    width: geometry.size.width * CGFloat(min(data.count, 10)) / 10,
                                    height: 20
                                )
                        }
                    }
                    .frame(height: 20)

                    Text("\(data.count)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.logosPrimary)
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Weekly Heatmap Section
    private var weeklyHeatmapSection: some View {
        VStack(spacing: 16) {
            Text("Mapa de Calor Semanal")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.logosTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                // Headers
                HStack(spacing: 4) {
                    Text("")
                        .frame(width: 50)
                    ForEach(["L", "M", "X", "J", "V", "S", "D"], id: \.self) { day in
                        Text(day)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.logosTextSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                // Heatmap grid
                ForEach(0..<4, id: \.self) { week in
                    HStack(spacing: 4) {
                        Text("S\(week + 1)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.logosTextSecondary)
                            .frame(width: 50)

                        ForEach(0..<7, id: \.self) { day in
                            let index = week * 7 + day
                            let activity = index < viewModel.heatmapData.count ? viewModel.heatmapData[index] : 0

                            RoundedRectangle(cornerRadius: 4)
                                .fill(heatmapColor(for: activity))
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }

                // Legend
                HStack(spacing: 8) {
                    Text("Menos")
                        .font(.system(size: 11))
                        .foregroundColor(.logosTextTertiary)

                    ForEach(0..<5, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(heatmapColor(for: level))
                            .frame(width: 12, height: 12)
                    }

                    Text("Más")
                        .font(.system(size: 11))
                        .foregroundColor(.logosTextTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 8)
            }
            .padding(20)
            .liquidGlass()
        }
    }

    // MARK: - Puzzle Comparison Chart Section
    private var puzzleComparisonChartSection: some View {
        VStack(spacing: 16) {
            Text("Comparación por Tipo de Puzzle")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.logosTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(UserProgress.PuzzleType.allCases, id: \.self) { type in
                            let stats = viewModel.progressByType[type]
                            let count = stats?.completed ?? 0

                            BarMark(
                                x: .value("Tipo", type.displayName),
                                y: .value("Completados", count)
                            )
                            .foregroundStyle(by: .value("Tipo", type.displayName))
                            .cornerRadius(8)
                        }
                    }
                    .frame(height: 250)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel()
                                .font(.system(size: 11))
                        }
                    }
                } else {
                    // Fallback para iOS 15
                    simplifiedComparisonView
                }

                // Stats summary
                HStack(spacing: 12) {
                    ForEach(UserProgress.PuzzleType.allCases.prefix(3), id: \.self) { type in
                        let stats = viewModel.progressByType[type]
                        let count = stats?.completed ?? 0

                        VStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.system(size: 16))
                                .foregroundColor(.logosPrimary)

                            Text("\(count)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.logosTextPrimary)

                            Text(type.rawValue.capitalized)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.logosTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.logosCard.opacity(0.5))
                        )
                    }
                }
            }
            .padding(20)
            .liquidGlass()
        }
    }

    // MARK: - Simplified Comparison View (iOS 15 fallback)
    private var simplifiedComparisonView: some View {
        VStack(spacing: 12) {
            ForEach(UserProgress.PuzzleType.allCases, id: \.self) { type in
                let stats = viewModel.progressByType[type]
                let count = stats?.completed ?? 0
                let maxCount = viewModel.progressByType.values.map { $0.completed }.max() ?? 1

                HStack {
                    Image(systemName: type.icon)
                        .font(.system(size: 16))
                        .foregroundColor(.logosPrimary)
                        .frame(width: 30)

                    Text(type.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.logosTextSecondary)
                        .frame(width: 100, alignment: .leading)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.logosTextTertiary.opacity(0.2))
                                .frame(height: 24)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.primaryGradient)
                                .frame(
                                    width: geometry.size.width * CGFloat(count) / CGFloat(max(maxCount, 1)),
                                    height: 24
                                )
                        }
                    }
                    .frame(height: 24)

                    Text("\(count)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.logosPrimary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Helper Methods
    private func heatmapColor(for activity: Int) -> Color {
        switch activity {
        case 0: return Color.logosTextTertiary.opacity(0.1)
        case 1: return Color.logosPrimary.opacity(0.3)
        case 2: return Color.logosPrimary.opacity(0.5)
        case 3: return Color.logosPrimary.opacity(0.7)
        default: return Color.logosPrimary
        }
    }
}

#Preview {
    StatisticsView()
        .environmentObject(AuthViewModel())
}
