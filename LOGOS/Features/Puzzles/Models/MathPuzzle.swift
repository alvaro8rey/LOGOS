//
//  MathPuzzle.swift
//  LOGOS
//
//  Puzzle Matemático REDISEÑADO: KenKen Simplificado
//  Solo necesitas cumplir las operaciones de cada jaula
//

import Foundation

struct MathPuzzle: Codable {
    let seed: String
    let difficulty: Int
    let gridSize: Int
    let solution: [[Int]]
    let cages: [Cage]

    struct CellPosition: Equatable, Codable, Hashable {
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
            case none = "="

            var symbol: String { return self.rawValue }

            var displayName: String {
                switch self {
                case .add: return "Suma"
                case .subtract: return "Resta"
                case .multiply: return "Multiplicación"
                case .divide: return "División"
                case .none: return "Igual"
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
        case 4: self.gridSize = 7
        default: self.gridSize = 8
        }

        var random = SeededRandomGenerator(seed: seed)

        // Generar solución válida (Latin Square - cada fila y columna sin repetir)
        var solution = Array(repeating: Array(repeating: 0, count: gridSize), count: gridSize)

        // Método mejorado: shuffle de primera fila, luego rotar
        var firstRow = Array(1...gridSize)
        firstRow.shuffle(using: &random)

        for row in 0..<gridSize {
            for col in 0..<gridSize {
                solution[row][col] = firstRow[(col + row) % gridSize]
            }
        }

        self.solution = solution

        // Generar jaulas con algoritmo mejorado
        let result = MathPuzzle.generateCages(
            solution: solution,
            gridSize: gridSize,
            difficulty: difficulty,
            random: &random
        )

        self.cages = result
    }

    // MARK: - Generate Cages (ALGORITMO MEJORADO)
    static func generateCages(
        solution: [[Int]],
        gridSize: Int,
        difficulty: Int,
        random: inout SeededRandomGenerator
    ) -> [Cage] {

        var cages: [Cage] = []
        var used = Set<CellPosition>()

        // Estrategia: crear jaulas de diferentes tamaños
        // Más dificultad = jaulas más grandes
        let maxCageSize: Int
        switch difficulty {
        case 1: maxCageSize = 2  // Solo pares
        case 2: maxCageSize = 2  // Pares y algunos triples
        case 3: maxCageSize = 3  // Hasta 3 celdas
        case 4: maxCageSize = 4  // Hasta 4 celdas
        default: maxCageSize = 5 // Hasta 5 celdas - MUY difícil
        }

        // Llenar todo el grid con jaulas
        while used.count < gridSize * gridSize {
            // Encontrar una celda no usada
            var startRow = -1
            var startCol = -1

            for row in 0..<gridSize {
                for col in 0..<gridSize {
                    let pos = CellPosition(row: row, col: col)
                    if !used.contains(pos) {
                        startRow = row
                        startCol = col
                        break
                    }
                }
                if startRow != -1 { break }
            }

            guard startRow != -1 else { break }

            // Decidir tamaño de jaula (70% pequeñas, 30% grandes)
            let targetSize: Int
            if random.next(max: 100) < 70 {
                targetSize = random.next(max: 2) + 1  // 1-2 celdas
            } else {
                targetSize = random.next(max: maxCageSize - 1) + 2  // 2 a maxCageSize
            }

            // Construir jaula usando flood fill limitado
            var cageCells: [(Int, Int)] = [(startRow, startCol)]
            var visited = Set<CellPosition>()
            visited.insert(CellPosition(row: startRow, col: startCol))

            // Expandir jaula
            var attempts = 0
            while cageCells.count < targetSize && attempts < 20 {
                // Elegir una celda al azar de las actuales
                guard let baseCell = cageCells.randomElement(using: &random) else { break }

                // Intentar agregar vecino
                let directions = [(0, 1), (1, 0), (0, -1), (-1, 0)]
                directions.shuffle(using: &random)

                var added = false
                for (dr, dc) in directions {
                    let newRow = baseCell.0 + dr
                    let newCol = baseCell.1 + dc
                    let newPos = CellPosition(row: newRow, col: newCol)

                    if newRow >= 0 && newRow < gridSize &&
                       newCol >= 0 && newCol < gridSize &&
                       !used.contains(newPos) &&
                       !visited.contains(newPos) {
                        cageCells.append((newRow, newCol))
                        visited.insert(newPos)
                        added = true
                        break
                    }
                }

                if !added {
                    attempts += 1
                }
            }

            // Marcar celdas como usadas
            for cell in cageCells {
                used.insert(CellPosition(row: cell.0, col: cell.1))
            }

            // Calcular operación y target
            let values = cageCells.map { solution[$0.0][$0.1] }
            let (target, operation) = calculateOperation(
                values: values,
                difficulty: difficulty,
                random: &random
            )

            cages.append(Cage(cells: cageCells, target: target, operation: operation))
        }

        return cages
    }

