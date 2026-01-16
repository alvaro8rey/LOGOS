//
//  NonogramPuzzle.swift
//  Logos
//
//  Puzzle tipo Nonogram (Constraint Satisfaction) - CORREGIDO
//

import Foundation

struct NonogramPuzzle: Puzzle {
    let id: String
    let seed: String
    let difficulty: Int
    let createdAt: Date
    
    // Puzzle data
    let gridSize: Int
    let solution: [[Bool]] // true = filled, false = empty
    let rowHints: [[Int]]
    let columnHints: [[Int]]
    
    // MARK: - Computed Property (sin initial value en la declaración)
    var puzzleType: UserProgress.PuzzleType {
        return .constraints
    }
    
    init(seed: String, difficulty: Int) {
        self.id = UUID().uuidString
        self.seed = seed
        self.difficulty = difficulty
        self.createdAt = Date()
        
        // Determinar tamaño basado en dificultad
        switch difficulty {
        case 1: self.gridSize = 5
        case 2: self.gridSize = 7
        case 3: self.gridSize = 10
        case 4: self.gridSize = 12
        default: self.gridSize = 15
        }
        
        // Generar puzzle
        let generator = NonogramGenerator(seed: seed, size: gridSize)
        self.solution = generator.solution
        self.rowHints = generator.rowHints
        self.columnHints = generator.columnHints
    }
    
    func isValid() -> Bool {
        // Verificar que las pistas correspondan a la solución
        return NonogramValidator.validate(
            solution: solution,
            rowHints: rowHints,
            columnHints: columnHints
        )
    }
    
    func isSolved(with userSolution: Any) -> Bool {
        guard let grid = userSolution as? [[CellState]] else {
            return false
        }
        
        // Convertir CellState a Bool y comparar
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let shouldBeFilled = solution[row][col]
                let isFilled = grid[row][col] == .filled
                
                if shouldBeFilled != isFilled {
                    return false
                }
            }
        }
        
        return true
    }
    
    // MARK: - Cell State
    enum CellState: Codable {
        case empty
        case filled
        case marked // Marcado como vacío por el usuario
    }
}

// MARK: - Nonogram Generator
struct NonogramGenerator {
    let seed: String
    let size: Int
    let solution: [[Bool]]
    let rowHints: [[Int]]
    let columnHints: [[Int]]
    
    init(seed: String, size: Int) {
        self.seed = seed
        self.size = size
        
        // Usar seed para generar números pseudoaleatorios consistentes
        var rng = SeededRandomNumberGenerator(seed: seed)
        
        // Generar solución con densidad basada en tamaño
        let density: Double = size <= 5 ? 0.6 : (size <= 10 ? 0.5 : 0.4)
        var grid = [[Bool]]()
        
        for _ in 0..<size {
            var row = [Bool]()
            for _ in 0..<size {
                row.append(Double.random(in: 0...1, using: &rng) < density)
            }
            grid.append(row)
        }
        
        self.solution = grid
        
        // Calcular pistas para filas
        var rows = [[Int]]()
        for row in grid {
            rows.append(Self.calculateHints(for: row))
        }
        self.rowHints = rows
        
        // Calcular pistas para columnas
        var cols = [[Int]]()
        for col in 0..<size {
            var column = [Bool]()
            for row in 0..<size {
                column.append(grid[row][col])
            }
            cols.append(Self.calculateHints(for: column))
        }
        self.columnHints = cols
    }
    
    // CAMBIADO DE PRIVATE A STATIC INTERNAL
    static func calculateHints(for line: [Bool]) -> [Int] {
        var hints = [Int]()
        var currentGroup = 0
        
        for cell in line {
            if cell {
                currentGroup += 1
            } else if currentGroup > 0 {
                hints.append(currentGroup)
                currentGroup = 0
            }
        }
        
        if currentGroup > 0 {
            hints.append(currentGroup)
        }
        
        return hints.isEmpty ? [0] : hints
    }
}

// MARK: - Nonogram Validator
struct NonogramValidator {
    static func validate(
        solution: [[Bool]],
        rowHints: [[Int]],
        columnHints: [[Int]]
    ) -> Bool {
        let size = solution.count
        
        // Validar filas
        for (index, row) in solution.enumerated() {
            let calculatedHints = NonogramGenerator.calculateHints(for: row)
            if calculatedHints != rowHints[index] {
                return false
            }
        }
        
        // Validar columnas
        for col in 0..<size {
            var column = [Bool]()
            for row in 0..<size {
                column.append(solution[row][col])
            }
            let calculatedHints = NonogramGenerator.calculateHints(for: column)
            if calculatedHints != columnHints[col] {
                return false
            }
        }
        
        return true
    }
}

// MARK: - Seeded Random Number Generator
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: String) {
        // Convertir seed string a número
        var hasher = Hasher()
        hasher.combine(seed)
        self.state = UInt64(abs(hasher.finalize()))
    }
    
    mutating func next() -> UInt64 {
        // Linear Congruential Generator
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
