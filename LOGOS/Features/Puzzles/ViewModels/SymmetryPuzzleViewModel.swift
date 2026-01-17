//
//  SymmetryPuzzleViewModel.swift
//  LOGOS
//

import Foundation
import Combine

@MainActor
class SymmetryPuzzleViewModel: ObservableObject {
    @ObservedObject var puzzleEngine: SymmetryPuzzleEngine
    @Published var showingCompletionSheet = false

    let puzzleType: UserProgress.PuzzleType
    let difficulty: Int
    private let userId: String
    private let syncService = SyncService.shared
    private var cancellables = Set<AnyCancellable>()

    init(puzzleType: UserProgress.PuzzleType, difficulty: Int, userId: String) {
        self.puzzleType = puzzleType
        self.difficulty = difficulty
        self.userId = userId
        self.puzzleEngine = SymmetryPuzzleEngine()

        puzzleEngine.generatePuzzle(difficulty: difficulty)
        setupObservers()
    }

    private func setupObservers() {
        puzzleEngine.$isCompleted
            .sink { [weak self] isCompleted in
                if isCompleted {
                    self?.handlePuzzleCompletion()
                }
            }
            .store(in: &cancellables)
    }

    private func handlePuzzleCompletion() {
        guard let puzzle = puzzleEngine.currentPuzzle else { return }

        let history = PuzzleHistory(
            userId: userId,
            puzzleType: puzzleType,
            seed: puzzle.seed,
            difficulty: difficulty,
            timeSpent: puzzleEngine.getElapsedTime(),
            hintsUsed: puzzleEngine.usedHintsCount,
            isSolved: true
        )

        syncService.saveHistory(history)
        updateProgress(timeSpent: puzzleEngine.getElapsedTime())
        showingCompletionSheet = true
    }

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
    }

    func generateNewPuzzle() {
        let progress = syncService.getLocalProgress(userId: userId, puzzleType: puzzleType)
        let currentDifficulty = progress?.currentDifficulty ?? difficulty
        puzzleEngine.generatePuzzle(difficulty: currentDifficulty)
        showingCompletionSheet = false
    }
}
