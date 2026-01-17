//
//  BridgesGameView.swift
//  LOGOS
//
//  Vista del puzzle de Grafos: Bridges
//

import SwiftUI

struct BridgesGameView: View {
    @StateObject var viewModel: BridgesPuzzleViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingInstructions = false

    var body: some View {
        ZStack {
            Color.logosBackground
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                headerView

                ScrollView {
                    VStack(spacing: 20) {
                        // Game grid
                        if let puzzle = viewModel.puzzleEngine.currentPuzzle {
                            bridgesGrid(puzzle: puzzle)
                        }

                        // Controls
                        controlsView
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingInstructions = true
                } label: {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.logosPrimary)
                }
            }
        }
        .sheet(isPresented: $showingInstructions) {
            instructionsSheet
        }
        .sheet(isPresented: $viewModel.showingCompletionSheet) {
            completionSheet
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bridges")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.logosTextPrimary)

                HStack(spacing: 12) {
                    Label("Nivel \(viewModel.difficulty)", systemImage: "chart.bar.fill")
                    Label(timeString, systemImage: "clock.fill")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.logosTextSecondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if !viewModel.puzzleEngine.isCompleted {
                viewModel.puzzleEngine.objectWillChange.send()
            }
        }
    }

    // MARK: - Bridges Grid
    private func bridgesGrid(puzzle: BridgesPuzzle) -> some View {
        let cellSize: CGFloat = getCellSize(gridSize: puzzle.gridSize)

        return GeometryReader { geometry in
            ZStack {
                // Puentes
                ForEach(viewModel.puzzleEngine.bridges) { bridge in
                    if let fromIsland = puzzle.islands.first(where: { $0.id == bridge.from }),
                       let toIsland = puzzle.islands.first(where: { $0.id == bridge.to }) {
                        bridgeLine(
                            from: fromIsland,
                            to: toIsland,
                            count: bridge.count,
                            cellSize: cellSize
                        )
                    }
                }

                // Islas
                ForEach(puzzle.islands) { island in
                    islandView(island: island, cellSize: cellSize, puzzle: puzzle)
                }
            }
            .frame(width: cellSize * CGFloat(puzzle.gridSize), height: cellSize * CGFloat(puzzle.gridSize))
        }
        .frame(height: getCellSize(gridSize: puzzle.gridSize) * CGFloat(puzzle.gridSize))
        .padding(20)
        .liquidGlass()
    }

    // MARK: - Island View
    @State private var selectedIsland: BridgesPuzzle.Island?

