//
//  LightsOutEngine.swift
//  LOGOS
//
//  Engine para Lights Out puzzle
//

import Foundation
import Combine

class LightsOutEngine: ObservableObject {

    // MARK: - Published Properties
    @Published var currentPuzzle: LightsOutPuzzle?
    @Published var currentGrid: [[Bool]] = []
    @Published var isCompleted = false
    @Published var moveCount = 0
    @Published var refreshTrigger = UUID()

    // MARK: - Private Properties
    private var startTime: Date?

    // MARK: - Initialization
    init() {}

    // MARK: - Generate Puzzle
    func generatePuzzle(difficulty: Int) {
        let seed = UUID().uuidString
        let puzzle = LightsOutPuzzle(seed: seed, difficulty: difficulty)

        self.currentPuzzle = puzzle
        self.currentGrid = puzzle.initialState
        self.isCompleted = false
        self.moveCount = 0
        self.startTime = Date()
        self.refreshTrigger = UUID()
    }

    // MARK: - Toggle Cell
    func toggleCell(row: Int, col: Int) {
        guard let puzzle = currentPuzzle else { return }

        puzzle.toggle(grid: &currentGrid, row: row, col: col)
        moveCount += 1
        refreshTrigger = UUID()
        objectWillChange.send()

        checkCompletion()
    }

    // MARK: - Reset Puzzle
    func resetPuzzle() {
        guard let puzzle = currentPuzzle else { return }

        currentGrid = puzzle.initialState
        isCompleted = false
        moveCount = 0
        startTime = Date()
        refreshTrigger = UUID()
        objectWillChange.send()
    }

    // MARK: - Check Completion
    private func checkCompletion() {
        guard let puzzle = currentPuzzle else { return }

        if puzzle.isSolved(with: currentGrid) {
            isCompleted = true
        }
    }

    // MARK: - Use Hint
    func useHint() {
        guard let puzzle = currentPuzzle,
              let firstMove = puzzle.solution.first else { return }

        toggleCell(row: firstMove.row, col: firstMove.col)
    }

    // MARK: - Get Elapsed Time
    func getElapsedTime() -> TimeInterval {
        guard let start = startTime else { return 0 }
        return Date().timeIntervalSince(start)
    }
}
