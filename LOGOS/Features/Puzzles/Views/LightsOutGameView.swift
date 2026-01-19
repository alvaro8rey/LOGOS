//
//  LightsOutGameView.swift
//  LOGOS
//
//  Vista del puzzle Lights Out
//  Puzzle extremadamente desafiante de lógica pura
//

import SwiftUI

struct LightsOutGameView: View {
    @StateObject var viewModel: LightsOutViewModel
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
                        // Lights Out grid
                        if viewModel.puzzleEngine.currentPuzzle != nil {
                            lightsOutGrid
                        }

                        // Stats
                        statsView

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
                Text("Lights Out")
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

    // MARK: - Lights Out Grid
    private var lightsOutGrid: some View {
        let gridSize = viewModel.puzzleEngine.currentPuzzle!.gridSize
        let cellSize = getCellSize(gridSize: gridSize)

        return VStack(spacing: 4) {
            ForEach(0..<gridSize, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<gridSize, id: \.self) { col in
                        lightCell(row: row, col: col, cellSize: cellSize)
                    }
                }
            }
        }
        .padding(20)
        .liquidGlass()
    }

    // MARK: - Light Cell
    private func lightCell(row: Int, col: Int, cellSize: CGFloat) -> some View {
        let isOn = viewModel.puzzleEngine.currentGrid[row][col]

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                viewModel.puzzleEngine.toggleCell(row: row, col: col)
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isOn ?
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.logosCard, Color.logosCard.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: isOn ? Color.yellow.opacity(0.5) : Color.clear, radius: 10)

                if isOn {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: cellSize * 0.4))
                        .foregroundColor(.white)
                }
            }
            .frame(width: cellSize, height: cellSize)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Get Cell Size
    private func getCellSize(gridSize: Int) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 80
        let spacing: CGFloat = CGFloat(gridSize - 1) * 4
        return (availableWidth - spacing) / CGFloat(gridSize)
    }

    // MARK: - Stats View
    private var statsView: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "hand.tap.fill",
                label: "Movimientos",
                value: "\(viewModel.puzzleEngine.moveCount)"
            )

            statCard(
                icon: "lightbulb.fill",
                label: "Encendidas",
                value: "\(getLightsOnCount())"
            )
        }
    }

    private func statCard(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.primaryGradient)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.logosTextPrimary)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.logosTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .liquidGlass()
    }

    // MARK: - Get Lights On Count
    private func getLightsOnCount() -> Int {
        var count = 0
        for row in viewModel.puzzleEngine.currentGrid {
            for isOn in row {
                if isOn { count += 1 }
            }
        }
        return count
    }

    // MARK: - Controls
    private var controlsView: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation {
                    viewModel.puzzleEngine.resetPuzzle()
                }
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
                        Text("¡Todas las luces apagadas!")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.logosTextPrimary)

                        Text("Has completado el puzzle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.logosTextSecondary)
                    }

                    VStack(spacing: 16) {
                        statRow(icon: "clock.fill", label: "Tiempo", value: timeString)
                        statRow(icon: "hand.tap.fill", label: "Movimientos", value: "\(viewModel.puzzleEngine.moveCount)")
                    }
                    .padding(20)
                    .liquidGlass()
                    .padding(.horizontal, 30)

                    VStack(spacing: 12) {
                        Button {
                            withAnimation {
                                viewModel.generateNewPuzzle()
                            }
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
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(Color.primaryGradient)

                            Text("Cómo Jugar Lights Out")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.logosTextPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)

                        VStack(alignment: .leading, spacing: 16) {
                            instructionItem(
                                title: "El Desafío",
                                description: "Lights Out es uno de los puzzles más engañosamente difíciles. Parece simple pero requiere pensamiento matemático avanzado para niveles altos."
                            )

                            instructionItem(
                                title: "Objetivo",
                                description: "Apagar TODAS las luces de la cuadrícula. El puzzle está resuelto cuando ninguna luz está encendida (todas son grises oscuras)."
                            )

                            instructionItem(
                                title: "Reglas",
                                description: "1. Toca cualquier celda para cambiar su estado\n2. Cuando tocas una celda, esa celda Y sus 4 vecinos (arriba, abajo, izquierda, derecha) cambian de estado\n3. Si una luz está ENCENDIDA, se APAGA\n4. Si una luz está APAGADA, se ENCIENDE\n5. Las celdas en los bordes solo afectan a sus vecinos existentes"
                            )

                            instructionItem(
                                title: "Por Qué Es Tan Difícil",
                                description: "• Cada movimiento afecta 5 celdas (la que tocas + 4 vecinos)\n• Los efectos se acumulan y pueden crear patrones complejos\n• A veces necesitas \"romper\" un patrón para arreglarlo después\n• No hay forma obvia de \"deshacer\" un movimiento\n• En grids 7×7, puede haber millones de combinaciones posibles"
                            )

                            instructionItem(
                                title: "Estrategias",
                                description: "• MÉTODO DE FILA: Resuelve fila por fila de arriba hacia abajo\n• PARIDAD: Presionar la misma celda dos veces la devuelve al estado original\n• PATRONES: Algunos patrones iniciales tienen soluciones conocidas\n• ESQUINAS PRIMERO: A veces ayuda empezar por las esquinas\n• MATEMÁTICA LINEAL: El puzzle es matemáticamente un sistema de ecuaciones en GF(2)"
                            )

                            instructionItem(
                                title: "Dificultad",
                                description: "• NIVEL 1 (3×3): 9 luces - Relativamente simple\n• NIVEL 2 (4×4): 16 luces - Moderado\n• NIVEL 3 (5×5): 25 luces - Difícil\n• NIVEL 4 (6×6): 36 luces - Muy difícil\n• NIVEL 5 (7×7): 49 luces - EXTREMADAMENTE DIFÍCIL\n\nUn grid 7×7 tiene 128 quintillones de estados posibles. La solución promedio requiere 15-25 movimientos precisos."
                            )

                            instructionItem(
                                title: "Consejo Final",
                                description: "Este puzzle parece aleatorio pero es completamente determinista y matemático. Cada configuración inicial tiene UNA solución óptima. La clave es pensar varios pasos adelante y entender cómo interactúan los patrones."
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
        LightsOutGameView(
            viewModel: LightsOutViewModel(
                puzzleType: .graphs,
                difficulty: 3,
                userId: "preview-user"
            )
        )
    }
}
