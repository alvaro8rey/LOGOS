//
//  LightsOutPuzzle.swift
//  LOGOS
//
//  Puzzle Extremo: Lights Out (Luces Fuera)
//  Uno de los puzzles más difíciles - requiere pensamiento estratégico
//

import Foundation

struct LightsOutPuzzle: Codable {
    let seed: String
    let difficulty: Int
    let gridSize: Int
    let initialState: [[Bool]]
    let solution: [(row: Int, col: Int)]

    init(seed: String, difficulty: Int) {
        self.seed = seed
        self.difficulty = difficulty

        // Tamaño según dificultad
        switch difficulty {
        case 1: self.gridSize = 3
        case 2: self.gridSize = 4
        case 3: self.gridSize = 5
        case 4: self.gridSize = 6
        default: self.gridSize = 7  // EXTREMADAMENTE DIFÍCIL
        }

        var random = SeededRandomGenerator(seed: seed)
        let result = LightsOutPuzzle.generatePuzzle(gridSize: gridSize, random: &random)

        self.initialState = result.initialState
        self.solution = result.solution
    }

    // MARK: - Generate Puzzle
    static func generatePuzzle(
        gridSize: Int,
        random: inout SeededRandomGenerator
    ) -> (initialState: [[Bool]], solution: [(row: Int, col: Int)]) {

        // Empezar con todas las luces apagadas
        var grid = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)

        // Generar una solución (secuencia de movimientos)
        var solution: [(row: Int, col: Int)] = []

        // Número de movimientos según dificultad
        let moveCount = random.next(max: gridSize * 2) + gridSize

        for _ in 0..<moveCount {
            let row = random.next(max: gridSize)
            let col = random.next(max: gridSize)

            solution.append((row, col))

            // Aplicar el toggle
            toggleLight(grid: &grid, row: row, col: col, gridSize: gridSize)
        }

        return (initialState: grid, solution: solution)
    }

    // MARK: - Toggle Light
    private static func toggleLight(grid: inout [[Bool]], row: Int, col: Int, gridSize: Int) {
        // Toggle la celda actual
        grid[row][col].toggle()

        // Toggle vecinos (arriba, abajo, izquierda, derecha)
        let directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]

        for (dr, dc) in directions {
            let newRow = row + dr
            let newCol = col + dc

            if newRow >= 0 && newRow < gridSize &&
               newCol >= 0 && newCol < gridSize {
                grid[newRow][newCol].toggle()
            }
        }
    }

    // MARK: - Public Toggle
    func toggle(grid: inout [[Bool]], row: Int, col: Int) {
        LightsOutPuzzle.toggleLight(grid: &grid, row: row, col: col, gridSize: gridSize)
    }

    // MARK: - Validation
    func isValid() -> Bool {
        return gridSize >= 3
    }

    func isSolved(with grid: [[Bool]]) -> Bool {
        // Todas las luces deben estar apagadas (false)
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if grid[row][col] {
                    return false
                }
            }
        }
        return true
    }
}