    private func islandView(island: BridgesPuzzle.Island, cellSize: CGFloat, puzzle: BridgesPuzzle) -> some View {
        let x = cellSize * CGFloat(island.col) + cellSize / 2
        let y = cellSize * CGFloat(island.row) + cellSize / 2
        let bridgeCount = viewModel.puzzleEngine.getBridgeCount(for: island)
        let isComplete = bridgeCount == island.requiredBridges
        let hasError = bridgeCount > island.requiredBridges

        return Circle()
            .fill(hasError ? Color.logosError : (isComplete ? Color.logosSuccess : Color.logosPrimary))
            .frame(width: cellSize * 0.8, height: cellSize * 0.8)
            .overlay(
                Text("\(island.requiredBridges)")
                    .font(.system(size: cellSize * 0.4, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            )
            .position(x: x, y: y)
            .onTapGesture {
                if let selected = selectedIsland {
                    // Ya hay una isla seleccionada, intentar crear puente
                    viewModel.puzzleEngine.toggleBridge(from: selected, to: island)
                    selectedIsland = nil
                } else {
                    // Seleccionar esta isla
                    selectedIsland = island
                }
            }
            .overlay(
                selectedIsland?.id == island.id ?
                Circle()
                    .stroke(Color.logosAccent, lineWidth: 3)
                    .frame(width: cellSize * 0.9, height: cellSize * 0.9)
                    .position(x: x, y: y)
                : nil
            )
    }

    // MARK: - Bridge Line
    private func bridgeLine(from: BridgesPuzzle.Island, to: BridgesPuzzle.Island, count: Int, cellSize: CGFloat) -> some View {
        let fromX = cellSize * CGFloat(from.col) + cellSize / 2
        let fromY = cellSize * CGFloat(from.row) + cellSize / 2
        let toX = cellSize * CGFloat(to.col) + cellSize / 2
        let toY = cellSize * CGFloat(to.row) + cellSize / 2

        return Group {
            if count == 1 {
                // Puente simple
                Path { path in
                    path.move(to: CGPoint(x: fromX, y: fromY))
                    path.addLine(to: CGPoint(x: toX, y: toY))
                }
                .stroke(Color.logosPrimary, lineWidth: 3)
            } else {
                // Puente doble
                let offset: CGFloat = 3
                Path { path in
                    if from.row == to.row {
                        // Horizontal
                        path.move(to: CGPoint(x: fromX, y: fromY - offset))
                        path.addLine(to: CGPoint(x: toX, y: toY - offset))
                        path.move(to: CGPoint(x: fromX, y: fromY + offset))
                        path.addLine(to: CGPoint(x: toX, y: toY + offset))
                    } else {
                        // Vertical
                        path.move(to: CGPoint(x: fromX - offset, y: fromY))
                        path.addLine(to: CGPoint(x: toX - offset, y: toY))
                        path.move(to: CGPoint(x: fromX + offset, y: fromY))
                        path.addLine(to: CGPoint(x: toX + offset, y: toY))
                    }
                }
                .stroke(Color.logosPrimary, lineWidth: 3)
            }
        }
    }

    // MARK: - Get Cell Size
    private func getCellSize(gridSize: Int) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 80
        return availableWidth / CGFloat(gridSize)
    }

    // MARK: - Controls
    private var controlsView: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.puzzleEngine.resetPuzzle()
                selectedIsland = nil
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reiniciar")
                }
                .frame(maxWidth: .infinity)
            }
            .liquidButton()
        }
    }

    // MARK: - Time String
    private var timeString: String {
        let time = viewModel.puzzleEngine.getElapsedTime()
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Completion Sheet
    private var completionSheet: some View {
        NavigationView {
            ZStack {
                Color.logosBackground
                    .ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.accentGradient)

                    VStack(spacing: 12) {
                        Text("¡Completado!")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.logosTextPrimary)

                        Text("Has conectado todas las islas correctamente")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.logosTextSecondary)
                    }

                    VStack(spacing: 16) {
                        statRow(icon: "clock.fill", label: "Tiempo", value: timeString)
                    }
                    .padding(20)
                    .liquidGlass()
                    .padding(.horizontal, 30)

                    VStack(spacing: 12) {
                        Button {
                            viewModel.generateNewPuzzle()
                        } label: {
                            Text("Siguiente Puzzle")
                                .frame(maxWidth: .infinity)
                        }
                        .liquidButton()

                        Button {
                            dismiss()
                        } label: {
                            Text("Volver al Menú")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.logosTextSecondary)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 30)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Stat Row
    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.primaryGradient)
                .frame(width: 30)

            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.logosTextSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.logosTextPrimary)
        }
    }

    // MARK: - Instructions Sheet
    private var instructionsSheet: some View {
        NavigationView {
            ZStack {
                Color.logosBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(spacing: 12) {
                            Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                                .font(.system(size: 60))
                                .foregroundStyle(Color.primaryGradient)

                            Text("Cómo Jugar Bridges")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.logosTextPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)

                        VStack(alignment: .leading, spacing: 16) {
                            instructionItem(
                                title: "Objetivo",
                                description: "Conecta todas las islas con puentes siguiendo las reglas del número en cada isla."
                            )

                            instructionItem(
                                title: "Reglas",
                                description: "• Cada isla muestra un número (1-8) que indica cuántos puentes deben conectarse a ella\n• Puedes colocar 1 o 2 puentes entre dos islas\n• Los puentes solo pueden ser horizontales o verticales\n• Los puentes NO pueden cruzarse\n• Todas las islas deben estar conectadas al final"
                            )

                            instructionItem(
                                title: "Cómo Jugar",
                                description: "1. Toca una isla para seleccionarla (se marca con borde azul)\n2. Toca otra isla alineada (horizontal o vertical) para crear un puente\n3. Vuelve a tocar para cambiar de puente simple (1) a doble (2)\n4. Toca una tercera vez para eliminar el puente"
                            )

                            instructionItem(
                                title: "Estrategia",
                                description: "• Empieza con islas que tienen números grandes (6-8)\n• Las islas con 1 o 2 suelen ser fáciles de resolver primero\n• Asegúrate de que todas las islas queden conectadas"
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Instrucciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        showingInstructions = false
                    }
                }
            }
        }
    }

    private func instructionItem(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.logosPrimary)

            Text(description)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.logosTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .liquidGlass()
    }
}

#Preview {
    NavigationStack {
        BridgesGameView(
            viewModel: BridgesPuzzleViewModel(
                puzzleType: .graphs,
                difficulty: 1,
                userId: "preview-user"
            )
        )
    }
}
