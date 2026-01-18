//
//  BridgesPuzzleEngine.swift
//  LOGOS
//
//  Motor de puzzles de Grafos: Bridges
//  ACTUALIZADO: Mejor reactividad para actualizar colores
//

import Foundation
import Combine

@MainActor
class BridgesPuzzleEngine: ObservableObject {

    // MARK: - Published Properties
    @Published var currentPuzzle: BridgesPuzzle?
    @Published var bridges: [BridgesPuzzle.Bridge] = []
    @Published var isCompleted = false
    @Published var availableHints: [Hint] = []
    @Published var usedHintsCount = 0
    @Published var refreshTrigger = UUID()  // Para forzar refresh de UI

    // MARK: - Private Properties
    private var startTime: Date?
    private var elapsedTime: TimeInterval = 0

    // MARK: - Generate Puzzle
    func generatePuzzle(difficulty: Int) {
        let seed = UUID().uuidString
        let puzzle = BridgesPuzzle(seed: seed, difficulty: difficulty)

        guard puzzle.isValid() else {
            print("❌ Puzzle inválido generado, reintentando...")
            generatePuzzle(difficulty: difficulty)
            return
        }

        self.currentPuzzle = puzzle
        self.bridges = []
        self.isCompleted = false
        self.usedHintsCount = 0
        self.startTime = Date()
        self.elapsedTime = 0
        self.refreshTrigger = UUID()

        generateHints()

        print("✅ Bridges puzzle generado: \(puzzle.islands.count) islas, dificultad \(difficulty)")
    }

    // MARK: - Toggle Bridge
    func toggleBridge(from fromIsland: BridgesPuzzle.Island, to toIsland: BridgesPuzzle.Island) {
        guard !isCompleted else { return }
        guard let puzzle = currentPuzzle else { return }

        // Verificar que las islas estén alineadas (horizontal o vertical)
        let isHorizontal = fromIsland.row == toIsland.row
        let isVertical = fromIsland.col == toIsland.col

        guard isHorizontal || isVertical else { return }

        // Buscar puente existente
        if let index = bridges.firstIndex(where: {
            ($0.from == fromIsland.id && $0.to == toIsland.id) ||
            ($0.from == toIsland.id && $0.to == fromIsland.id)
        }) {
            // Ya existe un puente
            let existingBridge = bridges[index]

            if existingBridge.count == 1 {
                // Convertir a puente doble
                bridges[index] = BridgesPuzzle.Bridge(
                    from: fromIsland.id,
                    to: toIsland.id,
                    count: 2,
                    isHorizontal: isHorizontal
                )
            } else {
                // Eliminar puente
                bridges.remove(at: index)
            }
        } else {
            // Crear nuevo puente simple
            bridges.append(BridgesPuzzle.Bridge(
                from: fromIsland.id,
                to: toIsland.id,
                count: 1,
                isHorizontal: isHorizontal
            ))
        }

        // Forzar actualización de UI
        refreshTrigger = UUID()
        objectWillChange.send()

        checkCompletion()
    }

    // MARK: - Check Completion
    private func checkCompletion() {
        guard let puzzle = currentPuzzle else { return }

        if puzzle.isSolved(with: bridges) {
            isCompleted = true
            if let start = startTime {
                elapsedTime = Date().timeIntervalSince(start)
            }
            print("🎉 Bridges puzzle completado en \(elapsedTime)s!")
        }
    }

    // MARK: - Generate Hints
    private func generateHints() {
        availableHints = [
            Hint(
                type: .conceptual,
                message: "Conecta las islas con puentes. El número en cada isla indica cuántos puentes deben conectarse a ella."
            ),
            Hint(
                type: .conceptual,
                message: "Puedes colocar 1 o 2 puentes entre dos islas. Los puentes no pueden cruzarse."
            ),
            Hint(
                type: .logical,
                message: "Las islas con números grandes (6-8) generalmente necesitan puentes en todas direcciones posibles."
            ),
            Hint(
                type: .partial,
                message: "Comienza conectando las islas que solo tienen una dirección posible."
            ),
            Hint(
                type: .error,
                message: "Verifica que todas las islas estén conectadas y ninguna tenga más puentes de los requeridos."
            )
        ]
    }

    // MARK: - Use Hint
    func useHint(hint: Hint) {
        usedHintsCount += 1
    }

    // MARK: - Get Elapsed Time
    func getElapsedTime() -> TimeInterval {
        guard let start = startTime, !isCompleted else {
            return elapsedTime
        }
        return Date().timeIntervalSince(start)
    }

    // MARK: - Reset Puzzle
    func resetPuzzle() {
        bridges = []
        isCompleted = false
        usedHintsCount = 0
        startTime = Date()
        elapsedTime = 0
        refreshTrigger = UUID()
    }

    // MARK: - Get Bridge Count for Island
    func getBridgeCount(for island: BridgesPuzzle.Island) -> Int {
        let connectedBridges = bridges.filter { $0.from == island.id || $0.to == island.id }
        return connectedBridges.reduce(0) { $0 + $1.count }
    }
}
