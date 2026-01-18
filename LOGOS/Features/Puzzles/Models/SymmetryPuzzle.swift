//
//  SymmetryPuzzle.swift
//  LOGOS
//
//  Puzzle de Simetría: COMPLETAMENTE REDISEÑADO
//  Patrones SIEMPRE visibles y complejidad escalable por dificultad
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

        // Tamaño escalable según dificultad
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

        // Generar MITAD del patrón con complejidad según dificultad
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

    // MARK: - Generate Half Pattern (MEJORADO CON COMPLEJIDAD)
    static func generateHalfPattern(
        gridSize: Int,
        difficulty: Int,
        type: SymmetryType,
        random: inout SeededRandomGenerator
    ) -> [[Bool]] {

        var pattern = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)

        // Complejidad escalable: más celdas = más difícil
        let baseCount = 8  // Mínimo visible
        let difficultyMultiplier = 4  // Más agresivo
        let totalCells = baseCount + (difficulty * difficultyMultiplier)

        // Calcular área disponible según tipo de simetría
        let availableArea: Int
        switch type {
        case .vertical:
            availableArea = gridSize * (gridSize / 2)
        case .horizontal:
            availableArea = (gridSize / 2) * gridSize
        case .diagonal:
            availableArea = (gridSize * (gridSize + 1)) / 2
        case .rotational:
            availableArea = (gridSize / 2) * (gridSize / 2)
        }

        // Ajustar totalCells para no exceder área disponible
        let adjustedTotal = min(totalCells, availableArea / 2)

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

        // Crear PATRONES más complejos basados en dificultad
        if difficulty >= 3 {
            // Dificultad alta: Patrones geométricos
            pattern = generateGeometricPattern(gridSize: gridSize, type: type, random: &random)
        } else if difficulty == 2 {
            // Dificultad media: Patrones semi-aleatorios con clustering
            positions.shuffle(using: &random)
            var filledCount = 0
            for (row, col) in positions {
                if filledCount >= adjustedTotal { break }
                pattern[row][col] = true

                // 40% probabilidad de llenar vecinos (clustering)
                if random.next(max: 100) < 40 && filledCount < adjustedTotal - 1 {
                    let neighbors = getNeighbors(row: row, col: col, gridSize: gridSize, type: type)
                    if let (nRow, nCol) = neighbors.randomElement(using: &random), !pattern[nRow][nCol] {
                        pattern[nRow][nCol] = true
                        filledCount += 1
                    }
                }
                filledCount += 1
            }
        } else {
            // Dificultad baja: Aleatorio simple
            positions.shuffle(using: &random)
            for i in 0..<min(adjustedTotal, positions.count) {
                let (row, col) = positions[i]
                pattern[row][col] = true
            }
        }

        return pattern
    }

    // MARK: - Generate Geometric Pattern
    static func generateGeometricPattern(
        gridSize: Int,
        type: SymmetryType,
        random: inout SeededRandomGenerator
    ) -> [[Bool]] {
        var pattern = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)

        let patternType = random.next(max: 3)

        switch patternType {
        case 0:
            // Diagonal lines
            for row in 0..<gridSize {
                for col in 0..<gridSize {
                    if (row + col) % 3 == 0 && shouldFillForSymmetry(row: row, col: col, gridSize: gridSize, type: type) {
                        pattern[row][col] = true
                    }
                }
            }
        case 1:
            // Concentric squares
            let center = gridSize / 2
            for row in 0..<gridSize {
                for col in 0..<gridSize {
                    let distance = max(abs(row - center), abs(col - center))
                    if distance % 2 == 0 && shouldFillForSymmetry(row: row, col: col, gridSize: gridSize, type: type) {
                        pattern[row][col] = true
                    }
                }
            }
        default:
            // Checkerboard variant
            for row in 0..<gridSize {
                for col in 0..<gridSize {
                    if (row % 2 == col % 2) && shouldFillForSymmetry(row: row, col: col, gridSize: gridSize, type: type) {
                        pattern[row][col] = true
                    }
                }
            }
        }

        return pattern
    }

    // MARK: - Helper: Should Fill For Symmetry
    static func shouldFillForSymmetry(row: Int, col: Int, gridSize: Int, type: SymmetryType) -> Bool {
        switch type {
        case .vertical:
            return col < gridSize / 2
        case .horizontal:
            return row < gridSize / 2
        case .diagonal:
            return row >= col
        case .rotational:
            return row < gridSize / 2 && col < gridSize / 2
        }
    }

    // MARK: - Helper: Get Neighbors
    static func getNeighbors(row: Int, col: Int, gridSize: Int, type: SymmetryType) -> [(Int, Int)] {
        var neighbors: [(Int, Int)] = []
        let directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]

        for (dr, dc) in directions {
            let newRow = row + dr
            let newCol = col + dc

            if newRow >= 0 && newRow < gridSize && newCol >= 0 && newCol < gridSize {
                if shouldFillForSymmetry(row: newRow, col: newCol, gridSize: gridSize, type: type) {
                    neighbors.append((newRow, newCol))
                }
            }
        }

        return neighbors
    }

    // MARK: - Apply Symmetry
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
