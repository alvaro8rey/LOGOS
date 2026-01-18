//
//  MathPuzzle.swift
//  LOGOS
//
//  Puzzle Matemático: Similar a KenKen/Calcudoku
//  Completa todas las celdas siguiendo las reglas matemáticas
//

import Foundation

struct MathPuzzle: Codable {
    let seed: String
    let difficulty: Int
    let gridSize: Int
    let solution: [[Int]]
    let cages: [Cage]

    struct CellPosition: Equatable, Codable {
        let row: Int
        let col: Int
    }

    struct Cage: Identifiable, Codable {
        let id: String
        let cells: [CellPosition]
        let target: Int
        let operation: Operation

        enum Operation: String, Codable {
            case add = "+"
            case subtract = "-"
            case multiply = "×"
            case divide = "÷"
            case none = ""

            var symbol: String { return self.rawValue }

            var displayName: String {
                switch self {
                case .add: return "Suma"
                case .subtract: return "Resta"
                case .multiply: return "Multiplicación"
                case .divide: return "División"
                case .none: return "Valor"
                }
            }
        }

        init(cells: [(Int, Int)], target: Int, operation: Operation) {
            self.id = UUID().uuidString
            self.cells = cells.map { CellPosition(row: $0.0, col: $0.1) }
            self.target = target
            self.operation = operation
        }
    }

    init(seed: String, difficulty: Int) {
        self.seed = seed
        self.difficulty = difficulty

        // Tamaño según dificultad
        switch difficulty {
        case 1: self.gridSize = 4
        case 2: self.gridSize = 5
        case 3: self.gridSize = 6
        case 4: self.gridSize = 6
        default: self.gridSize = 7
        }

        // Generar solución válida (sudoku simplificado)
        var solution = Array(repeating: Array(repeating: 0, count: gridSize), count: gridSize)
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                solution[row][col] = ((row + col) % gridSize) + 1
            }
        }

        self.solution = solution

        // Generar jaulas
        var random = SeededRandomGenerator(seed: seed)
        var cages: [Cage] = []
        var used = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)

        // Más jaulas para dificultad alta
        let targetCages = gridSize * 2 + difficulty
        var failedAttempts = 0
        let maxFailedAttempts = 100

        while cages.count < targetCages && failedAttempts < maxFailedAttempts {
            let row = random.next(max: gridSize)
            let col = random.next(max: gridSize)

            if !used[row][col] {
                failedAttempts = 0  // Reset on success
                var cells = [(row, col)]
                used[row][col] = true

                // Intentar agregar más celdas según dificultad
                let maxCellsInCage = difficulty >= 3 ? 3 : 2
                var attempts = 0

                while cells.count < maxCellsInCage && attempts < 4 {
                    let lastCell = cells.last!
                    let directions = [(0, 1), (1, 0), (0, -1), (-1, 0)]

                    if let (dr, dc) = directions.randomElement(using: &random) {
                        let newRow = lastCell.0 + dr
                        let newCol = lastCell.1 + dc

                        if newRow >= 0 && newRow < gridSize &&
                           newCol >= 0 && newCol < gridSize &&
                           !used[newRow][newCol] {
                            cells.append((newRow, newCol))
                            used[newRow][newCol] = true
                        }
                    }

                    attempts += 1
                }

                let values = cells.map { solution[$0.0][$0.1] }
                let target: Int
                let operation: Cage.Operation

                if cells.count == 1 {
                    // Celda individual
                    target = values[0]
                    operation = .none
                } else {
                    // Operación para múltiples celdas
                    var ops: [Cage.Operation] = [.add, .multiply]

                    // Agregar resta y división para dificultad alta
                    if difficulty >= 3 && cells.count == 2 {
                        ops.append(contentsOf: [.subtract, .divide])
                    }

                    operation = ops[random.next(max: ops.count)]

                    switch operation {
                    case .add:
                        target = values.reduce(0, +)
                    case .multiply:
                        target = values.reduce(1, *)
                    case .subtract:
                        target = abs(values[0] - values[1])
                    case .divide:
                        let sorted = values.sorted(by: >)
                        target = sorted[0] / (sorted[1] == 0 ? 1 : sorted[1])
                    case .none:
                        target = values[0]
                    }
                }

                cages.append(Cage(cells: cells, target: target, operation: operation))
            } else {
                failedAttempts += 1
            }
        }

        self.cages = cages
    }

    func isValid() -> Bool {
        return gridSize >= 4
    }

    func isSolved(with userGrid: [[Int]]) -> Bool {
        // Verificar que todas las celdas estén llenas
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if userGrid[row][col] == 0 {
                    return false
                }
            }
        }

        // Verificar que cada fila tenga números únicos (1 a gridSize)
        for row in 0..<gridSize {
            let rowValues = userGrid[row]
            if Set(rowValues).count != gridSize {
                return false
            }
            if rowValues.min() != 1 || rowValues.max() != gridSize {
                return false
            }
        }

        // Verificar que cada columna tenga números únicos (1 a gridSize)
        for col in 0..<gridSize {
            let colValues = (0..<gridSize).map { userGrid[$0][col] }
            if Set(colValues).count != gridSize {
                return false
            }
            if colValues.min() != 1 || colValues.max() != gridSize {
                return false
            }
        }

        // Verificar jaulas
        for cage in cages {
            let values = cage.cells.map { userGrid[$0.row][$0.col] }

            if values.contains(0) { return false }

            let result: Int
            switch cage.operation {
            case .add:
                result = values.reduce(0, +)
            case .multiply:
                result = values.reduce(1, *)
            case .subtract:
                result = abs(values[0] - values[1])
            case .divide:
                let sorted = values.sorted(by: >)
                result = sorted[0] / (sorted[1] == 0 ? 1 : sorted[1])
            case .none:
                result = values[0]
            }

            if result != cage.target {
                return false
            }
        }

        return true
    }

    // MARK: - Helper: Get cage for cell
    func getCage(for row: Int, col: Int) -> Cage? {
        return cages.first { cage in
            cage.cells.contains { $0.row == row && $0.col == col }
        }
    }

    // MARK: - Helper: Is cell first in cage
    func isFirstCellInCage(row: Int, col: Int) -> Bool {
        guard let cage = getCage(for: row, col: col) else { return false }
        return cage.cells.first?.row == row && cage.cells.first?.col == col
    }
}
