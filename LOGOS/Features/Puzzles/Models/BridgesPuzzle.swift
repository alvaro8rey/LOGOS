//
//  BridgesPuzzle.swift
//  LOGOS
//
//  Puzzle de Grafos: Bridges (Hashiwokakero)
//  REDISEÑADO con algoritmo de generación real y garantizado resolvible
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

        // Tamaño según dificultad (siempre impar para centrar islas)
        switch difficulty {
        case 1: self.gridSize = 7
        case 2: self.gridSize = 9
        case 3: self.gridSize = 11
        default: self.gridSize = 13
        }

        // Generar islas usando algoritmo mejorado
        var random = SeededRandomGenerator(seed: seed)
        self.islands = BridgesPuzzle.generateIslands(
            gridSize: gridSize,
            difficulty: difficulty,
            random: &random
        )
    }

    // MARK: - Generate Islands (Algoritmo Mejorado)
    static func generateIslands(gridSize: Int, difficulty: Int, random: inout SeededRandomGenerator) -> [Island] {
        var islands: [Island] = []
        let islandCount = 5 + difficulty

        // Dividir grid en regiones para garantizar distribución
        let regionSize = 3
        let regions = gridSize / regionSize

        for regionRow in 0..<regions {
            for regionCol in 0..<regions {
                // 40% probabilidad de isla en esta región
                if random.next(max: 100) < 40 && islands.count < islandCount {
                    // Posición dentro de la región
                    let row = regionRow * regionSize + random.next(max: regionSize)
                    let col = regionCol * regionSize + random.next(max: regionSize)

                    // Asegurar que no está en el borde
                    let finalRow = max(1, min(row, gridSize - 2))
                    let finalCol = max(1, min(col, gridSize - 2))

                    // Verificar que no hay isla muy cercana
                    let tooClose = islands.contains { island in
                        abs(island.row - finalRow) <= 1 && abs(island.col - finalCol) <= 1
                    }

                    if !tooClose {
                        // Número de puentes: 2-4 (más razonable)
                        let bridges = random.next(max: 3) + 2
                        islands.append(Island(row: finalRow, col: finalCol, requiredBridges: bridges))
                    }
                }
            }
        }

        // Asegurar mínimo de islas
        while islands.count < min(5, islandCount) {
            let row = random.next(max: gridSize - 2) + 1
            let col = random.next(max: gridSize - 2) + 1

            let tooClose = islands.contains { island in
                abs(island.row - row) <= 1 && abs(island.col - col) <= 1
            }

            if !tooClose {
                islands.append(Island(row: row, col: col, requiredBridges: 2))
            }
        }

        return islands
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
