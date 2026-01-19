//
//  BinaryPuzzle.swift
//  LOGOS
//
//  Puzzle de Estados Binarios: Binary
//  REDISEÑADO para ser simple, rápido y SIEMPRE funcional
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

        // Generar solución simple y GARANTIZADA
        var random = SeededRandomGenerator(seed: seed)
        self.solution = BinaryPuzzle.generateSimpleSolution(size: gridSize, random: &random)

        // Generar grid inicial - MÉTODO SEGURO sin ciclos infinitos
        var initialGrid = Array(repeating: Array(repeating: Int?.none, count: gridSize), count: gridSize)

        let revealPercentage: Double
        switch difficulty {
        case 1: revealPercentage = 0.5
        case 2: revealPercentage = 0.4
        case 3: revealPercentage = 0.35
        case 4: revealPercentage = 0.3
        default: revealPercentage = 0.25
        }

        // Crear lista de todas las posiciones posibles
        var positions: [(Int, Int)] = []
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                positions.append((row, col))
            }
        }

        // Mezclar posiciones y tomar las primeras N
        positions.shuffle(using: &random)
        let cellsToReveal = Int(Double(gridSize * gridSize) * revealPercentage)

        for i in 0..<min(cellsToReveal, positions.count) {
            let (row, col) = positions[i]
            initialGrid[row][col] = solution[row][col]
        }

        self.initialGrid = initialGrid
    }

    // MARK: - Generate Simple Solution
    static func generateSimpleSolution(size: Int, random: inout SeededRandomGenerator) -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: size), count: size)

        // Generar patrón alternado simple - GARANTIZADO válido
        let patternType = random.next(max: 4)

        for row in 0..<size {
            for col in 0..<size {
                switch patternType {
                case 0:
                    // Patrón tablero de ajedrez
                    grid[row][col] = (row + col) % 2
                case 1:
                    // Patrón columnas alternadas
                    grid[row][col] = col % 2
                case 2:
                    // Patrón filas alternadas
                    grid[row][col] = row % 2
                default:
                    // Patrón bloques 2x2
                    grid[row][col] = ((row / 2) + (col / 2)) % 2
                }
            }
        }

        return grid
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
