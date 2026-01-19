//
//  ConstraintPuzzleEngine.swift
//  LOGOS
//
//  Created by alvaro on 16/1/26.
//


//
//  ConstraintPuzzleEngine.swift
//  Logos
//
//  Motor de puzzles de restricciones (Nonogram)
//

import Foundation

@MainActor
class ConstraintPuzzleEngine: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentPuzzle: NonogramPuzzle?
    @Published var userGrid: [[NonogramPuzzle.CellState]] = []
    @Published var isCompleted = false
    @Published var availableHints: [Hint] = []
    @Published var usedHintsCount = 0
    
    // MARK: - Private Properties
    private var startTime: Date?
    private var elapsedTime: TimeInterval = 0
    
    // MARK: - Generate Puzzle
    func generatePuzzle(difficulty: Int) {
        let seed = generateSeed()
        let puzzle = NonogramPuzzle(seed: seed, difficulty: difficulty)
        
        guard puzzle.isValid() else {
            print("❌ Puzzle inválido generado, reintentando...")
            generatePuzzle(difficulty: difficulty)
            return
        }
        
        self.currentPuzzle = puzzle
        self.userGrid = Array(
            repeating: Array(repeating: .empty, count: puzzle.gridSize),
            count: puzzle.gridSize
        )
        self.isCompleted = false
        self.usedHintsCount = 0
        self.startTime = Date()
        self.elapsedTime = 0
        
        // Generar pistas disponibles
        generateHints()
        
        print("✅ Puzzle generado: \(puzzle.gridSize)x\(puzzle.gridSize), dificultad \(difficulty)")
    }
    
    // MARK: - Generate Seed
    private func generateSeed() -> String {
        return UUID().uuidString
    }
    
    // MARK: - Toggle Cell
    func toggleCell(row: Int, col: Int) {
        guard !isCompleted else { return }
        guard let puzzle = currentPuzzle else { return }
        guard row >= 0 && row < puzzle.gridSize && col >= 0 && col < puzzle.gridSize else { return }

        objectWillChange.send()

        switch userGrid[row][col] {
        case .empty:
            userGrid[row][col] = .filled
        case .filled:
            userGrid[row][col] = .marked
        case .marked:
            userGrid[row][col] = .empty
        }

        // Verificar si está completo
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
            print("🎉 ¡Puzzle completado en \(elapsedTime)s!")
        }
    }
    
    // MARK: - Generate Hints
    private func generateHints() {
        guard let puzzle = currentPuzzle else { return }
        
        availableHints = [
            // Pista 1: Conceptual
            Hint(
                type: .conceptual,
                message: "Los números indican grupos consecutivos de celdas a rellenar en cada fila y columna. Por ejemplo, [2, 1] significa: 2 celdas juntas, al menos 1 espacio, y luego 1 celda."
            ),
            
            // Pista 2: Estrategia básica
            Hint(
                type: .conceptual,
                message: "Comienza por las filas y columnas con números grandes o con un solo número. Son más fáciles de resolver."
            ),
            
            // Pista 3: Lógica
            Hint(
                type: .logical,
                message: "Si una fila tiene el número \(puzzle.gridSize), toda la fila debe estar llena. Si tiene [0], toda la fila debe estar vacía."
            ),
            
            // Pista 4: Parcial - revelar una fila fácil
            generatePartialHint(puzzle: puzzle),
            
            // Pista 5: Error detection
            generateErrorHint(puzzle: puzzle)
        ]
    }
    
    // MARK: - Generate Partial Hint
    private func generatePartialHint(puzzle: NonogramPuzzle) -> Hint {
        // Encontrar la fila más fácil (mayor número o único número)
        var easiestRow = 0
        var maxSum = 0
        
        for (index, hints) in puzzle.rowHints.enumerated() {
            let sum = hints.reduce(0, +)
            if sum > maxSum {
                maxSum = sum
                easiestRow = index
            }
        }
        
        return Hint(
            type: .partial,
            message: "En la fila \(easiestRow + 1), los números \(puzzle.rowHints[easiestRow]) indican dónde van las celdas llenas.",
            specificData: ["row": "\(easiestRow)"]
        )
    }
    
    // MARK: - Generate Error Hint
    private func generateErrorHint(puzzle: NonogramPuzzle) -> Hint {
        // Buscar errores en el grid actual
        for row in 0..<puzzle.gridSize {
            let userRow = userGrid[row].map { $0 == .filled }
            let currentHints = NonogramGenerator.calculateHints(for: userRow)
            let expectedHints = puzzle.rowHints[row]
            
            // Contar celdas llenas
            let filledCount = userRow.filter { $0 }.count
            let expectedCount = expectedHints.reduce(0, +)
            
            if filledCount > expectedCount {
                return Hint(
                    type: .error,
                    message: "La fila \(row + 1) tiene demasiadas celdas llenas. Revisa los números: \(expectedHints).",
                    specificData: ["row": "\(row)", "type": "overfilled"]
                )
            }
        }
        
        return Hint(
            type: .error,
            message: "Revisa cuidadosamente cada fila y columna comparando con los números indicados."
        )
    }
    
    // MARK: - Use Hint
    func useHint(hint: Hint) {
        usedHintsCount += 1
        
        // Si es una pista parcial, revelar la celda
        if hint.type == .partial, let rowString = hint.specificData?["row"],
           let row = Int(rowString),
           let puzzle = currentPuzzle {
            
            // Revelar algunas celdas de esa fila
            for col in 0..<puzzle.gridSize {
                if puzzle.solution[row][col] && userGrid[row][col] == .empty {
                    userGrid[row][col] = .filled
                    break // Revelar solo una celda por pista
                }
            }
            
            checkCompletion()
        }
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
        
        userGrid = Array(
            repeating: Array(repeating: .empty, count: puzzle.gridSize),
            count: puzzle.gridSize
        )
        isCompleted = false
        usedHintsCount = 0
        startTime = Date()
        elapsedTime = 0
    }
}
