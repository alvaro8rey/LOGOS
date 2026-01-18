//
//  HomeView.swift
//  Logos
//
//  Vista principal con navegación a puzzles (ACTUALIZADA)
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.logosBackground
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    loadingView
                } else {
                    contentView
                }
            }
            .navigationTitle("LOGOS")
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
            
            Text("Cargando puzzles...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.logosTextSecondary)
        }
    }
    
    // MARK: - Content View
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerView
                
                // Puzzle Types Grid
                puzzleTypesGrid
                
                // Quick Stats
                quickStatsCard
                
                // Recent Activity
                if !viewModel.recentHistory.isEmpty {
                    recentActivitySection
                }
            }
            .padding()
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bienvenido")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.logosTextSecondary)
                    
                    Text(authViewModel.user?.displayName ?? "Jugador")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.logosTextPrimary)
                }
                
                Spacer()
                
                // Hints Badge
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 16))
                    Text("\(authViewModel.user?.hintsAvailable ?? 0)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Color.accentGradient)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .liquidGlass(cornerRadius: 20)
            }
        }
    }
    
    // MARK: - Puzzle Types Grid
    private var puzzleTypesGrid: some View {
        VStack(spacing: 16) {
            ForEach(UserProgress.PuzzleType.allCases, id: \.self) { type in
                NavigationLink {
                    DifficultySelectionView(
                        puzzleType: type,
                        currentDifficulty: viewModel.getProgress(for: type)?.currentDifficulty ?? 1
                    )
                } label: {
                    PuzzleTypeCardWithProgress(
                        puzzleType: type,
                        progress: viewModel.getProgress(for: type)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Quick Stats Card
    private var quickStatsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Tu Progreso")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.logosTextPrimary)
                
                Spacer()
                
                if authViewModel.user?.isPremium ?? false {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                        Text("Premium")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accentGradient)
                }
            }
            
            HStack(spacing: 12) {
                statItem(
                    icon: "checkmark.circle.fill",
                    title: "Completados",
                    value: "\(viewModel.totalCompleted)"
                )
                
                Divider()
                    .frame(height: 40)
                
                statItem(
                    icon: "clock.fill",
                    title: "Tiempo",
                    value: formatTime(viewModel.totalTimeSpent)
                )
                
                Divider()
                    .frame(height: 40)
                
                statItem(
                    icon: "star.fill",
                    title: "Tipos",
                    value: "\(viewModel.userProgress.count)"
                )
            }
        }
        .liquidCard()
    }
    
    // MARK: - Recent Activity
    private var recentActivitySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Actividad Reciente")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.logosTextPrimary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.recentHistory.prefix(5)) { history in
                    recentActivityRow(history: history)
                }
            }
        }
    }
    
    // MARK: - Recent Activity Row
    private func recentActivityRow(history: PuzzleHistory) -> some View {
        HStack(spacing: 12) {
            Image(systemName: history.puzzleType.icon)
                .font(.system(size: 20))
                .foregroundStyle(
                    history.isSolved
                    ? AnyShapeStyle(Color.primaryGradient)
                    : AnyShapeStyle(Color.logosTextTertiary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(history.puzzleType.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.logosTextPrimary)
                
                HStack(spacing: 8) {
                    Text("Nivel \(history.difficulty)")
                    Text("•")
                    Text(formatTime(history.timeSpent))
                    if history.hintsUsed > 0 {
                        Text("•")
                        HStack(spacing: 2) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 10))
                            Text("\(history.hintsUsed)")
                        }
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.logosTextSecondary)
            }
            
            Spacer()
            
            if history.isSolved {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.logosSuccess)
            }
        }
        .padding(16)
        .liquidGlass()
    }
    
    // MARK: - Stat Item
    private func statItem(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.primaryGradient)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.logosTextPrimary)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.logosTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Format Time
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "<1m"
        }
    }
}

// MARK: - Difficulty Selection View
struct DifficultySelectionView: View {
    let puzzleType: UserProgress.PuzzleType
    let currentDifficulty: Int
    @EnvironmentObject var authViewModel: AuthViewModel

    private let difficulties = [
        (level: 1, name: "Fácil", description: "Cuadrícula 5x5", icon: "1.circle.fill", color: Color.logosSuccess),
        (level: 2, name: "Medio", description: "Cuadrícula 7x7", icon: "2.circle.fill", color: Color.logosPrimary),
        (level: 3, name: "Difícil", description: "Cuadrícula 10x10", icon: "3.circle.fill", color: Color.logosWarning),
        (level: 4, name: "Experto", description: "Cuadrícula 12x12", icon: "4.circle.fill", color: Color.logosError),
        (level: 5, name: "Maestro", description: "Cuadrícula 15x15", icon: "5.circle.fill", color: Color.logosAccent)
    ]

    var body: some View {
        ZStack {
            Color.logosBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: puzzleType.icon)
                            .font(.system(size: 60))
                            .foregroundStyle(Color.primaryGradient)

                        Text(puzzleType.displayName)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.logosTextPrimary)

