//
//  SymmetryPuzzle.swift
//  LOGOS
//
//  Puzzle de Simetría: Completar patrones simétricos
//

import Foundation

struct SymmetryPuzzle: Codable {
    let seed: String
    let difficulty: Int
    let gridSize: Int
    let solution: [[Bool]]  // true = filled, false = empty
    let initialPattern: [[Bool?]]  // nil = vacío, debe ser completado
    let symmetryType: SymmetryType

    enum SymmetryType: String, Codable {
        case vertical = "vertical"
        case horizontal = "horizontal"
        case diagonal = "diagonal"
        case rotational = "rotational"

        var displayName: String {
            switch self {
            case .vertical: return "Simetría Vertical"
            case .horizontal: return "Simetría Horizontal"
            case .diagonal: return "Simetría Diagonal"
            case .rotational: return "Simetría Rotacional"
            }
        }
    }

    enum CellState: Codable, Equatable {
        case empty
        case filled
        case marked
    }

    // MARK: - Initialization
    init(seed: String, difficulty: Int) {
        self.seed = seed
        self.difficulty = difficulty

        switch difficulty {
        case 1: self.gridSize = 8
        case 2: self.gridSize = 10
        case 3: self.gridSize = 12
        case 4: self.gridSize = 14
        default: self.gridSize = 16
        }

        // Tipo de simetría aleatorio
        var random = SeededRandomGenerator(seed: seed)
        let types: [SymmetryType] = [.vertical, .horizontal, .diagonal, .rotational]
        self.symmetryType = types[random.next(max: types.count)]

        // Generar patrón base con MEJOR DENSIDAD
        var pattern = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)

        // Aumentar densidad base para que siempre haya patrón visible
        let patternDensity = 0.15 + (Double(difficulty) * 0.03)  // Más conservador
        let cellsToFill = max(Int(Double(gridSize * gridSize / 4) * patternDensity), 3)  // Mínimo 3 celdas

        // Generar patrón en la mitad del tablero
        var filledCount = 0
        var attempts = 0
        while filledCount < cellsToFill && attempts < cellsToFill * 3 {
            let row = random.next(max: gridSize / 2)
            let col = random.next(max: gridSize / 2)
            if !pattern[row][col] {
                pattern[row][col] = true
                filledCount += 1
            }
            attempts += 1
        }

        // Aplicar simetría
        self.solution = SymmetryPuzzle.applySymmetry(to: pattern, type: symmetryType)

        // Generar patrón inicial (mitad revelada)
        var initialPattern = Array(repeating: Array(repeating: Bool?.none, count: gridSize), count: gridSize)

        switch symmetryType {
        case .vertical:
            // Revelar mitad izquierda
            for row in 0..<gridSize {
                for col in 0..<(gridSize / 2) {
                    initialPattern[row][col] = solution[row][col]
                }
            }
        case .horizontal:
            // Revelar mitad superior
            for row in 0..<(gridSize / 2) {
                for col in 0..<gridSize {
                    initialPattern[row][col] = solution[row][col]
                }
            }
        case .diagonal, .rotational:
            // Revelar cuadrante superior izquierdo
            for row in 0..<(gridSize / 2) {
                for col in 0..<(gridSize / 2) {
                    initialPattern[row][col] = solution[row][col]
                }
            }
        }

        self.initialPattern = initialPattern
    }

    // MARK: - Apply Symmetry
    static func applySymmetry(to pattern: [[Bool]], type: SymmetryType) -> [[Bool]] {
        let size = pattern.count
        var result = pattern

        switch type {
        case .vertical:
            for row in 0..<size {
                for col in 0..<size {
                    result[row][size - 1 - col] = pattern[row][col]
                }
            }
        case .horizontal:
            for row in 0..<size {
                for col in 0..<size {
                    result[size - 1 - row][col] = pattern[row][col]
                }
            }
        case .diagonal:
            for row in 0..<size {
                for col in 0..<size {
                    result[col][row] = pattern[row][col]
                }
            }
        case .rotational:
            for row in 0..<size {
                for col in 0..<size {
                    result[size - 1 - row][size - 1 - col] = pattern[row][col]
                }
            }
        }

        return result
    }

    // MARK: - Validation
    func isValid() -> Bool {
        return gridSize >= 8 && gridSize % 2 == 0
    }

    func isSolved(with userGrid: [[CellState]]) -> Bool {
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let userFilled = userGrid[row][col] == .filled
                if userFilled != solution[row][col] {
                    return false
                }
            }
        }
        return true
    }
}
