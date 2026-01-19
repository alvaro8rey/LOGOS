//
//  SudokuPuzzleEngine.swift
//  LOGOS
//
//  Engine para Sudoku 9x9
//

import Foundation
import Combine

class SudokuPuzzleEngine: ObservableObject {

    // MARK: - Published Properties
    @Published var currentPuzzle: SudokuPuzzle?
    @Published var userGrid: [[Int]] = []
    @Published var isCompleted = false
    @Published var usedHintsCount = 0
    @Published var hintsAvailable = 1  // Solo 1 pista gratuita
    @Published var refreshTrigger = UUID()
    @Published var showingBuyHintsSheet = false

    // MARK: - Private Properties
    private var startTime: Date?

    // MARK: - Initialization
    init() {
        self.userGrid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    }

    // MARK: - Generate Puzzle
    func generatePuzzle(difficulty: Int) {
        let seed = UUID().uuidString
        let puzzle = SudokuPuzzle(seed: seed, difficulty: difficulty)

        self.currentPuzzle = puzzle
        self.userGrid = puzzle.initialGrid
        self.isCompleted = false
        self.usedHintsCount = 0
        self.hintsAvailable = 1  // Resetear a 1 pista gratuita
        self.startTime = Date()
        self.refreshTrigger = UUID()
    }

    // MARK: - Set Cell Value
    func setCellValue(row: Int, col: Int, value: Int) {
        guard let puzzle = currentPuzzle else { return }

        // No permitir editar celdas pre-llenadas
        if puzzle.isInitialCell(row: row, col: col) {
            return
        }

        userGrid[row][col] = value
        refreshTrigger = UUID()
        objectWillChange.send()

        checkCompletion()
    }

    // MARK: - Reset Puzzle
    func resetPuzzle() {
        guard let puzzle = currentPuzzle else { return }

        userGrid = puzzle.initialGrid
        isCompleted = false
        startTime = Date()
        refreshTrigger = UUID()
        objectWillChange.send()
    }

    // MARK: - Check Completion
    private func checkCompletion() {
        guard let puzzle = currentPuzzle else { return }

        if puzzle.isSolved(with: userGrid) {
            isCompleted = true
        }
    }

    // MARK: - Use Hint
    func useHint() {
        // Verificar si hay pistas disponibles
        if hintsAvailable <= 0 {
            showingBuyHintsSheet = true
            return
        }

        guard let puzzle = currentPuzzle else { return }

        // Buscar una celda vacía que no sea inicial
        for row in 0..<9 {
            for col in 0..<9 {
                if !puzzle.isInitialCell(row: row, col: col) && userGrid[row][col] == 0 {
                    // Revelar el número correcto
                    userGrid[row][col] = puzzle.solution[row][col]
                    usedHintsCount += 1
                    hintsAvailable -= 1  // Decrementar pistas disponibles
                    refreshTrigger = UUID()
                    objectWillChange.send()
                    checkCompletion()
                    return
                }
            }
        }
    }

    // MARK: - Get Elapsed Time
    func getElapsedTime() -> TimeInterval {
        guard let start = startTime else { return 0 }
        return Date().timeIntervalSince(start)
    }

    // MARK: - Check if cell has conflict
    func hasConflict(row: Int, col: Int) -> Bool {
        guard let puzzle = currentPuzzle else { return false }
        return puzzle.hasConflict(in: userGrid, row: row, col: col)
    }
}