                        Text("Selecciona la dificultad")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.logosTextSecondary)
                    }
                    .padding(.top, 20)

                    // Difficulty cards
                    VStack(spacing: 16) {
                        ForEach(difficulties, id: \.level) { difficulty in
                            difficultyCard(difficulty: difficulty)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Dificultad")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Difficulty Card
    private func difficultyCard(difficulty: (level: Int, name: String, description: String, icon: String, color: Color)) -> some View {
        NavigationLink {
            if let userId = authViewModel.user?.id {
                PuzzleGameRouter(
                    puzzleType: puzzleType,
                    difficulty: difficulty.level,
                    userId: userId
                )
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: difficulty.icon)
                    .font(.system(size: 32))
                    .foregroundColor(difficulty.color)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(difficulty.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.logosTextPrimary)
                    
                    Text(difficulty.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.logosTextSecondary)
                }
                
                Spacer()
                
                // Current difficulty indicator
                if difficulty.level == currentDifficulty {
                    VStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.logosAccent)
                        Text("Actual")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.logosAccent)
                    }
                } else if difficulty.level < currentDifficulty {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.logosSuccess)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.logosTextTertiary)
                        .opacity(difficulty.level > currentDifficulty + 1 ? 1 : 0)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.logosTextTertiary)
            }
            .padding(20)
            .liquidGlass()
        }
        .disabled(difficulty.level > currentDifficulty + 1) // Solo puede jugar nivel actual +1
    }
}

// MARK: - Puzzle Type Card With Progress
struct PuzzleTypeCardWithProgress: View {
    let puzzleType: UserProgress.PuzzleType
    let progress: UserProgress?
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: puzzleType.icon)
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.logosPrimary, Color.logosSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.logosPrimary.opacity(0.1))
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(puzzleType.displayName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.logosTextPrimary)
                
                if let progress = progress {
                    Text("\(progress.completedCount) completados · Nivel \(progress.currentDifficulty)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.logosTextSecondary)
                } else {
                    Text("No iniciado")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.logosTextSecondary)
                }
            }
            
            Spacer()
            
            // Progress indicator
            if let progress = progress, progress.completedCount > 0 {
                VStack(spacing: 4) {
                    Text("\(progress.completedCount)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.logosSecondary, Color.logosAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.logosTextTertiary)
                }
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.logosTextTertiary)
            }
        }
        .padding(20)
        .liquidGlass()
    }
}

// MARK: - Puzzle Game Router
struct PuzzleGameRouter: View {
    let puzzleType: UserProgress.PuzzleType
    let difficulty: Int
    let userId: String

    var body: some View {
        switch puzzleType {
        case .constraints:
            // Nonogram puzzle - IMPLEMENTADO
            NonogramGameView(
                viewModel: PuzzleViewModel(
                    puzzleType: puzzleType,
                    difficulty: difficulty,
                    userId: userId
                )
            )
        case .graphs:
            // Bridges puzzle - IMPLEMENTADO
            BridgesGameView(
                viewModel: BridgesPuzzleViewModel(
                    puzzleType: puzzleType,
                    difficulty: difficulty,
                    userId: userId
                )
            )
        case .binaryStates:
            // Binary puzzle - IMPLEMENTADO
            BinaryGameView(
                viewModel: BinaryPuzzleViewModel(
                    puzzleType: puzzleType,
                    difficulty: difficulty,
                    userId: userId
                )
            )
        case .symmetry:
            // Symmetry puzzle - IMPLEMENTADO
            SymmetryGameView(
                viewModel: SymmetryPuzzleViewModel(
                    puzzleType: puzzleType,
                    difficulty: difficulty,
                    userId: userId
                )
            )
        case .mathematical:
            // Math puzzle - IMPLEMENTADO
            MathGameView(
                viewModel: MathPuzzleViewModel(
                    puzzleType: puzzleType,
                    difficulty: difficulty,
                    userId: userId
                )
            )
        case .logic:
            // Sudoku 9x9 - IMPLEMENTADO (EXTREMADAMENTE DIFÍCIL)
            SudokuGameView(
                viewModel: SudokuPuzzleViewModel(
                    puzzleType: puzzleType,
                    difficulty: difficulty,
                    userId: userId
                )
            )
        }
    }
}

// MARK: - Coming Soon Puzzle View
struct ComingSoonPuzzleView: View {
    let puzzleType: UserProgress.PuzzleType
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.logosBackground
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Icon
                Image(systemName: puzzleType.icon)
                    .font(.system(size: 80))
                    .foregroundStyle(Color.primaryGradient)

                // Title
                VStack(spacing: 12) {
                    Text(puzzleType.displayName)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.logosTextPrimary)

                    Text("Próximamente")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.logosAccent)
                }

                // Description
                Text("Este tipo de puzzle está en desarrollo.\nPronto estará disponible.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.logosTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Back button
                Button {
                    dismiss()
                } label: {
                    Text("Volver")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.logosPrimary, Color.logosSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}
