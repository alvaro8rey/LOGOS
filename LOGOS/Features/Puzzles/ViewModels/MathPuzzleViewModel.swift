//
//  MathPuzzleViewModel.swift
//  LOGOS
//
//  ViewModel para puzzle matemático (KenKen/Calcudoku)
//

import Foundation
import Combine

@MainActor
class MathPuzzleViewModel: ObservableObject {

    // MARK: - Published Properties
    let puzzleEngine: MathPuzzleEngine
    @Published var showingCompletionSheet = false

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
        self.puzzleEngine = MathPuzzleEngine()

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

        puzzleEngine.$isCompleted
            .sink { [weak self] isCompleted in
                if isCompleted {
                    self?.handlePuzzleCompletion()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Handle Puzzle Completion
    private func handlePuzzleCompletion() {
        guard let puzzle = puzzleEngine.currentPuzzle else { return }

        let elapsedTime = puzzleEngine.getElapsedTime()

        let history = PuzzleHistory(
            userId: userId,
            puzzleType: puzzleType,
            seed: puzzle.seed,
            difficulty: difficulty,
            timeSpent: elapsedTime,
            hintsUsed: puzzleEngine.usedHintsCount,
            isSolved: true
        )

        syncService.saveHistory(history)
        updateProgress(timeSpent: elapsedTime)

        showingCompletionSheet = true

        print("🎉 Math puzzle completado y guardado")
    }

    // MARK: - Update Progress
    private func updateProgress(timeSpent: TimeInterval) {
        var progress = syncService.getLocalProgress(userId: userId, puzzleType: puzzleType)
            ?? UserProgress(userId: userId, puzzleType: puzzleType)

        progress.completedCount += 1
        progress.lastPlayedAt = Date()
        progress.totalHintsUsed += puzzleEngine.usedHintsCount

        if let bestTime = progress.bestTime {
            progress.bestTime = min(bestTime, timeSpent)
        } else {
            progress.bestTime = timeSpent
        }

        if progress.completedCount % 5 == 0 {
            progress.currentDifficulty = min(progress.currentDifficulty + 1, 5)
        }

        progress.updatedAt = Date()

        syncService.saveProgress(progress)

        print("✅ Progreso actualizado: \(progress.completedCount) completados")
    }

    // MARK: - New Puzzle
    func generateNewPuzzle() {
        let progress = syncService.getLocalProgress(userId: userId, puzzleType: puzzleType)
        let currentDifficulty = progress?.currentDifficulty ?? difficulty

        puzzleEngine.generatePuzzle(difficulty: currentDifficulty)
        showingCompletionSheet = false
    }
}
