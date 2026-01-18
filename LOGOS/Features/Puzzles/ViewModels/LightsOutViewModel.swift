//
//  LightsOutViewModel.swift
//  LOGOS
//
//  ViewModel para Lights Out
//

import Foundation
import Combine

@MainActor
class LightsOutViewModel: ObservableObject {

    // MARK: - Published Properties
    let puzzleEngine: LightsOutEngine
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
        self.puzzleEngine = LightsOutEngine()

        puzzleEngine.generatePuzzle(difficulty: difficulty)

        setupObservers()
    }

    // MARK: - Setup Observers
    private func setupObservers() {
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
            hintsUsed: 0,
            isSolved: true
        )

        syncService.saveHistory(history)
        updateProgress(timeSpent: elapsedTime)

        showingCompletionSheet = true

        print("🎉 Lights Out puzzle completado")
    }

    // MARK: - Update Progress
    private func updateProgress(timeSpent: TimeInterval) {
        var progress = syncService.getLocalProgress(userId: userId, puzzleType: puzzleType)
            ?? UserProgress(userId: userId, puzzleType: puzzleType)

        progress.completedCount += 1
        progress.lastPlayedAt = Date()

        if let bestTime = progress.bestTime {
            progress.bestTime = min(bestTime, timeSpent)
        } else {
            progress.bestTime = timeSpent
        }

        if progress.completedCount % 3 == 0 {
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
