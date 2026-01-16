//
//  MathPuzzle.swift
//  LOGOS
//
//  Puzzle Matemático: Similar a KenKen/Calcudoku
//

import Foundation

struct MathPuzzle {
    let seed: String
    let difficulty: Int
    let gridSize: Int
    let solution: [[Int]]
    let cages: [Cage]

    struct CellPosition: Equatable {
        let row: Int
        let col: Int
    }

    struct Cage: Identifiable {
        let id: String
        let cells: [CellPosition]
        let target: Int
        let operation: Operation

        enum Operation: String {
            case add = "+"
            case subtract = "-"
            case multiply = "×"
            case divide = "÷"
            case none = ""

            var symbol: String { return self.rawValue }
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

        while cages.count < gridSize * 2 {
            let row = random.next(max: gridSize)
            let col = random.next(max: gridSize)

            if !used[row][col] {
                var cells = [(row, col)]
                used[row][col] = true

                // Agregar celdas adyacentes aleatoriamente
                if random.next(max: 2) == 0 && col + 1 < gridSize && !used[row][col + 1] {
                    cells.append((row, col + 1))
                    used[row][col + 1] = true
                }

                let values = cells.map { solution[$0.0][$0.1] }
                let target: Int
                let operation: Cage.Operation

                if cells.count == 1 {
                    target = values[0]
                    operation = .none
                } else {
                    let ops: [Cage.Operation] = [.add, .multiply]
                    operation = ops[random.next(max: ops.count)]

                    switch operation {
                    case .add:
                        target = values.reduce(0, +)
                    case .multiply:
                        target = values.reduce(1, *)
                    default:
                        target = values[0]
                    }
                }

                cages.append(Cage(cells: cells, target: target, operation: operation))
            }
        }

        self.cages = cages
    }

    func isValid() -> Bool {
        return gridSize >= 4
    }

    func isSolved(with userGrid: [[Int]]) -> Bool {
        // Verificar que cada fila y columna tenga números únicos
        for i in 0..<gridSize {
            let row = userGrid[i]
            let col = (0..<gridSize).map { userGrid[$0][i] }

            if Set(row).count != gridSize || Set(col).count != gridSize {
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
            case .none:
                result = values[0]
            default:
                result = 0
            }

            if result != cage.target {
                return false
            }
        }

        return true
    }
}
