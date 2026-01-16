//
//  StatisticsViewModel.swift
//  LOGOS
//
//  Created by alvaro on 16/1/26.
//


//
//  StatisticsViewModel.swift
//  Logos
//
//  ViewModel para estadísticas
//

import Foundation
import Combine

@MainActor
class StatisticsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var userProgress: [UserProgress] = []
    @Published var puzzleHistory: [PuzzleHistory] = []
    @Published var isLoading = false
    
    // Estadísticas calculadas
    @Published var totalCompleted = 0
    @Published var totalTimeSpent: TimeInterval = 0
    @Published var totalHintsUsed = 0
    @Published var averageTimePerPuzzle: TimeInterval = 0
    @Published var currentStreak = 0
    @Published var longestStreak = 0
    @Published var completionRate: Double = 0
    
    // Por tipo de puzzle
    @Published var progressByType: [UserProgress.PuzzleType: ProgressStats] = [:]
    
    // MARK: - Services
    private let syncService = SyncService.shared
    private let supabaseService = SupabaseService.shared
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String?
    
    // MARK: - Nested Types
    struct ProgressStats {
        var completed: Int
        var totalTime: TimeInterval
        var hintsUsed: Int
        var averageTime: TimeInterval
        var bestTime: TimeInterval?
        var currentDifficulty: Int
    }
    
    // MARK: - Load Data
    func loadData(for userId: String) async {
        self.currentUserId = userId
        isLoading = true
        
        // Cargar progreso
        userProgress = syncService.getAllLocalProgress(userId: userId)
        
        // Cargar historial completo
        await loadHistory(userId: userId)
        
        // Calcular estadísticas
        calculateAllStats()
        
        isLoading = false
    }
    
    // MARK: - Load History
    private func loadHistory(userId: String) async {
        do {
            // Intentar cargar desde Supabase
            puzzleHistory = try await supabaseService.fetchPuzzleHistory(
                userId: userId,
                limit: 1000 // Cargar más para estadísticas precisas
            )
            print("✅ Historial completo cargado: \(puzzleHistory.count) puzzles")
        } catch {
            print("❌ Error cargando historial: \(error)")
            // Cargar desde local como fallback
            loadLocalHistory(userId: userId)
        }
    }
    
    // MARK: - Load Local History
    private func loadLocalHistory(userId: String) {
        let context = PersistenceController.shared.viewContext
        let entities = PuzzleHistoryEntity.fetchHistory(userId: userId, in: context)
        puzzleHistory = entities.compactMap { $0.toDomainModel() }
        print("✅ Historial local cargado: \(puzzleHistory.count) puzzles")
    }
    
    // MARK: - Calculate All Stats
    private func calculateAllStats() {
        calculateGlobalStats()
        calculateProgressByType()
        calculateStreaks()
    }
    
    // MARK: - Calculate Global Stats
    private func calculateGlobalStats() {
        totalCompleted = userProgress.reduce(0) { $0 + $1.completedCount }
        
        let solvedPuzzles = puzzleHistory.filter { $0.isSolved }
        
        totalTimeSpent = solvedPuzzles.reduce(0) { $0 + $1.timeSpent }
        totalHintsUsed = solvedPuzzles.reduce(0) { $0 + $1.hintsUsed }
        
        if !solvedPuzzles.isEmpty {
            averageTimePerPuzzle = totalTimeSpent / Double(solvedPuzzles.count)
            completionRate = Double(solvedPuzzles.count) / Double(puzzleHistory.count)
        }
    }
    
    // MARK: - Calculate Progress by Type
    private func calculateProgressByType() {
        progressByType.removeAll()
        
        for type in UserProgress.PuzzleType.allCases {
            let progress = userProgress.first(where: { $0.puzzleType == type })
            let typeHistory = puzzleHistory.filter { $0.puzzleType == type && $0.isSolved }
            
            let totalTime = typeHistory.reduce(0) { $0 + $1.timeSpent }
            let hintsUsed = typeHistory.reduce(0) { $0 + $1.hintsUsed }
            let avgTime = typeHistory.isEmpty ? 0 : totalTime / Double(typeHistory.count)
            
            progressByType[type] = ProgressStats(
                completed: progress?.completedCount ?? 0,
                totalTime: totalTime,
                hintsUsed: hintsUsed,
                averageTime: avgTime,
                bestTime: progress?.bestTime,
                currentDifficulty: progress?.currentDifficulty ?? 1
            )
        }
    }
    
    // MARK: - Calculate Streaks
    private func calculateStreaks() {
        guard !puzzleHistory.isEmpty else {
            currentStreak = 0
            longestStreak = 0
            return
        }
        
        // Ordenar por fecha
        let sortedHistory = puzzleHistory.sorted { $0.completedAt > $1.completedAt }
        
        // Calcular racha actual
        var streak = 0
        var lastDate = Date()
        let calendar = Calendar.current
        
        for puzzle in sortedHistory {
            let daysDifference = calendar.dateComponents([.day], from: puzzle.completedAt, to: lastDate).day ?? 0
            
            if daysDifference <= 1 {
                streak += 1
                lastDate = puzzle.completedAt
            } else {
                break
            }
        }
        
        currentStreak = streak
        
        // Calcular racha más larga (simplificado)
        longestStreak = max(streak, currentStreak)
    }
    
    // MARK: - Refresh
    func refresh() async {
        guard let userId = currentUserId else { return }
        await loadData(for: userId)
    }
    
    // MARK: - Format Time
    func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    // MARK: - Get Completion Percentage for Type
    func getCompletionPercentage(for type: UserProgress.PuzzleType) -> Int {
        guard let stats = progressByType[type] else { return 0 }
        
        // Calcular basándose en la dificultad actual
        // Por ejemplo: 10 puzzles por nivel, 5 niveles = 50 total
        let totalPuzzles = stats.currentDifficulty * 10
        let percentage = (Double(stats.completed) / Double(totalPuzzles)) * 100
        return min(Int(percentage), 100)
    }
}
