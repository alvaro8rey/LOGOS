//
//  BridgesPuzzle.swift
//  LOGOS
//
//  Puzzle de Grafos: Bridges (Hashiwokakero)
//  COMPLETAMENTE REDISEÑADO - Generación basada en grid alineado
//

import Foundation

struct BridgesPuzzle: Codable {
    let seed: String
    let difficulty: Int
    let gridSize: Int
    let islands: [Island]
    let solution: [Bridge]  // Solución válida

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
        default: self.gridSize = 13
        }

        // Generar puzzle completo con solución
        var random = SeededRandomGenerator(seed: seed)
        let result = BridgesPuzzle.generatePuzzle(
            gridSize: gridSize,
            difficulty: difficulty,
            random: &random
        )

        self.islands = result.islands
        self.solution = result.solution
    }

    // MARK: - Generate Puzzle (NUEVO ALGORITMO)
    static func generatePuzzle(
        gridSize: Int,
        difficulty: Int,
        random: inout SeededRandomGenerator
    ) -> (islands: [Island], solution: [Bridge]) {

        // Crear grid de posiciones válidas (solo posiciones pares para alineación)
        let step = 2
        var gridPositions: [(Int, Int)] = []
        for row in stride(from: 1, to: gridSize - 1, by: step) {
            for col in stride(from: 1, to: gridSize - 1, by: step) {
                gridPositions.append((row, col))
            }
        }

        // Número de islas basado en dificultad
        let islandCount = min(4 + difficulty, gridPositions.count)

        // Seleccionar posiciones aleatorias
        gridPositions.shuffle(using: &random)
        let selectedPositions = Array(gridPositions.prefix(islandCount))

        // Crear islas temporales (sin requiredBridges aún)
        var tempIslands: [Island] = []
        for (row, col) in selectedPositions {
            tempIslands.append(Island(row: row, col: col, requiredBridges: 0))
        }

        // Generar conexiones válidas y calcular requiredBridges
        var bridges: [Bridge] = []
        var bridgeCounts: [String: Int] = [:]  // Contar puentes por isla

        // Crear diccionario de islas por posición
        var islandsByPosition: [[String?]] = Array(
            repeating: Array(repeating: nil, count: gridSize),
            count: gridSize
        )
        for island in tempIslands {
            islandsByPosition[island.row][island.col] = island.id
        }

        // Para cada isla, buscar vecinos horizontales y verticales
        for island in tempIslands {
            // Buscar vecino horizontal (derecha)
            var rightNeighbor: Island? = nil
            for col in (island.col + 1)..<gridSize {
                if let neighborId = islandsByPosition[island.row][col] {
                    rightNeighbor = tempIslands.first { $0.id == neighborId }
                    break
                }
            }

            // Buscar vecino vertical (abajo)
            var downNeighbor: Island? = nil
            for row in (island.row + 1)..<gridSize {
                if let neighborId = islandsByPosition[row][island.col] {
                    downNeighbor = tempIslands.first { $0.id == neighborId }
                    break
                }
            }

            // Crear puentes con vecinos (50% probabilidad de 1 o 2 puentes)
            if let neighbor = rightNeighbor, random.next(max: 100) < 70 {
                let count = random.next(max: 2) + 1  // 1 o 2
                bridges.append(Bridge(
                    from: island.id,
                    to: neighbor.id,
                    count: count,
                    isHorizontal: true
                ))
                bridgeCounts[island.id, default: 0] += count
                bridgeCounts[neighbor.id, default: 0] += count
            }

            if let neighbor = downNeighbor, random.next(max: 100) < 70 {
                let count = random.next(max: 2) + 1  // 1 o 2
                bridges.append(Bridge(
                    from: island.id,
                    to: neighbor.id,
                    count: count,
                    isHorizontal: false
                ))
                bridgeCounts[island.id, default: 0] += count
                bridgeCounts[neighbor.id, default: 0] += count
            }
        }

        // Asegurar que todas las islas tengan al menos 1 puente
        for island in tempIslands {
            if bridgeCounts[island.id] == nil || bridgeCounts[island.id] == 0 {
                // Buscar cualquier vecino y conectar
                if let neighbor = findAnyNeighbor(for: island, in: tempIslands, islandsByPosition: islandsByPosition, gridSize: gridSize) {
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

        // Crear islas finales con requiredBridges correcto
        let finalIslands = tempIslands.map { tempIsland in
            Island(
                row: tempIsland.row,
                col: tempIsland.col,
                requiredBridges: max(1, bridgeCounts[tempIsland.id] ?? 1)
            )
        }

        return (islands: finalIslands, solution: bridges)
    }

    // MARK: - Helper: Find Any Neighbor
    static func findAnyNeighbor(
        for island: Island,
        in islands: [Island],
        islandsByPosition: [[String?]],
        gridSize: Int
    ) -> Island? {
        // Buscar horizontal derecha
        for col in (island.col + 1)..<gridSize {
            if let neighborId = islandsByPosition[island.row][col] {
                return islands.first { $0.id == neighborId }
            }
        }

        // Buscar vertical abajo
        for row in (island.row + 1)..<gridSize {
            if let neighborId = islandsByPosition[row][island.col] {
                return islands.first { $0.id == neighborId }
            }
        }

        // Buscar horizontal izquierda
        for col in stride(from: island.col - 1, through: 0, by: -1) {
            if let neighborId = islandsByPosition[island.row][col] {
                return islands.first { $0.id == neighborId }
            }
        }

        // Buscar vertical arriba
        for row in stride(from: island.row - 1, through: 0, by: -1) {
            if let neighborId = islandsByPosition[row][island.col] {
                return islands.first { $0.id == neighborId }
            }
        }

        return nil
    }

    // MARK: - Validation
    func isValid() -> Bool {
        return islands.count >= 4
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
