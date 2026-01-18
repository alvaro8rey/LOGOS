//
//  MathGameView.swift
//  LOGOS
//
//  Vista REDISEÑADA del Math Puzzle
//  UI clara y fácil de entender
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

            VStack(spacing: 16) {
                // Header
                headerView

                ScrollView {
                    VStack(spacing: 20) {
                        // Math Puzzle grid
                        if let puzzle = viewModel.puzzleEngine.currentPuzzle {
                            mathGrid(puzzle: puzzle)
                        }

                        // Number picker
                        if showingNumberPicker {
                            numberPickerView
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
        let cellSize = getCellSize(gridSize: puzzle.gridSize)

        return VStack(spacing: 0) {
            ForEach(0..<puzzle.gridSize, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<puzzle.gridSize, id: \.self) { col in
                        mathCell(row: row, col: col, puzzle: puzzle, cellSize: cellSize)
                    }
                }
            }
        }
        .padding(20)
        .liquidGlass()
    }

    // MARK: - Math Cell
    private func mathCell(row: Int, col: Int, puzzle: MathPuzzle, cellSize: CGFloat) -> some View {
        let userValue = viewModel.puzzleEngine.userGrid[row][col]
        let isSelected = selectedCell?.row == row && selectedCell?.col == col
        let cage = puzzle.getCage(for: row, col: col)
        let isFirstInCage = puzzle.isFirstCellInCage(row: row, col: col)
        let hasConflict = viewModel.puzzleEngine.hasConflict(row: row, col: col)

        // Color de la jaula
        let cageColor = getCageColor(cageId: cage?.id ?? "")

        return Button {
            selectedCell = (row, col)
            showingNumberPicker = true
        } label: {
            ZStack(alignment: .topLeading) {
                // Fondo de celda
                Rectangle()
                    .fill(
                        isSelected ? Color.logosPrimary.opacity(0.2) :
                        Color.logosCard
                    )

                // Bordes de jaula (GRUESOS y COLORIDOS)
                cageBorders(row: row, col: col, puzzle: puzzle, cageId: cage?.id ?? "", color: cageColor)

                // Label de jaula (arriba izquierda de primera celda)
                if isFirstInCage, let cage = cage {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(cage.target)\(cage.operation.symbol)")
                            .font(.system(size: cellSize * 0.2, weight: .bold))
                            .foregroundColor(cageColor)
                            .padding(2)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }

                // Número del usuario (centro)
                if userValue > 0 {
                    Text("\(userValue)")
                        .font(.system(size: cellSize * 0.5, weight: .bold, design: .rounded))
                        .foregroundColor(
                            hasConflict ? Color.logosError :
                            Color.logosTextPrimary
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: cellSize, height: cellSize)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Cage Borders
    private func cageBorders(row: Int, col: Int, puzzle: MathPuzzle, cageId: String, color: Color) -> some View {
        let borderWidth: CGFloat = 3

        // Verificar vecinos para determinar qué bordes dibujar
        let topDifferent = row == 0 || puzzle.getCage(for: row - 1, col: col)?.id != cageId
        let bottomDifferent = row == puzzle.gridSize - 1 || puzzle.getCage(for: row + 1, col: col)?.id != cageId
        let leftDifferent = col == 0 || puzzle.getCage(for: row, col: col - 1)?.id != cageId
        let rightDifferent = col == puzzle.gridSize - 1 || puzzle.getCage(for: row, col: col + 1)?.id != cageId

        return ZStack {
            // Borde superior
            if topDifferent {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(color)
                        .frame(height: borderWidth)
                    Spacer()
                }
            }

            // Borde inferior
            if bottomDifferent {
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(color)
                        .frame(height: borderWidth)
                }
            }

            // Borde izquierdo
            if leftDifferent {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(color)
                        .frame(width: borderWidth)
                    Spacer()
                }
            }

            // Borde derecho
            if rightDifferent {
                HStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(color)
                        .frame(width: borderWidth)
                }
            }
        }
    }

    // MARK: - Get Cage Color
    private func getCageColor(cageId: String) -> Color {
        // Hash del ID para asignar color consistente
        let hash = abs(cageId.hashValue)
        let colors: [Color] = [
            .blue,
            .purple,
            .green,
            .orange,
            .pink,
            .cyan,
            .indigo,
            .mint,
            .teal
        ]
        return colors[hash % colors.count]
    }

    // MARK: - Get Cell Size
    private func getCellSize(gridSize: Int) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 80
        return availableWidth / CGFloat(gridSize)
    }

    // MARK: - Number Picker
    private var numberPickerView: some View {
        guard let puzzle = viewModel.puzzleEngine.currentPuzzle else {
            return AnyView(EmptyView())
        }

        return AnyView(
            VStack(spacing: 12) {
                Text("Selecciona un número (1-\(puzzle.gridSize))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.logosTextPrimary)

                // Grid de números
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: min(puzzle.gridSize, 5)), spacing: 8) {
                    ForEach(1...puzzle.gridSize, id: \.self) { number in
                        numberButton(number: number)
                    }

                    // Botón para borrar
                    Button {
                        if let cell = selectedCell {
                            viewModel.puzzleEngine.setCellValue(row: cell.row, col: cell.col, value: 0)
                        }
                        showingNumberPicker = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.logosError)
                            .frame(width: 50, height: 50)
                            .background(Color.logosCard)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
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

    // MARK: - Number Button
    private func numberButton(number: Int) -> some View {
        Button {
            if let cell = selectedCell {
                viewModel.puzzleEngine.setCellValue(row: cell.row, col: cell.col, value: number)
            }
            showingNumberPicker = false
        } label: {
            Text("\(number)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.logosPrimary)
                .frame(width: 50, height: 50)
                .background(Color.logosCard)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Stats View
    private var statsView: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "checkmark.circle.fill",
                label: "Progreso",
                value: progressPercentage
            )

            statCard(
                icon: "number.circle.fill",
                label: "Jaulas",
                value: "\(viewModel.puzzleEngine.currentPuzzle?.cages.count ?? 0)"
            )
        }
    }

    private func statCard(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.primaryGradient)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.logosTextPrimary)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.logosTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .liquidGlass()
    }

    // MARK: - Progress Percentage
    private var progressPercentage: String {
        guard let puzzle = viewModel.puzzleEngine.currentPuzzle else { return "0%" }

        let totalCells = puzzle.gridSize * puzzle.gridSize
        var filledCells = 0

        for row in 0..<puzzle.gridSize {
            for col in 0..<puzzle.gridSize {
                if viewModel.puzzleEngine.userGrid[row][col] > 0 {
                    filledCells += 1
                }
            }
        }

        let percentage = (filledCells * 100) / totalCells
        return "\(percentage)%"
    }

    // MARK: - Controls
    private var controlsView: some View {
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
                        Text("¡Perfecto!")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.logosTextPrimary)

                        Text("Has completado el Math Puzzle")
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
                                description: "Llena la cuadrícula con números del 1 al tamaño del grid. Cada número debe aparecer solo UNA VEZ por fila y columna (como Sudoku)."
                            )

                            instructionItem(
                                title: "Las Jaulas de Colores",
                                description: "Cada grupo de celdas con borde del mismo color es una JAULA. El número y símbolo en la esquina superior izquierda te dice:\n\n• El RESULTADO que deben dar esas celdas\n• La OPERACIÓN matemática (+, -, ×, ÷, =)\n\nEjemplo: \"5+\" significa que los números en esa jaula deben SUMAR 5."
                            )

                            instructionItem(
                                title: "Reglas Importantes",
                                description: "1. **Sin repetir:** Cada número solo puede aparecer UNA VEZ por fila\n2. **Sin repetir:** Cada número solo puede aparecer UNA VEZ por columna\n3. **Cumplir jaulas:** Los números en cada jaula deben dar el resultado con la operación indicada\n4. **Números en ROJO:** Significa que hay un conflicto (número repetido en fila/columna)"
                            )

                            instructionItem(
                                title: "Operaciones",
                                description: "• **+** (Suma): Los números suman al total\n• **×** (Multiplicación): Los números multiplicados dan el total\n• **-** (Resta): La diferencia entre el mayor y menor da el total\n• **÷** (División): El mayor dividido por el menor da el total\n• **=** (Igual): La celda debe tener exactamente ese número"
                            )

                            instructionItem(
                                title: "Estrategia",
                                description: "1. **Empieza por jaulas de 1 celda** (tienen el símbolo =)\n2. **Busca jaulas pequeñas** con pocas opciones\n3. **Usa el proceso de eliminación:** Si un número ya está en una fila/columna, no puede repetirse\n4. **Piensa en las combinaciones:** Por ejemplo, 5+ en 2 celdas solo puede ser 1+4 o 2+3\n5. **Los números en ROJO te avisan** cuando hay un error"
                            )

                            instructionItem(
                                title: "Dificultad",
                                description: "• **Nivel 1-2:** Cuadrículas pequeñas (4x4, 5x5) con operaciones simples\n• **Nivel 3-4:** Cuadrículas medianas (6x6, 7x7) con más operaciones\n• **Nivel 5:** Cuadrícula grande (8x8) con jaulas complejas - MUY DIFÍCIL"
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
