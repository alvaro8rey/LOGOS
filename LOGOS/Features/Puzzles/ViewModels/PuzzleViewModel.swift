//
//  PuzzleViewModel.swift
//  LOGOS
//
//  Created by alvaro on 16/1/26.
//


//
//  PuzzleViewModel.swift
//  Logos
//
//  ViewModel principal para puzzles
//

import Foundation
import Combine

@MainActor
class PuzzleViewModel: ObservableObject {

    // MARK: - Published Properties
    let puzzleEngine: ConstraintPuzzleEngine
    @Published var showingHintSheet = false
    @Published var selectedHint: Hint?
    @Published var showingCompletionSheet = false
    @Published var canUseHint = true
    @Published var freeHintsRemaining = 1

    // MARK: - Properties
    let puzzleType: UserProgress.PuzzleType
    let difficulty: Int
    private let userId: String

    // MARK: - Services
    private let syncService = SyncService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(puzzleType: UserProgress.PuzzleType, difficulty: Int, userId: String) {
        self.puzzleType = puzzleType
        self.difficulty = difficulty
        self.userId = userId
        self.puzzleEngine = ConstraintPuzzleEngine()

        // Generar puzzle
        puzzleEngine.generatePuzzle(difficulty: difficulty)

        setupObservers()
    }

    // MARK: - Setup Observers
    private func setupObservers() {
        // Reenviar cambios del engine a este ViewModel
        puzzleEngine.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        // Observar cuando se complete el puzzle
        puzzleEngine.$isCompleted
            .sink { [weak self] isCompleted in
                if isCompleted {
                    self?.handlePuzzleCompletion()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Use Hint
    func useHint(_ hint: Hint) {
        guard canUseHint else { return }
        
        if freeHintsRemaining > 0 {
            // Usar pista gratuita
            freeHintsRemaining -= 1
            puzzleEngine.useHint(hint: hint)
            selectedHint = hint
        } else {
            // Requiere pista de pago
            // TODO: Implementar con StoreKit en Fase 4
            print("⚠️ Requiere pista de pago")
        }
    }
    
    // MARK: - Handle Puzzle Completion
    private func handlePuzzleCompletion() {
        guard let puzzle = puzzleEngine.currentPuzzle else { return }
        
        let elapsedTime = puzzleEngine.getElapsedTime()
        
        // Crear historial
        let history = PuzzleHistory(
            userId: userId,
            puzzleType: puzzleType,
            seed: puzzle.seed,
            difficulty: difficulty,
            timeSpent: elapsedTime,
            hintsUsed: puzzleEngine.usedHintsCount,
            isSolved: true
        )
        
        // Guardar historial
        syncService.saveHistory(history)
        
        // Actualizar progreso
        updateProgress(timeSpent: elapsedTime)
        
        // Mostrar sheet de completado
        showingCompletionSheet = true
        
        print("🎉 Puzzle completado y guardado")
    }
    
    // MARK: - Update Progress
    private func updateProgress(timeSpent: TimeInterval) {
        // Obtener progreso actual o crear nuevo
        var progress = syncService.getLocalProgress(userId: userId, puzzleType: puzzleType)
            ?? UserProgress(userId: userId, puzzleType: puzzleType)
        
        // Actualizar
        progress.completedCount += 1
        progress.lastPlayedAt = Date()
        progress.totalHintsUsed += puzzleEngine.usedHintsCount
        
        // Actualizar mejor tiempo
        if let bestTime = progress.bestTime {
            progress.bestTime = min(bestTime, timeSpent)
        } else {
            progress.bestTime = timeSpent
        }
        
        // Incrementar dificultad cada 5 puzzles completados
        if progress.completedCount % 5 == 0 {
            progress.currentDifficulty = min(progress.currentDifficulty + 1, 5)
        }
        
        progress.updatedAt = Date()
        
        // Guardar
        syncService.saveProgress(progress)
        
        print("✅ Progreso actualizado: \(progress.completedCount) completados")
    }
    
    // MARK: - New Puzzle
    func generateNewPuzzle() {
        // Obtener progreso actual para la dificultad
        let progress = syncService.getLocalProgress(userId: userId, puzzleType: puzzleType)
        let currentDifficulty = progress?.currentDifficulty ?? difficulty
        
        puzzleEngine.generatePuzzle(difficulty: currentDifficulty)
        freeHintsRemaining = 1
        showingCompletionSheet = false
    }
}
