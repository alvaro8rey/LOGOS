//
//  SymmetryPuzzle.swift
//  LOGOS
//
//  Puzzle de Simetría: COMPLETAMENTE REDISEÑADO
//  Patrones SIEMPRE visibles y validación correcta
//

import Foundation

struct SymmetryPuzzle: Codable {
    let seed: String
    let difficulty: Int
    let gridSize: Int
    let solution: [[Bool]]  // true = filled, false = empty
    let initialPattern: [[Bool?]]  // nil = debe completarse, true/false = pista
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
        let types: [SymmetryType] = [.vertical, .horizontal]  // Solo estas por ahora
        self.symmetryType = types[random.next(max: types.count)]

        // Generar MITAD del patrón
        let halfPattern = SymmetryPuzzle.generateHalfPattern(
            gridSize: gridSize,
            difficulty: difficulty,
            type: symmetryType,
            random: &random
        )

        // Aplicar simetría para crear el patrón completo
        self.solution = SymmetryPuzzle.applySymmetry(
            halfPattern: halfPattern,
            type: symmetryType,
            gridSize: gridSize
        )

        // Generar patrón inicial (revelar la mitad)
        self.initialPattern = SymmetryPuzzle.generateInitialPattern(
            solution: solution,
            type: symmetryType,
            gridSize: gridSize
        )
    }

    // MARK: - Generate Half Pattern
    static func generateHalfPattern(
        gridSize: Int,
        difficulty: Int,
        type: SymmetryType,
        random: inout SeededRandomGenerator
    ) -> [[Bool]] {

        var pattern = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)

        // Calcular número de celdas a llenar (solo en la mitad)
        let baseCount = 6  // Mínimo garantizado visible
        let difficultyExtra = difficulty * 3
        let totalCells = baseCount + difficultyExtra

        // Generar posiciones según tipo de simetría
        var positions: [(Int, Int)] = []

        switch type {
        case .vertical:
            // Solo mitad izquierda
            for row in 0..<gridSize {
                for col in 0..<(gridSize / 2) {
                    positions.append((row, col))
                }
            }

        case .horizontal:
            // Solo mitad superior
            for row in 0..<(gridSize / 2) {
                for col in 0..<gridSize {
                    positions.append((row, col))
                }
            }

        case .diagonal:
            // Solo triángulo superior izquierdo
            for row in 0..<gridSize {
                for col in 0...row {
                    positions.append((row, col))
                }
            }

        case .rotational:
            // Solo primer cuadrante + líneas centrales
            for row in 0..<(gridSize / 2) {
                for col in 0..<(gridSize / 2) {
                    positions.append((row, col))
                }
            }
        }

        // Mezclar y seleccionar
        positions.shuffle(using: &random)
        let selectedCount = min(totalCells, positions.count)

        for i in 0..<selectedCount {
            let (row, col) = positions[i]
            pattern[row][col] = true
        }

        return pattern
    }

    // MARK: - Apply Symmetry (CORREGIDO)
    static func applySymmetry(
        halfPattern: [[Bool]],
        type: SymmetryType,
        gridSize: Int
    ) -> [[Bool]] {

        var result = halfPattern

        switch type {
        case .vertical:
            // Reflejar horizontalmente (eje vertical en el centro)
            for row in 0..<gridSize {
                for col in 0..<(gridSize / 2) {
                    let mirrorCol = gridSize - 1 - col
                    result[row][mirrorCol] = halfPattern[row][col]
                }
            }

        case .horizontal:
            // Reflejar verticalmente (eje horizontal en el centro)
            for row in 0..<(gridSize / 2) {
                for col in 0..<gridSize {
                    let mirrorRow = gridSize - 1 - row
                    result[mirrorRow][col] = halfPattern[row][col]
                }
            }

        case .diagonal:
            // Reflejar sobre diagonal principal
            for row in 0..<gridSize {
                for col in 0...row {
                    result[col][row] = halfPattern[row][col]
                }
            }

        case .rotational:
            // Rotar 180 grados
            for row in 0..<gridSize {
                for col in 0..<gridSize {
                    let mirrorRow = gridSize - 1 - row
                    let mirrorCol = gridSize - 1 - col
                    result[mirrorRow][mirrorCol] = halfPattern[row][col]
                }
            }
        }

        return result
    }

    // MARK: - Generate Initial Pattern
    static func generateInitialPattern(
        solution: [[Bool]],
        type: SymmetryType,
        gridSize: Int
    ) -> [[Bool?]] {

        var initialPattern = Array(repeating: Array(repeating: Bool?.none, count: gridSize), count: gridSize)

        switch type {
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

        case .diagonal:
            // Revelar triángulo superior izquierdo
            for row in 0..<gridSize {
                for col in 0...min(row, gridSize - 1) {
                    initialPattern[row][col] = solution[row][col]
                }
            }

        case .rotational:
            // Revelar cuadrante superior izquierdo
            for row in 0..<(gridSize / 2) {
                for col in 0..<(gridSize / 2) {
                    initialPattern[row][col] = solution[row][col]
                }
            }
        }

        return initialPattern
    }

    // MARK: - Validation
    func isValid() -> Bool {
        return gridSize >= 8 && gridSize % 2 == 0
    }

    func isSolved(with userGrid: [[CellState]]) -> Bool {
        // Solo verificar las celdas que el usuario debe completar (initialPattern = nil)
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                // Si es celda inicial (pista), ignorar
                if initialPattern[row][col] != nil {
                    continue
                }

                // Verificar celda del usuario
                let userFilled = userGrid[row][col] == .filled
                let solutionFilled = solution[row][col]

                if userFilled != solutionFilled {
                    return false
                }
            }
        }

        return true
    }

    // MARK: - Helper: Get hint positions
    func getHintPositions() -> [(Int, Int)] {
        var hints: [(Int, Int)] = []
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if initialPattern[row][col] != nil {
                    hints.append((row, col))
                }
            }
        }
        return hints
    }

    // MARK: - Helper: Get cells to complete
    func getCellsToComplete() -> [(Int, Int)] {
        var cells: [(Int, Int)] = []
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if initialPattern[row][col] == nil {
                    cells.append((row, col))
                }
            }
        }
        return cells
    }
}
