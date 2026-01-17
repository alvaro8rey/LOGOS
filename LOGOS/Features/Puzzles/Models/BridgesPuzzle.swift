//
//  BridgesPuzzle.swift
//  LOGOS
//
//  Puzzle de Grafos: Bridges (Hashiwokakero)
//  Conectar islas con puentes siguiendo las reglas
//

import Foundation

struct BridgesPuzzle: Codable {
    let seed: String
    let difficulty: Int
    let gridSize: Int
    let islands: [Island]

    // MARK: - Island
    struct Island: Codable, Identifiable {
        let id: String
        let row: Int
        let col: Int
        let requiredBridges: Int

        init(row: Int, col: Int, requiredBridges: Int) {
            self.id = UUID().uuidString
            self.row = row
            self.col = col
            self.requiredBridges = requiredBridges
        }
    }

    // MARK: - Bridge
    struct Bridge: Codable, Identifiable {
        let id: String
        let from: String  // Island ID
        let to: String    // Island ID
        let count: Int    // 1 o 2 puentes
        let isHorizontal: Bool

        init(from: String, to: String, count: Int, isHorizontal: Bool) {
            self.id = UUID().uuidString
            self.from = from
            self.to = to
            self.count = count
            self.isHorizontal = isHorizontal
        }
    }

    // MARK: - Initialization
    init(seed: String, difficulty: Int) {
        self.seed = seed
        self.difficulty = difficulty

        // Tamaño según dificultad
        switch difficulty {
        case 1: self.gridSize = 7
        case 2: self.gridSize = 9
        case 3: self.gridSize = 11
        case 4: self.gridSize = 13
        default: self.gridSize = 15
        }

        // Generar islas en GRID para garantizar alineación
        var random = SeededRandomGenerator(seed: seed)
        let islandCount = 5 + difficulty
        var islands: [Island] = []

        // Crear posiciones de islas espaciadas uniformemente
        let spacing = max(2, gridSize / (islandCount / 2))
        var usedPositions = Set<String>()

        // Generar islas en posiciones de grid
        var row = 1
        var col = 1
        var generatedCount = 0

        while generatedCount < islandCount && row < gridSize - 1 {
            col = 1
            while col < gridSize - 1 && generatedCount < islandCount {
                // Probabilidad de colocar isla en esta posición
                if random.next(max: 100) < 60 {  // 60% probabilidad
                    let positionKey = "\(row),\(col)"
                    if !usedPositions.contains(positionKey) {
                        usedPositions.insert(positionKey)

                        // Contar islas alineadas horizontalmente y verticalmente
                        let horizontalCount = islands.filter { $0.row == row }.count
                        let verticalCount = islands.filter { $0.col == col }.count
                        let alignedCount = horizontalCount + verticalCount

                        // Asignar número de puentes basado en alineación (2-4)
                        let bridges = min(max(2, alignedCount + 1), 4)
                        islands.append(Island(row: row, col: col, requiredBridges: bridges))
                        generatedCount += 1
                    }
                }
                col += spacing
            }
            row += spacing
        }

        // Si no generamos suficientes, llenar con posiciones aleatorias
        while islands.count < islandCount {
            let r = random.next(max: gridSize - 2) + 1
            let c = random.next(max: gridSize - 2) + 1
            let key = "\(r),\(c)"
            if !usedPositions.contains(key) {
                usedPositions.insert(key)
                islands.append(Island(row: r, col: c, requiredBridges: 2))
            }
        }

        self.islands = islands
    }

    // MARK: - Validation
    func isValid() -> Bool {
        return islands.count >= 5
    }

    func isSolved(with bridges: [Bridge]) -> Bool {
        // Verificar que cada isla tenga el número correcto de puentes
        for island in islands {
            let connectedBridges = bridges.filter { $0.from == island.id || $0.to == island.id }
            let totalBridges = connectedBridges.reduce(0) { $0 + $1.count }

            if totalBridges != island.requiredBridges {
                return false
            }
        }

        // Verificar conectividad (todas las islas conectadas)
        return areAllIslandsConnected(with: bridges)
    }

    private func areAllIslandsConnected(with bridges: [Bridge]) -> Bool {
        guard let firstIsland = islands.first else { return false }

        var visited = Set<String>()
        var queue = [firstIsland.id]

        while !queue.isEmpty {
            let currentId = queue.removeFirst()
            if visited.contains(currentId) { continue }
            visited.insert(currentId)

            // Buscar islas conectadas
            let connectedBridges = bridges.filter { $0.from == currentId || $0.to == currentId }
            for bridge in connectedBridges {
                let neighborId = bridge.from == currentId ? bridge.to : bridge.from
                if !visited.contains(neighborId) {
                    queue.append(neighborId)
                }
            }
        }

        return visited.count == islands.count
    }
}

// MARK: - Seeded Random Generator
struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: String) {
        var hasher = Hasher()
        hasher.combine(seed)
        self.state = UInt64(truncatingIfNeeded: hasher.finalize())
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1
        return state
    }

    mutating func next(max: Int) -> Int {
        return Int(next() % UInt64(max))
    }
}
