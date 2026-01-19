//
//  SudokuPuzzle.swift
//  LOGOS
//
//  Puzzle Lógico Extremo: Sudoku 9x9
//  El puzzle más difícil - requiere lógica pura y deducción
//

import Foundation

struct SudokuPuzzle: Codable {
    let seed: String
    let difficulty: Int
    let gridSize: Int = 9
    let solution: [[Int]]
    let initialGrid: [[Int]]  // Grid con algunos números pre-llenados

    init(seed: String, difficulty: Int) {
        self.seed = seed
        self.difficulty = difficulty

        var random = SeededRandomGenerator(seed: seed)
        let result = SudokuPuzzle.generatePuzzle(difficulty: difficulty, random: &random)

        self.solution = result.solution
        self.initialGrid = result.initialGrid
    }

    // MARK: - Generate Puzzle
    static func generatePuzzle(
        difficulty: Int,
        random: inout SeededRandomGenerator
    ) -> (solution: [[Int]], initialGrid: [[Int]]) {

        // 1. Generar una solución válida completa
        var solution = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        fillSudoku(grid: &solution, random: &random)

        // 2. Crear grid inicial removiendo números según dificultad
        var initialGrid = solution

        // Número de celdas a remover según dificultad
        let cellsToRemove: Int
        switch difficulty {
        case 1: cellsToRemove = 35  // Fácil: 46 números visibles
        case 2: cellsToRemove = 42  // Medio: 39 números visibles
        case 3: cellsToRemove = 48  // Difícil: 33 números visibles
        case 4: cellsToRemove = 54  // Experto: 27 números visibles
        default: cellsToRemove = 60 // Maestro: 21 números visibles (EXTREMO)
        }

        // Remover números manteniendo simetría
        var removed = 0
        var attempts = 0
        let maxAttempts = 1000

        while removed < cellsToRemove && attempts < maxAttempts {
            let row = random.next(max: 9)
            let col = random.next(max: 9)

            // Si ya está removido, continuar
            if initialGrid[row][col] == 0 {
                attempts += 1
                continue
            }

            // Remover el número
            initialGrid[row][col] = 0
            removed += 1

            // Simetría rotacional (opcional para estética)
            let symRow = 8 - row
            let symCol = 8 - col
            if initialGrid[symRow][symCol] != 0 && removed < cellsToRemove {
                initialGrid[symRow][symCol] = 0
                removed += 1
            }

            attempts += 1
        }

        return (solution: solution, initialGrid: initialGrid)
    }

    // MARK: - Fill Sudoku (Backtracking)
    private static func fillSudoku(grid: inout [[Int]], random: inout SeededRandomGenerator) -> Bool {
        // Encontrar celda vacía
        var emptyRow = -1
        var emptyCol = -1

        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == 0 {
                    emptyRow = row
                    emptyCol = col
                    break
                }
            }
            if emptyRow != -1 { break }
        }

        // Si no hay celdas vacías, el sudoku está completo
        if emptyRow == -1 {
            return true
        }

        // Intentar números del 1-9 en orden aleatorio
        var numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]
        numbers.shuffle(using: &random)

        for num in numbers {
            if isValidPlacement(grid: grid, row: emptyRow, col: emptyCol, num: num) {
                grid[emptyRow][emptyCol] = num

                if fillSudoku(grid: &grid, random: &random) {
                    return true
                }

                // Backtrack
                grid[emptyRow][emptyCol] = 0
            }
        }

        return false
    }

    // MARK: - Validation
    private static func isValidPlacement(grid: [[Int]], row: Int, col: Int, num: Int) -> Bool {
        // Verificar fila
        for c in 0..<9 {
            if grid[row][c] == num {
                return false
            }
        }

        // Verificar columna
        for r in 0..<9 {
            if grid[r][col] == num {
                return false
            }
        }

        // Verificar cuadrante 3x3
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3

        for r in boxRow..<boxRow + 3 {
            for c in boxCol..<boxCol + 3 {
                if grid[r][c] == num {
                    return false
                }
            }
        }

        return true
    }

    // MARK: - Public Validation
    func isValid() -> Bool {
        return gridSize == 9
    }

    func isSolved(with userGrid: [[Int]]) -> Bool {
        // Verificar que todas las celdas estén llenas
        for row in 0..<9 {
            for col in 0..<9 {
                if userGrid[row][col] == 0 {
                    return false
                }
            }
        }

        // Verificar cada fila
        for row in 0..<9 {
            var seen = Set<Int>()
            for col in 0..<9 {
                let num = userGrid[row][col]
                if num < 1 || num > 9 || seen.contains(num) {
                    return false
                }
                seen.insert(num)
            }
        }

        // Verificar cada columna
        for col in 0..<9 {
            var seen = Set<Int>()
            for row in 0..<9 {
                let num = userGrid[row][col]
                if num < 1 || num > 9 || seen.contains(num) {
                    return false
                }
                seen.insert(num)
            }
        }

        // Verificar cada cuadrante 3x3
        for boxRow in 0..<3 {
            for boxCol in 0..<3 {
                var seen = Set<Int>()
                for r in 0..<3 {
                    for c in 0..<3 {
                        let num = userGrid[boxRow * 3 + r][boxCol * 3 + c]
                        if num < 1 || num > 9 || seen.contains(num) {
                            return false
                        }
                        seen.insert(num)
                    }
                }
            }
        }

        return true
    }

    // MARK: - Helper: Check if cell is pre-filled
    func isInitialCell(row: Int, col: Int) -> Bool {
        return initialGrid[row][col] != 0
    }

    // MARK: - Helper: Get conflicts for a cell
    func hasConflict(in userGrid: [[Int]], row: Int, col: Int) -> Bool {
        let num = userGrid[row][col]

        // Si está vacío, no hay conflicto
        if num == 0 {
            return false
        }

        // Verificar fila
        for c in 0..<9 {
            if c != col && userGrid[row][c] == num {
                return true
            }
        }

        // Verificar columna
        for r in 0..<9 {
            if r != row && userGrid[r][col] == num {
                return true
            }
        }

        // Verificar cuadrante 3x3
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3

        for r in boxRow..<boxRow + 3 {
            for c in boxCol..<boxCol + 3 {
                if (r != row || c != col) && userGrid[r][c] == num {
                    return true
                }
            }
        }

        return false
    }
}
