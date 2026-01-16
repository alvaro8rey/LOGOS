//
//  MathPuzzleEngine.swift
//  LOGOS
//
//  Motor de puzzles matemáticos
//

import Foundation

@MainActor
class MathPuzzleEngine: ObservableObject {

    // MARK: - Published Properties
    @Published var currentPuzzle: MathPuzzle?
    @Published var userGrid: [[Int]] = []
    @Published var isCompleted = false
    @Published var availableHints: [Hint] = []
    @Published var usedHintsCount = 0

    // MARK: - Private Properties
    private var startTime: Date?
    private var elapsedTime: TimeInterval = 0

    // MARK: - Generate Puzzle
    func generatePuzzle(difficulty: Int) {
        let seed = UUID().uuidString
        let puzzle = MathPuzzle(seed: seed, difficulty: difficulty)

        guard puzzle.isValid() else {
            print("❌ Puzzle inválido generado, reintentando...")
            generatePuzzle(difficulty: difficulty)
            return
        }

        self.currentPuzzle = puzzle
        self.userGrid = Array(repeating: Array(repeating: 0, count: puzzle.gridSize), count: puzzle.gridSize)
        self.isCompleted = false
        self.usedHintsCount = 0
        self.startTime = Date()
        self.elapsedTime = 0

        generateHints()

        print("✅ Math puzzle generado: \(puzzle.gridSize)x\(puzzle.gridSize), dificultad \(difficulty)")
    }

    // MARK: - Set Cell Value
    func setCellValue(row: Int, col: Int, value: Int) {
        guard !isCompleted else { return }
        guard let puzzle = currentPuzzle else { return }
        guard value >= 0 && value <= puzzle.gridSize else { return }

        objectWillChange.send()

        userGrid[row][col] = value

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
            print("🎉 Math puzzle completado en \(elapsedTime)s!")
        }
    }

    // MARK: - Generate Hints
    private func generateHints() {
        availableHints = [
            Hint(
                type: .conceptual,
                message: "Llena la cuadrícula con números del 1 al tamaño de la cuadrícula. Cada número debe aparecer una vez por fila y columna."
            ),
            Hint(
                type: .logical,
                message: "Las jaulas muestran operaciones matemáticas. Los números en cada jaula deben dar el resultado indicado."
            ),
            Hint(
                type: .partial,
                message: "Comienza por las jaulas más pequeñas o con operaciones más simples."
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

        userGrid = Array(repeating: Array(repeating: 0, count: puzzle.gridSize), count: puzzle.gridSize)
        isCompleted = false
        usedHintsCount = 0
        startTime = Date()
        elapsedTime = 0
    }
}
