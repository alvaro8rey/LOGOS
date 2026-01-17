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

        // Generar islas ALINEADAS en filas y columnas
        var random = SeededRandomGenerator(seed: seed)
        let islandCount = 5 + (difficulty * 2)
        var islands: [Island] = []

        // Crear conjunto de filas y columnas para alinear islas
        var usedPositions = Set<String>()

        for _ in 0..<islandCount {
            var row: Int
            var col: Int
            var attempts = 0
            var positionKey: String

            repeat {
                row = random.next(max: gridSize)
                col = random.next(max: gridSize)
                positionKey = "\(row),\(col)"
                attempts += 1
            } while usedPositions.contains(positionKey) && attempts < 100

            if attempts < 100 {
                usedPositions.insert(positionKey)

                // Asignar puentes basado en cuántas conexiones son posibles
                // Empezar con 2-4 puentes (más razonable que 1-7)
                let bridges = (random.next(max: 3) + 2)  // 2-4 puentes
                islands.append(Island(row: row, col: col, requiredBridges: bridges))
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
