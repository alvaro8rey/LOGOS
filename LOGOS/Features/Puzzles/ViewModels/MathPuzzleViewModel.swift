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
                    self?.handleCompletion()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Handle Completion
    private func handleCompletion() {
        showingCompletionSheet = true

        Task {
            await saveProgress()
        }
    }

    // MARK: - Save Progress
    private func saveProgress() async {
        let isSolved = puzzleEngine.isCompleted
        let timeSpent = puzzleEngine.getElapsedTime()
        let hintsUsed = puzzleEngine.usedHintsCount

        let history = PuzzleHistory(
            userId: userId,
            puzzleType: puzzleType,
            difficulty: difficulty,
            isSolved: isSolved,
            timeSpent: timeSpent,
            hintsUsed: hintsUsed,
            completedAt: Date()
        )

        // Guardar en local
        syncService.savePuzzleHistory(history)

        // Actualizar progreso
        let currentProgress = syncService.getProgress(for: userId, puzzleType: puzzleType)

        let newCompletedCount = currentProgress.completedCount + 1
        let newBestTime: Double
        if let existingBest = currentProgress.bestTime {
            newBestTime = min(existingBest, timeSpent)
        } else {
            newBestTime = timeSpent
        }

        let newProgress = UserProgress(
            id: currentProgress.id,
            userId: userId,
            puzzleType: puzzleType,
            completedCount: newCompletedCount,
            currentDifficulty: difficulty,
            bestTime: newBestTime,
            totalHintsUsed: currentProgress.totalHintsUsed + hintsUsed,
            lastPlayedAt: Date(),
            updatedAt: Date()
        )

        syncService.updateProgress(newProgress)

        print("✅ Math puzzle progreso guardado: \(newCompletedCount) completados")
    }

    // MARK: - Generate New Puzzle
    func generateNewPuzzle() {
        showingCompletionSheet = false
        puzzleEngine.generatePuzzle(difficulty: difficulty)
    }
}
