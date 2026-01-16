//
//  BinaryPuzzleEngine.swift
//  LOGOS
//
//  Motor de puzzles de Estados Binarios: Binary
//

import Foundation

@MainActor
class BinaryPuzzleEngine: ObservableObject {

    // MARK: - Published Properties
    @Published var currentPuzzle: BinaryPuzzle?
    @Published var userGrid: [[BinaryPuzzle.CellState]] = []
    @Published var isCompleted = false
    @Published var availableHints: [Hint] = []
    @Published var usedHintsCount = 0

    // MARK: - Private Properties
    private var startTime: Date?
    private var elapsedTime: TimeInterval = 0

    // MARK: - Generate Puzzle
    func generatePuzzle(difficulty: Int) {
        let seed = UUID().uuidString
        let puzzle = BinaryPuzzle(seed: seed, difficulty: difficulty)

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

        // Inicializar userGrid con valores iniciales
        var grid = Array(repeating: Array(repeating: BinaryPuzzle.CellState.empty, count: puzzle.gridSize), count: puzzle.gridSize)

        for row in 0..<puzzle.gridSize {
            for col in 0..<puzzle.gridSize {
                if let value = puzzle.initialGrid[row][col] {
                    grid[row][col] = value == 0 ? .zero : .one
                }
            }
        }

        self.userGrid = grid

        generateHints()

        print("✅ Binary puzzle generado: \(puzzle.gridSize)x\(puzzle.gridSize), dificultad \(difficulty)")
    }

    // MARK: - Toggle Cell
    func toggleCell(row: Int, col: Int) {
        guard !isCompleted else { return }
        guard let puzzle = currentPuzzle else { return }

        // Verificar si la celda es inicial (no editable)
        if puzzle.initialGrid[row][col] != nil {
            return
        }

        objectWillChange.send()

        switch userGrid[row][col] {
        case .empty:
            userGrid[row][col] = .zero
        case .zero:
            userGrid[row][col] = .one
        case .one:
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
            print("🎉 Binary puzzle completado en \(elapsedTime)s!")
        }
    }

    // MARK: - Generate Hints
    private func generateHints() {
        availableHints = [
            Hint(
                type: .conceptual,
                message: "Llena la cuadrícula con 0s y 1s. Cada fila y columna debe tener la misma cantidad de cada número."
            ),
            Hint(
                type: .conceptual,
                message: "No puede haber más de dos 0s o 1s consecutivos en ninguna fila o columna."
            ),
            Hint(
                type: .logical,
                message: "Si hay dos 0s o dos 1s juntos, el número adyacente debe ser el opuesto."
            ),
            Hint(
                type: .partial,
                message: "Busca filas o columnas que ya tengan la mitad de un número. Completa con el otro."
            ),
            Hint(
                type: .error,
                message: "Verifica que no haya tres números iguales consecutivos en ninguna fila o columna."
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

        var grid = Array(repeating: Array(repeating: BinaryPuzzle.CellState.empty, count: puzzle.gridSize), count: puzzle.gridSize)

        for row in 0..<puzzle.gridSize {
            for col in 0..<puzzle.gridSize {
                if let value = puzzle.initialGrid[row][col] {
                    grid[row][col] = value == 0 ? .zero : .one
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
        return puzzle.initialGrid[row][col] != nil
    }
}
