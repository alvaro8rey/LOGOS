//
//  MathGameView.swift
//  LOGOS
//
//  Vista del puzzle matemático (KenKen/Calcudoku)
//

import SwiftUI

struct MathGameView: View {
    @StateObject var viewModel: MathPuzzleViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingInstructions = false
    @State private var selectedCell: (row: Int, col: Int)? = nil
    @State private var showingNumberPicker = false

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
                            mathGrid(puzzle: puzzle)
                        }

                        // Number picker
                        if showingNumberPicker {
                            numberPickerView
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
                Text("Math Puzzle")
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

    // MARK: - Math Grid
    private func mathGrid(puzzle: MathPuzzle) -> some View {
        let cellSize: CGFloat = getCellSize(gridSize: puzzle.gridSize)

        return VStack(spacing: 0) {
            ForEach(0..<puzzle.gridSize, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<puzzle.gridSize, id: \.self) { col in
                        cellView(row: row, col: col, puzzle: puzzle, cellSize: cellSize)
                    }
                }
            }
        }
        .padding(20)
        .liquidGlass()
    }

    // MARK: - Cell View
    private func cellView(row: Int, col: Int, puzzle: MathPuzzle, cellSize: CGFloat) -> some View {
        let userValue = viewModel.puzzleEngine.userGrid[row][col]
        let cage = puzzle.getCage(for: row, col)
        let isSelected = selectedCell?.row == row && selectedCell?.col == col
        let isFirstInCage = puzzle.isFirstCellInCage(row: row, col: col)

        return ZStack(alignment: .topLeading) {
            // Background
            Rectangle()
                .fill(isSelected ? Color.logosPrimary.opacity(0.1) : Color.logosCard)
                .border(getCageBorderColor(row: row, col: col, puzzle: puzzle), width: 2)

            // Cage label (solo en primera celda de la jaula)
            if isFirstInCage, let cage = cage {
                Text("\(cage.target)\(cage.operation.symbol)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.logosPrimary)
                    .padding(3)
            }

            // User value
            if userValue > 0 {
                Text("\(userValue)")
                    .font(.system(size: cellSize * 0.5, weight: .bold, design: .rounded))
                    .foregroundColor(.logosTextPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .onTapGesture {
            selectedCell = (row, col)
            showingNumberPicker = true
        }
    }

    // MARK: - Get Cage Border Color
    private func getCageBorderColor(row: Int, col: Int, puzzle: MathPuzzle) -> Color {
        guard let cage = puzzle.getCage(for: row, col) else {
            return Color.logosTextTertiary.opacity(0.3)
        }

        // Diferentes colores para diferentes tipos de operación
        switch cage.operation {
        case .add:
            return Color.blue.opacity(0.5)
        case .subtract:
            return Color.orange.opacity(0.5)
        case .multiply:
            return Color.green.opacity(0.5)
        case .divide:
            return Color.purple.opacity(0.5)
        case .none:
            return Color.gray.opacity(0.5)
        }
    }

    // MARK: - Number Picker View
    private var numberPickerView: some View {
        guard let puzzle = viewModel.puzzleEngine.currentPuzzle else {
            return AnyView(EmptyView())
        }

        return AnyView(
            VStack(spacing: 12) {
                Text("Selecciona un número")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.logosTextPrimary)

                HStack(spacing: 8) {
                    // Botón para borrar
                    Button {
                        if let cell = selectedCell {
                            viewModel.puzzleEngine.setCellValue(row: cell.row, col: cell.col, value: 0)
                        }
                        showingNumberPicker = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(.logosError)
                            .frame(width: 50, height: 50)
                            .background(Color.logosCard)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Números disponibles
                    ForEach(1...puzzle.gridSize, id: \.self) { number in
                        Button {
                            if let cell = selectedCell {
                                viewModel.puzzleEngine.setCellValue(row: cell.row, col: cell.col, value: number)
                            }
                            showingNumberPicker = false
                        } label: {
                            Text("\(number)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.logosPrimary)
                                .frame(width: 50, height: 50)
                                .background(Color.logosCard)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }

                Button("Cancelar") {
                    showingNumberPicker = false
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.logosTextSecondary)
            }
            .padding()
            .liquidGlass()
        )
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
                selectedCell = nil
                showingNumberPicker = false
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

                        Text("Has resuelto correctamente todas las jaulas matemáticas")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.logosTextSecondary)
                            .multilineTextAlignment(.center)
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
                            Image(systemName: "function")
                                .font(.system(size: 60))
                                .foregroundStyle(Color.primaryGradient)

                            Text("Cómo Jugar Math Puzzle")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.logosTextPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)

                        VStack(alignment: .leading, spacing: 16) {
                            instructionItem(
                                title: "Objetivo",
                                description: "Llena la cuadrícula con números del 1 al tamaño de la cuadrícula, sin repetir números en filas ni columnas."
                            )

                            instructionItem(
                                title: "Jaulas Matemáticas",
                                description: "Cada jaula (grupo de celdas con borde de color) tiene un número objetivo y una operación matemática:\n\n• + (Suma): Los números deben sumar el objetivo\n• × (Multiplicación): Los números deben multiplicar al objetivo\n• - (Resta): La diferencia debe dar el objetivo\n• ÷ (División): El cociente debe dar el objetivo\n• Sin símbolo: La celda debe contener ese número"
                            )

                            instructionItem(
                                title: "Reglas",
                                description: "• Cada número (1 a N) debe aparecer exactamente una vez en cada fila\n• Cada número (1 a N) debe aparecer exactamente una vez en cada columna\n• Los números en cada jaula deben cumplir con su operación matemática\n• Puedes usar el mismo número varias veces en una jaula (si está en diferentes filas/columnas)"
                            )

                            instructionItem(
                                title: "Cómo Jugar",
                                description: "1. Toca una celda vacía para seleccionarla\n2. Aparecerá un selector de números\n3. Elige el número que quieres colocar\n4. Usa la X roja para borrar un número\n5. Completa todas las celdas correctamente para ganar"
                            )

                            instructionItem(
                                title: "Estrategia",
                                description: "• Empieza con jaulas pequeñas (1-2 celdas)\n• Las jaulas con un solo número son las más fáciles\n• Busca números que solo pueden ir en una posición\n• Usa eliminación: si un número no puede estar en una fila, prueba otra"
                            )

                            instructionItem(
                                title: "Colores de Jaulas",
                                description: "Cada operación tiene un color diferente para ayudarte a identificarlas:\n\n🔵 Azul: Suma (+)\n🟠 Naranja: Resta (-)\n🟢 Verde: Multiplicación (×)\n🟣 Morado: División (÷)\n⚫ Gris: Valor fijo"
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
        MathGameView(
            viewModel: MathPuzzleViewModel(
                puzzleType: .mathematical,
                difficulty: 1,
                userId: "preview-user"
            )
        )
    }
}
