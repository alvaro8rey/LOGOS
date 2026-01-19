//
//  SymmetryPuzzleEngine.swift
//  LOGOS
//
//  Motor de puzzles de simetría
//

import Foundation

@MainActor
class SymmetryPuzzleEngine: ObservableObject {

    // MARK: - Published Properties
    @Published var currentPuzzle: SymmetryPuzzle?
    @Published var userGrid: [[SymmetryPuzzle.CellState]] = []
    @Published var isCompleted = false
    @Published var availableHints: [Hint] = []
    @Published var usedHintsCount = 0

    // MARK: - Private Properties
    private var startTime: Date?
    private var elapsedTime: TimeInterval = 0

    // MARK: - Generate Puzzle
    func generatePuzzle(difficulty: Int) {
        let seed = UUID().uuidString
        let puzzle = SymmetryPuzzle(seed: seed, difficulty: difficulty)

        guard puzzle.isValid() else {
            print("❌ Puzzle inválido generado, reintentando...")
            generatePuzzle(difficulty: difficulty)
            return
        }

        self.currentPuzzle = puzzle
        self.isCompleted = false
        self.usedHintsCount = 0
        self.startTime = Date()
        self.elapsedTime = 0

        // Inicializar userGrid con patrón inicial
        var grid = Array(repeating: Array(repeating: SymmetryPuzzle.CellState.empty, count: puzzle.gridSize), count: puzzle.gridSize)

        for row in 0..<puzzle.gridSize {
            for col in 0..<puzzle.gridSize {
                if let value = puzzle.initialPattern[row][col] {
                    grid[row][col] = value ? .filled : .empty
                }
            }
        }

        self.userGrid = grid

        generateHints()

        print("✅ Symmetry puzzle generado: \(puzzle.gridSize)x\(puzzle.gridSize), tipo: \(puzzle.symmetryType.rawValue), dificultad \(difficulty)")
    }

    // MARK: - Toggle Cell
    func toggleCell(row: Int, col: Int) {
        guard !isCompleted else { return }
        guard let puzzle = currentPuzzle else { return }

        // Verificar si la celda es inicial (no editable)
        if puzzle.initialPattern[row][col] != nil {
            return
        }

        objectWillChange.send()

        switch userGrid[row][col] {
        case .empty:
            userGrid[row][col] = .filled
        case .filled:
            userGrid[row][col] = .marked
        case .marked:
            userGrid[row][col] = .empty
        }

        checkCompletion()
    }

    // MARK: - Check Completion
    private func checkCompletion() {
        guard let puzzle = currentPuzzle else { return }

        if puzzle.isSolved(with: userGrid) {
            isCompleted = true
            if let start = startTime {
                elapsedTime = Date().timeIntervalSince(start)
            }
            print("🎉 Symmetry puzzle completado en \(elapsedTime)s!")
        }
    }

    // MARK: - Generate Hints
    private func generateHints() {
        guard let puzzle = currentPuzzle else { return }

        availableHints = [
            Hint(
                type: .conceptual,
                message: "Completa el patrón siguiendo la simetría indicada: \(puzzle.symmetryType.displayName)."
            ),
            Hint(
                type: .logical,
                message: "Observa el patrón revelado y replica de forma simétrica en la parte vacía."
            ),
            Hint(
                type: .partial,
                message: "Marca con X las celdas que seguro están vacías para visualizar mejor el patrón."
            )
        ]
    }

    // MARK: - Use Hint
    func useHint(hint: Hint) {
        usedHintsCount += 1
    }

    // MARK: - Get Elapsed Time
    func getElapsedTime() -> TimeInterval {
        guard let start = startTime, !isCompleted else {
            return elapsedTime
        }
        return Date().timeIntervalSince(start)
    }

    // MARK: - Reset Puzzle
    func resetPuzzle() {
        guard let puzzle = currentPuzzle else { return }

        var grid = Array(repeating: Array(repeating: SymmetryPuzzle.CellState.empty, count: puzzle.gridSize), count: puzzle.gridSize)

        for row in 0..<puzzle.gridSize {
            for col in 0..<puzzle.gridSize {
                if let value = puzzle.initialPattern[row][col] {
                    grid[row][col] = value ? .filled : .empty
                }
            }
        }

        userGrid = grid
        isCompleted = false
        usedHintsCount = 0
        startTime = Date()
        elapsedTime = 0
    }

    // MARK: - Is Cell Initial
    func isCellInitial(row: Int, col: Int) -> Bool {
        guard let puzzle = currentPuzzle else { return false }
        return puzzle.initialPattern[row][col] != nil
    }
}
