//
//  BinaryPuzzle.swift
//  LOGOS
//
//  Puzzle de Estados Binarios: Binary
//  Llenar cuadrícula con 0s y 1s siguiendo reglas
//

import Foundation

struct BinaryPuzzle: Codable {
    let seed: String
    let difficulty: Int
    let gridSize: Int
    let solution: [[Int]]  // 0 o 1
    let initialGrid: [[Int?]]  // nil = vacío

    enum CellState: Codable, Equatable {
        case empty
        case zero
        case one
    }

    // MARK: - Initialization
    init(seed: String, difficulty: Int) {
        self.seed = seed
        self.difficulty = difficulty

        // Tamaño siempre par (requisito del puzzle)
        switch difficulty {
        case 1: self.gridSize = 6
        case 2: self.gridSize = 8
        case 3: self.gridSize = 10
        case 4: self.gridSize = 12
        default: self.gridSize = 14
        }

        // Generar solución válida
        var random = SeededRandomGenerator(seed: seed)
        var solution = BinaryPuzzle.generateValidSolution(size: gridSize, random: &random)

        // Si no se pudo generar, usar una solución simple
        if solution.isEmpty {
            solution = BinaryPuzzle.generateSimpleSolution(size: gridSize)
        }

        self.solution = solution

        // Generar grid inicial con algunas celdas reveladas
        let revealPercentage: Double
        switch difficulty {
        case 1: revealPercentage = 0.5  // 50% revelado
        case 2: revealPercentage = 0.4
        case 3: revealPercentage = 0.35
        case 4: revealPercentage = 0.3
        default: revealPercentage = 0.25  // 25% revelado
        }

        var initialGrid = Array(repeating: Array(repeating: Int?.none, count: gridSize), count: gridSize)
        let cellsToReveal = Int(Double(gridSize * gridSize) * revealPercentage)

        var revealed = 0
        while revealed < cellsToReveal {
            let row = random.next(max: gridSize)
            let col = random.next(max: gridSize)

            if initialGrid[row][col] == nil {
                initialGrid[row][col] = solution[row][col]
                revealed += 1
            }
        }

        self.initialGrid = initialGrid
    }

    // MARK: - Generate Valid Solution
    static func generateValidSolution(size: Int, random: inout SeededRandomGenerator) -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: size), count: size)

        // Algoritmo simple: generar fila por fila asegurando reglas
        for row in 0..<size {
            var validRow = false
            var attempts = 0

            while !validRow && attempts < 100 {
                // Generar fila con mitad 0s y mitad 1s
                var rowValues = Array(repeating: 0, count: size / 2) + Array(repeating: 1, count: size / 2)
                rowValues.shuffle(using: &random)
                grid[row] = rowValues

                // Verificar reglas
                if isValidRow(rowValues) && !hasDuplicateRows(grid, upTo: row) {
                    validRow = true
                }
                attempts += 1
            }
        }

        // Verificar columnas
        if areColumnsValid(grid) {
            return grid
        }

        return []
    }

    // MARK: - Generate Simple Solution
    static func generateSimpleSolution(size: Int) -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: size), count: size)

        // Patrón alternado simple
        for row in 0..<size {
            for col in 0..<size {
                grid[row][col] = (row + col) % 2
            }
        }

        return grid
    }

    // MARK: - Validation Helpers
    static func isValidRow(_ row: [Int]) -> Bool {
        // No más de dos consecutivos
        for i in 0..<(row.count - 2) {
            if row[i] == row[i + 1] && row[i + 1] == row[i + 2] {
                return false
            }
        }
        return true
    }

    static func hasDuplicateRows(_ grid: [[Int]], upTo row: Int) -> Bool {
        for i in 0..<row {
            if grid[i] == grid[row] {
                return true
            }
        }
        return false
    }

    static func areColumnsValid(_ grid: [[Int]]) -> Bool {
        let size = grid.count

        for col in 0..<size {
            var column = [Int]()
            for row in 0..<size {
                column.append(grid[row][col])
            }

            // Verificar regla de no más de dos consecutivos
            if !isValidRow(column) {
                return false
            }

            // Verificar mitad 0s y mitad 1s
            let zeros = column.filter { $0 == 0 }.count
            if zeros != size / 2 {
                return false
            }
        }

        return true
    }

    // MARK: - Validation
    func isValid() -> Bool {
        return gridSize >= 6 && gridSize % 2 == 0
    }

    func isSolved(with userGrid: [[CellState]]) -> Bool {
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let userValue: Int
                switch userGrid[row][col] {
                case .zero: userValue = 0
                case .one: userValue = 1
                case .empty: return false
                }

                if userValue != solution[row][col] {
                    return false
                }
            }
        }
        return true
    }
}

// MARK: - Random Extension
extension SeededRandomGenerator {
    mutating func shuffle<T>(_ array: inout [T]) {
        for i in (1..<array.count).reversed() {
            let j = next(max: i + 1)
            array.swapAt(i, j)
        }
    }
}
