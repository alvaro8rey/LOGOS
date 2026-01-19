//
//  SudokuGameView.swift
//  LOGOS
//
//  Vista del puzzle Sudoku 9x9
//  El desafío definitivo de lógica pura
//

import SwiftUI

struct SudokuGameView: View {
    @StateObject var viewModel: SudokuPuzzleViewModel
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
                        // Sudoku grid
                        if let puzzle = viewModel.puzzleEngine.currentPuzzle {
                            sudokuGrid(puzzle: puzzle)
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
        .sheet(isPresented: $viewModel.puzzleEngine.showingBuyHintsSheet) {
            buyHintsSheet
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sudoku 9×9")
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

    // MARK: - Sudoku Grid
    private func sudokuGrid(puzzle: SudokuPuzzle) -> some View {
        let cellSize: CGFloat = getCellSize()

        return VStack(spacing: 0) {
            ForEach(0..<9, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { col in
                        cellView(row: row, col: col, puzzle: puzzle, cellSize: cellSize)
                    }
                }
            }
        }
        .padding(20)
        .liquidGlass()
    }

    // MARK: - Cell View
    private func cellView(row: Int, col: Int, puzzle: SudokuPuzzle, cellSize: CGFloat) -> some View {
        let userValue = viewModel.puzzleEngine.userGrid[row][col]
        let isInitial = puzzle.isInitialCell(row: row, col: col)
        let isSelected = selectedCell?.row == row && selectedCell?.col == col
        let hasConflict = viewModel.puzzleEngine.hasConflict(row: row, col: col)

        // Determinar grosor de borde
        let topBorderWidth: CGFloat = (row % 3 == 0) ? 3 : 1
        let leftBorderWidth: CGFloat = (col % 3 == 0) ? 3 : 1
        let bottomBorderWidth: CGFloat = (row == 8) ? 3 : 1
        let rightBorderWidth: CGFloat = (col == 8) ? 3 : 1

        return ZStack(alignment: .center) {
            // Background
            Rectangle()
                .fill(
                    isSelected ? Color.logosPrimary.opacity(0.15) :
                    isInitial ? Color.logosCard.opacity(0.5) :
                    Color.logosCard
                )

            // Bordes Sudoku
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.logosTextPrimary.opacity(0.3))
                    .frame(height: topBorderWidth)
                Spacer()
                Rectangle()
                    .fill(Color.logosTextPrimary.opacity(0.3))
                    .frame(height: bottomBorderWidth)
            }

            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.logosTextPrimary.opacity(0.3))
                    .frame(width: leftBorderWidth)
                Spacer()
                Rectangle()
                    .fill(Color.logosTextPrimary.opacity(0.3))
                    .frame(width: rightBorderWidth)
            }

            // Número
            if userValue > 0 {
                Text("\(userValue)")
                    .font(.system(size: cellSize * 0.5, weight: isInitial ? .bold : .semibold, design: .rounded))
                    .foregroundColor(
                        hasConflict ? Color.logosError :
                        isInitial ? Color.logosTextPrimary :
                        Color.logosPrimary
                    )
            }
        }
        .frame(width: cellSize, height: cellSize)
        .onTapGesture {
            if !isInitial {
                selectedCell = (row, col)
                showingNumberPicker = true
            }
        }
    }

    // MARK: - Get Cell Size
    private func getCellSize() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 80
        return availableWidth / 9
    }

    // MARK: - Number Picker View
    private var numberPickerView: some View {
        VStack(spacing: 12) {
            Text("Selecciona un número")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.logosTextPrimary)

            // Grid de números 1-9
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { number in
                        numberButton(number: number)
                    }
                }

                HStack(spacing: 8) {
                    ForEach(6...9, id: \.self) { number in
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
                            .font(.system(size: 20))
                            .foregroundColor(.logosError)
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
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.logosPrimary)
                .frame(width: 50, height: 50)
                .background(Color.logosCard)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
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

            Button {
                viewModel.puzzleEngine.useHint()
            } label: {
                HStack {
                    Image(systemName: "lightbulb.fill")
                    Text("Pista (\(viewModel.puzzleEngine.hintsAvailable))")
                }
                .frame(maxWidth: .infinity)
            }
            .liquidButton()
            .opacity(viewModel.puzzleEngine.hintsAvailable > 0 ? 1 : 0.5)
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

                        Text("Has resuelto el Sudoku correctamente")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.logosTextSecondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 16) {
                        statRow(icon: "clock.fill", label: "Tiempo", value: timeString)
                        statRow(icon: "lightbulb.fill", label: "Pistas", value: "\(viewModel.puzzleEngine.usedHintsCount)")
                    }
                    .padding(20)
                    .liquidGlass()
                    .padding(.horizontal, 30)

                    VStack(spacing: 12) {
                        Button {
                            viewModel.generateNewPuzzle()
                        } label: {
                            Text("Siguiente Sudoku")
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
                            Image(systemName: "square.grid.3x3")
                                .font(.system(size: 60))
                                .foregroundStyle(Color.primaryGradient)

                            Text("Cómo Jugar Sudoku")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.logosTextPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)

                        VStack(alignment: .leading, spacing: 16) {
                            instructionItem(
                                title: "El Desafío",
                                description: "Sudoku es un puzzle de lógica pura que requiere concentración y deducción. Es considerado uno de los puzzles más desafiantes del mundo."
                            )

                            instructionItem(
                                title: "Objetivo",
                                description: "Llena la cuadrícula 9×9 con números del 1 al 9, sin repetir números en:\n\n• Cada fila horizontal\n• Cada columna vertical\n• Cada cuadrante 3×3 (marcado con bordes gruesos)"
                            )

                            instructionItem(
                                title: "Reglas Fundamentales",
                                description: "1. Cada fila debe contener los números 1-9 exactamente una vez\n2. Cada columna debe contener los números 1-9 exactamente una vez\n3. Cada cuadrante 3×3 debe contener los números 1-9 exactamente una vez\n4. Los números en NEGRO son fijos y no se pueden cambiar\n5. Los números en AZUL son tus entradas"
                            )

                            instructionItem(
                                title: "Cómo Jugar",
                                description: "1. Toca una celda vacía para seleccionarla\n2. Aparecerá un selector con números del 1-9\n3. Elige el número que crees que va en esa celda\n4. Si un número se vuelve ROJO, significa que hay un conflicto\n5. Usa la X para borrar un número incorrecto"
                            )

                            instructionItem(
                                title: "Estrategias Avanzadas",
                                description: "• ELIMINACIÓN: Si 8 números están en una fila, el 9º es el faltante\n• ÚNICO CANDIDATO: Si solo un número puede ir en una celda, ese es el correcto\n• ESCANEO DE CUADRANTES: Busca números que solo pueden ir en una posición\n• NÚMEROS OCULTOS: A veces un número solo puede ir en una celda aunque no sea obvio\n• PARES Y TRIPLES: Si dos celdas solo pueden tener 2 números, elimínalos de otras celdas"
                            )

                            instructionItem(
                                title: "Dificultad",
                                description: "• FÁCIL (Nivel 1): 46 números visibles\n• MEDIO (Nivel 2): 39 números visibles\n• DIFÍCIL (Nivel 3): 33 números visibles\n• EXPERTO (Nivel 4): 27 números visibles\n• MAESTRO (Nivel 5): 21 números visibles - EXTREMADAMENTE DIFÍCIL"
                            )

                            instructionItem(
                                title: "Consejos",
                                description: "• Empieza con las filas, columnas o cuadrantes que tienen más números\n• Busca patrones obvios antes de adivinar\n• NUNCA adivines - Sudoku se resuelve con lógica pura\n• Si te atascas, usa una pista para desbloquearte\n• La paciencia es clave - los sudokus difíciles pueden tomar 30+ minutos"
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

    // MARK: - Buy Hints Sheet
    private var buyHintsSheet: some View {
        NavigationView {
            ZStack {
                Color.logosBackground
                    .ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer()

                    Image(systemName: "lightbulb.slash.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.logosWarning)

                    VStack(spacing: 12) {
                        Text("Sin Pistas")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.logosTextPrimary)

                        Text("Has usado tu pista gratuita para este puzzle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.logosTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }

                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text("💡 Paquete de 5 Pistas")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.logosTextPrimary)

                            Text("$0.99")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.accentGradient)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .liquidGlass()
                        .padding(.horizontal, 30)

                        Button {
                            // TODO: Implementar compra IAP
                            print("🛒 Comprar pistas - IAP no implementado aún")
                            viewModel.puzzleEngine.showingBuyHintsSheet = false
                        } label: {
                            Text("Comprar Pistas")
                                .frame(maxWidth: .infinity)
                        }
                        .liquidButton()
                        .padding(.horizontal, 30)

                        Button {
                            viewModel.puzzleEngine.showingBuyHintsSheet = false
                        } label: {
                            Text("Continuar sin Pistas")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.logosTextSecondary)
                        }
                        .padding(.top, 8)
                    }

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.puzzleEngine.showingBuyHintsSheet = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.logosTextTertiary)
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
        SudokuGameView(
            viewModel: SudokuPuzzleViewModel(
                puzzleType: .logic,
                difficulty: 3,
                userId: "preview-user"
            )
        )
    }
}
