//
//  HomeViewModel.swift
//  Logos
//
//  ViewModel para la vista principal
//

import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var userProgress: [UserProgress] = []
    @Published var recentHistory: [PuzzleHistory] = []
    @Published var isLoading = false
    @Published var totalCompleted = 0
    @Published var totalTimeSpent: TimeInterval = 0
    
    // MARK: - Services
    private let syncService = SyncService.shared
    private let supabaseService = SupabaseService.shared
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String?
    
    // MARK: - Initialization
    init() {
        // Observers will be set up when user is loaded
    }
    
    // MARK: - Load Data
    func loadData(for userId: String) async {
        self.currentUserId = userId
        isLoading = true
        
        // 1. Cargar progreso local primero
        loadLocalProgress(userId: userId)
        
        // 2. Sincronizar con remoto en background
        await syncService.syncAll()
        
        // 3. Recargar después de sincronizar
        loadLocalProgress(userId: userId)
        
        // 4. Cargar historial reciente
        await loadRecentHistory(userId: userId)
        
        isLoading = false
    }
    
    // MARK: - Load Local Progress
    private func loadLocalProgress(userId: String) {
        userProgress = syncService.getAllLocalProgress(userId: userId)
        calculateStats()
        print("✅ Progreso local cargado: \(userProgress.count) tipos")
    }
    
    // MARK: - Load Recent History
    private func loadRecentHistory(userId: String) async {
        do {
            recentHistory = try await supabaseService.fetchPuzzleHistory(userId: userId, limit: 10)
            print("✅ Historial reciente cargado: \(recentHistory.count) puzzles")
        } catch {
            print("❌ Error cargando historial: \(error)")
            // Cargar historial local como fallback
            loadLocalHistory(userId: userId)
        }
    }
    
    // MARK: - Load Local History
    private func loadLocalHistory(userId: String) {
        let context = PersistenceController.shared.viewContext
        let entities = PuzzleHistoryEntity.fetchHistory(userId: userId, limit: 10, in: context)
        recentHistory = entities.compactMap { $0.toDomainModel() }
        print("✅ Historial local cargado: \(recentHistory.count) puzzles")
    }
    
    // MARK: - Calculate Stats
    private func calculateStats() {
        totalCompleted = userProgress.reduce(0) { $0 + $1.completedCount }
        // TODO: Calcular tiempo total desde el historial
    }
    
    // MARK: - Get Progress for Type
    func getProgress(for type: UserProgress.PuzzleType) -> UserProgress? {
        return userProgress.first(where: { $0.puzzleType == type })
    }
    
    // MARK: - Refresh
    func refresh() async {
        guard let userId = currentUserId else { return }
        await loadData(for: userId)
    }
}