    // MARK: - Calculate Operation
    static func calculateOperation(
        values: [Int],
        difficulty: Int,
        random: inout SeededRandomGenerator
    ) -> (target: Int, operation: Cage.Operation) {

        if values.count == 1 {
            return (values[0], .none)
        }

        // Operaciones disponibles según dificultad
        var availableOps: [Cage.Operation] = [.add, .multiply]

        if difficulty >= 2 && values.count == 2 {
            availableOps.append(.subtract)
        }

        if difficulty >= 3 && values.count == 2 {
            // División solo si es exacta
            let sorted = values.sorted(by: >)
            if sorted[0] % sorted[1] == 0 {
                availableOps.append(.divide)
            }
        }

        let operation = availableOps[random.next(max: availableOps.count)]

        let target: Int
        switch operation {
        case .add:
            target = values.reduce(0, +)
        case .multiply:
            target = values.reduce(1, *)
        case .subtract:
            let sorted = values.sorted(by: >)
            target = sorted[0] - sorted[1]
        case .divide:
            let sorted = values.sorted(by: >)
            target = sorted[0] / sorted[1]
        case .none:
            target = values[0]
        }

        return (target, operation)
    }

    // MARK: - Validation
    func isValid() -> Bool {
        return gridSize >= 4 && !cages.isEmpty
    }

    func isSolved(with userGrid: [[Int]]) -> Bool {
        // 1. Verificar que todas las celdas estén llenas
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if userGrid[row][col] == 0 {
                    return false
                }

                // Verificar rango válido
                if userGrid[row][col] < 1 || userGrid[row][col] > gridSize {
                    return false
                }
            }
        }

        // 2. Verificar que cada fila tenga números únicos
        for row in 0..<gridSize {
            let rowValues = userGrid[row]
            if Set(rowValues).count != gridSize {
                return false
            }
        }

        // 3. Verificar que cada columna tenga números únicos
        for col in 0..<gridSize {
            let colValues = (0..<gridSize).map { userGrid[$0][col] }
            if Set(colValues).count != gridSize {
                return false
            }
        }

        // 4. Verificar jaulas
        for cage in cages {
            let values = cage.cells.map { userGrid[$0.row][$0.col] }

            let result: Int
            switch cage.operation {
            case .add:
                result = values.reduce(0, +)
            case .multiply:
                result = values.reduce(1, *)
            case .subtract:
                let sorted = values.sorted(by: >)
                result = sorted[0] - sorted[1]
            case .divide:
                let sorted = values.sorted(by: >)
                result = sorted[1] == 0 ? 0 : sorted[0] / sorted[1]
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

    // MARK: - Helper: Check if number conflicts
    func hasConflict(in userGrid: [[Int]], row: Int, col: Int) -> Bool {
        let value = userGrid[row][col]

        guard value > 0 else { return false }

        // Verificar fila
        for c in 0..<gridSize {
            if c != col && userGrid[row][c] == value {
                return true
            }
        }

        // Verificar columna
        for r in 0..<gridSize {
            if r != row && userGrid[r][col] == value {
                return true
            }
        }

        return false
    }
}
