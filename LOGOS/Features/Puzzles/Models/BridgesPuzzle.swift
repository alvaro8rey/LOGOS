//
//  BridgesPuzzle.swift
//  LOGOS
//
//  Puzzle de Grafos: Bridges (Hashiwokakero)
//  ALGORITMO FINAL - Grid fijo garantizado alineado
//

import Foundation

struct BridgesPuzzle: Codable {
    let seed: String
    let difficulty: Int
    let gridSize: Int
    let islands: [Island]
    let solution: [Bridge]

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
        let from: String
        let to: String
        let count: Int
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
        self.gridSize = 9  // Tamaño fijo para mejor control

        var random = SeededRandomGenerator(seed: seed)
        let result = BridgesPuzzle.generatePuzzle(difficulty: difficulty, random: &random)

        self.islands = result.islands
        self.solution = result.solution
    }

    // MARK: - Generate Puzzle (ALGORITMO MEJORADO)
    static func generatePuzzle(
        difficulty: Int,
        random: inout SeededRandomGenerator
    ) -> (islands: [Island], solution: [Bridge]) {

        // Grid fijo 3x3 de posiciones (GARANTIZA alineación)
        let positions: [(Int, Int)] = [
            (1, 1), (1, 4), (1, 7),
            (4, 1), (4, 4), (4, 7),
            (7, 1), (7, 4), (7, 7)
        ]

        // Más islas para más dificultad
        let islandCount = min(6 + difficulty, positions.count)

        // Seleccionar posiciones
        var shuffled = positions
        shuffled.shuffle(using: &random)
        let selectedPositions = Array(shuffled.prefix(islandCount))

        // Crear islas temporales
        var tempIslands: [Island] = []
        for (row, col) in selectedPositions {
            tempIslands.append(Island(row: row, col: col, requiredBridges: 0))
        }

        // Crear mapa de islas por posición
        var islandMap: [String: Island] = [:]
        for island in tempIslands {
            let key = "\(island.row),\(island.col)"
            islandMap[key] = island
        }

        // Generar SOLUCIÓN primero
        var bridges: [Bridge] = []
        var bridgeCounts: [String: Int] = [:]

        // Para cada isla, intentar conectar con vecinos
        for island in tempIslands {
            // Buscar vecinos en las 4 direcciones
            let neighbors = findNeighbors(for: island, in: tempIslands)

            for neighbor in neighbors {
                // Solo crear puente si no existe
                let existingBridge = bridges.first { bridge in
                    (bridge.from == island.id && bridge.to == neighbor.id) ||
                    (bridge.from == neighbor.id && bridge.to == island.id)
                }

                if existingBridge == nil {
                    // 70% probabilidad de crear puente
                    if random.next(max: 100) < 70 {
                        let count = random.next(max: 2) + 1  // 1 o 2
                        let isHorizontal = island.row == neighbor.row

                        bridges.append(Bridge(
                            from: island.id,
                            to: neighbor.id,
                            count: count,
                            isHorizontal: isHorizontal
                        ))

                        bridgeCounts[island.id, default: 0] += count
                        bridgeCounts[neighbor.id, default: 0] += count
                    }
                }
            }
        }

        // Asegurar que TODAS las islas tengan al menos 1 puente
        for island in tempIslands {
            if bridgeCounts[island.id] == nil || bridgeCounts[island.id] == 0 {
                let neighbors = findNeighbors(for: island, in: tempIslands)
                if let neighbor = neighbors.first {
                    let isHorizontal = island.row == neighbor.row
                    bridges.append(Bridge(
                        from: island.id,
                        to: neighbor.id,
                        count: 1,
                        isHorizontal: isHorizontal
                    ))
                    bridgeCounts[island.id, default: 0] += 1
                    bridgeCounts[neighbor.id, default: 0] += 1
                }
            }
        }

        // Crear islas finales con requiredBridges CORRECTO
        let finalIslands = tempIslands.map { tempIsland in
            Island(
                row: tempIsland.row,
                col: tempIsland.col,
                requiredBridges: bridgeCounts[tempIsland.id] ?? 1
            )
        }

        return (islands: finalIslands, solution: bridges)
    }

    // MARK: - Find Neighbors
    static func findNeighbors(for island: Island, in islands: [Island]) -> [Island] {
        var neighbors: [Island] = []

        // Las posiciones válidas son 1, 4, 7
        let validPositions = [1, 4, 7]

        // Buscar horizontal (misma fila)
        for otherIsland in islands where otherIsland.id != island.id {
            if otherIsland.row == island.row && validPositions.contains(otherIsland.col) {
                neighbors.append(otherIsland)
            }
        }

        // Buscar vertical (misma columna)
        for otherIsland in islands where otherIsland.id != island.id {
            if otherIsland.col == island.col && validPositions.contains(otherIsland.row) {
                neighbors.append(otherIsland)
            }
        }

        return neighbors
    }

    // MARK: - Validation
    func isValid() -> Bool {
        return islands.count >= 5
    }

    func isSolved(with bridges: [Bridge]) -> Bool {
        // Verificar que cada isla tenga EXACTAMENTE el número correcto de puentes
        for island in islands {
            let connectedBridges = bridges.filter { $0.from == island.id || $0.to == island.id }
            let totalBridges = connectedBridges.reduce(0) { $0 + $1.count }

            if totalBridges != island.requiredBridges {
                return false
            }
        }

        // Verificar conectividad
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
