//
//  SymmetryGameView.swift
//  LOGOS
//

import SwiftUI

struct SymmetryGameView: View {
    @StateObject var viewModel: SymmetryPuzzleViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingInstructions = false

    var body: some View {
        ZStack {
            Color.logosBackground
                .ignoresSafeArea()

            VStack(spacing: 20) {
                headerView

                ScrollView {
                    VStack(spacing: 20) {
                        if let puzzle = viewModel.puzzleEngine.currentPuzzle {
                            VStack(spacing: 8) {
                                Text(puzzle.symmetryType.displayName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.logosPrimary)

                                symmetryGrid(puzzle: puzzle)
                            }
                        }

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

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.logosTextSecondary)
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

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Simetría")
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

    private func symmetryGrid(puzzle: SymmetryPuzzle) -> some View {
        let cellSize: CGFloat = getCellSize(gridSize: puzzle.gridSize)

        return VStack(spacing: 1) {
            ForEach(0..<puzzle.gridSize, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<puzzle.gridSize, id: \.self) { col in
                        cellView(row: row, col: col, size: cellSize, puzzle: puzzle)
                            .id("\(row)-\(col)")  // Unique ID for each cell
                    }
                }
            }
        }
        .padding(20)
        .liquidGlass()
    }

    private func cellView(row: Int, col: Int, size: CGFloat, puzzle: SymmetryPuzzle) -> some View {
        let state = viewModel.puzzleEngine.userGrid[row][col]
        let isInitial = viewModel.puzzleEngine.isCellInitial(row: row, col: col)

        return ZStack {
            Rectangle()
                .fill(cellColor(for: state, isInitial: isInitial))
                .frame(width: size, height: size)

            if state == .marked {
                Image(systemName: "xmark")
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(.logosTextSecondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isInitial {
                viewModel.puzzleEngine.toggleCell(row: row, col: col)
            }
        }
    }

    private func cellColor(for state: SymmetryPuzzle.CellState, isInitial: Bool) -> Color {
        if isInitial {
            return state == .filled ? Color.logosPrimary.opacity(0.9) : Color.logosCard.opacity(0.5)
        }

        switch state {
        case .empty:
            return Color.logosCard
        case .filled:
            return Color.logosSecondary.opacity(0.6)
        case .marked:
            return Color.logosCard
        }
    }

    private func getCellSize(gridSize: Int) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 80
        let maxCellSize: CGFloat = 30
        let calculatedSize = availableWidth / CGFloat(gridSize)
        return min(calculatedSize, maxCellSize)
    }

    private var controlsView: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.puzzleEngine.resetPuzzle()
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

    private var timeString: String {
        let time = viewModel.puzzleEngine.getElapsedTime()
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

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

                        Text("Has completado el patrón simétrico")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.logosTextSecondary)
                    }

                    Button {
                        viewModel.generateNewPuzzle()
                    } label: {
                        Text("Siguiente Puzzle")
                            .frame(maxWidth: .infinity)
                    }
                    .liquidButton()
                    .padding(.horizontal, 30)

                    Spacer()
                }
            }
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
                            Image(systemName: "square.split.diagonal.2x2.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(Color.primaryGradient)

                            Text("Cómo Jugar Simetría")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.logosTextPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)

                        VStack(alignment: .leading, spacing: 16) {
                            instructionItem(
                                title: "Objetivo",
                                description: "Completa el patrón de forma que sea simétrico según el tipo de simetría indicado."
                            )

                            instructionItem(
                                title: "Tipos de Simetría",
                                description: "• Horizontal: El patrón se refleja arriba y abajo\n• Vertical: El patrón se refleja izquierda y derecha\n• Diagonal: El patrón se refleja en diagonal\n• Rotacional: El patrón se repite al rotar 180 grados"
                            )

                            instructionItem(
                                title: "Cómo Jugar",
                                description: "1. Observa el tipo de simetría en la parte superior\n2. Toca una celda vacía para rellenarla\n3. Vuelve a tocar para marcarla con X (indicando que debe estar vacía)\n4. Toca una tercera vez para vaciar la celda\n5. Las celdas iniciales (más brillantes) no se pueden modificar"
                            )

                            instructionItem(
                                title: "Estrategia",
                                description: "• Identifica primero el eje de simetría\n• Trabaja desde las celdas iniciales hacia afuera\n• Rellena celdas simétricas en pares para mantener el patrón\n• Usa las marcas X para indicar celdas que deben quedar vacías"
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
