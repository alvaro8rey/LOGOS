//
//  NonogramGameView.swift
//  LOGOS
//
//  Created by alvaro on 16/1/26.
//


//
//  NonogramGameView.swift
//  Logos
//
//  Vista del juego Nonogram
//

import SwiftUI

struct NonogramGameView: View {
    @StateObject var viewModel: PuzzleViewModel
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
                            nonogramGrid(puzzle: puzzle)
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
        .sheet(isPresented: $viewModel.showingHintSheet) {
            hintSheet
        }
        .sheet(isPresented: $viewModel.showingCompletionSheet) {
            completionSheet
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Nonogram")
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
            
            // Hints remaining
            VStack(spacing: 4) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.accentGradient)
                
                Text("\(viewModel.freeHintsRemaining)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.logosTextPrimary)
            }
        }
        .padding(.horizontal)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            // Forzar actualización del tiempo
            if !viewModel.puzzleEngine.isCompleted {
                viewModel.puzzleEngine.objectWillChange.send()
            }
        }
    }
    
    // MARK: - Nonogram Grid
    private func nonogramGrid(puzzle: NonogramPuzzle) -> some View {
        let cellSize: CGFloat = getCellSize(gridSize: puzzle.gridSize)
        
        return VStack(spacing: 0) {
            // Column hints
            HStack(spacing: 0) {
                // Empty corner
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: cellSize * 2, height: cellSize * 2)
                
                // Column numbers
                ForEach(0..<puzzle.gridSize, id: \.self) { col in
                    VStack(spacing: 2) {
                        ForEach(puzzle.columnHints[col], id: \.self) { hint in
                            Text("\(hint)")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(.logosTextSecondary)
                        }
                    }
                    .frame(width: cellSize, height: cellSize * 2)
                }
            }
            
            // Grid with row hints
            ForEach(0..<puzzle.gridSize, id: \.self) { row in
                HStack(spacing: 0) {
                    // Row hints
                    HStack(spacing: 2) {
                        ForEach(puzzle.rowHints[row], id: \.self) { hint in
                            Text("\(hint)")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(.logosTextSecondary)
                        }
                    }
                    .frame(width: cellSize * 2, height: cellSize)
                    
                    // Cells
                    ForEach(0..<puzzle.gridSize, id: \.self) { col in
                        cellView(row: row, col: col, size: cellSize)
                            .id("\(row)-\(col)")  // Unique ID for each cell
                    }
                }
            }
        }
        .padding(20)
        .liquidGlass()
    }
    
    // MARK: - Cell View
    private func cellView(row: Int, col: Int, size: CGFloat) -> some View {
        let state = viewModel.puzzleEngine.userGrid[row][col]

        return ZStack {
            Rectangle()
                .fill(cellColor(for: state))
                .frame(width: size, height: size)

            Rectangle()
                .stroke(Color.logosTextTertiary.opacity(0.3), lineWidth: 1)
                .frame(width: size, height: size)

            if state == .marked {
                Image(systemName: "xmark")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundColor(.logosTextSecondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.puzzleEngine.toggleCell(row: row, col: col)
        }
        .disabled(viewModel.puzzleEngine.isCompleted)
    }
    
    // MARK: - Cell Color
    private func cellColor(for state: NonogramPuzzle.CellState) -> Color {
        switch state {
        case .empty:
            return Color.logosCard
        case .filled:
            return Color.logosPrimary
        case .marked:
            return Color.logosCard
        }
    }
    
    // MARK: - Get Cell Size
    private func getCellSize(gridSize: Int) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 100 // Margins and hints space
        let maxCellSize: CGFloat = 40
        let calculatedSize = availableWidth / CGFloat(gridSize + 2)
        return min(calculatedSize, maxCellSize)
    }
    
    // MARK: - Controls
    private var controlsView: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.showingHintSheet = true
            } label: {
                HStack {
                    Image(systemName: "lightbulb.fill")
                    Text("Pista")
                }
                .frame(maxWidth: .infinity)
            }
            .liquidButton(isEnabled: viewModel.canUseHint && !viewModel.puzzleEngine.isCompleted)
            .disabled(!viewModel.canUseHint || viewModel.puzzleEngine.isCompleted)
            
            Button {
                viewModel.puzzleEngine.resetPuzzle()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reiniciar")
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.logosCard)
                )
                .foregroundColor(.logosTextPrimary)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
        }
    }
    
    // MARK: - Time String
    private var timeString: String {
        let time = viewModel.puzzleEngine.getElapsedTime()
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Hint Sheet
    private var hintSheet: some View {
        NavigationView {
            ZStack {
                Color.logosBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(Array(viewModel.puzzleEngine.availableHints.enumerated()), id: \.element.id) { index, hint in
                            hintCard(hint: hint, index: index)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Pistas Disponibles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        viewModel.showingHintSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Hint Card
    private func hintCard(hint: Hint, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: hintIcon(for: hint.type))
                    .font(.system(size: 24))
                    .foregroundStyle(hintColor(for: hint.type))
                
                Text(hintTitle(for: hint.type))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.logosTextPrimary)
                
                Spacer()
                
                if index == 0 && viewModel.freeHintsRemaining > 0 {
                    Text("GRATIS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.logosSuccess)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.logosSuccess.opacity(0.1))
                        )
                }
            }
            
            Text(hint.message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.logosTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            if index == 0 || viewModel.freeHintsRemaining > 0 {
                Button {
                    viewModel.useHint(hint)
                    viewModel.showingHintSheet = false
                } label: {
                    Text("Usar Pista")
                        .frame(maxWidth: .infinity)
                }
                .liquidButton()
            } else {
                Button {
                    // TODO: Mostrar tienda
                } label: {
                    HStack {
                        Image(systemName: "cart.fill")
                        Text("Comprar Pista")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.logosWarning.opacity(0.2))
                    )
                    .foregroundColor(.logosWarning)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
            }
        }
        .padding(20)
        .liquidGlass()
    }
    
    // MARK: - Hint Helpers
    private func hintIcon(for type: Hint.HintType) -> String {
        switch type {
        case .conceptual: return "book.fill"
        case .partial: return "eye.fill"
        case .logical: return "brain.head.profile"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    private func hintColor(for type: Hint.HintType) -> LinearGradient {
        switch type {
        case .conceptual: return Color.primaryGradient
        case .partial: return Color.accentGradient
        case .logical: return Color.primaryGradient
        case .error: return LinearGradient(colors: [.logosWarning, .logosError], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    private func hintTitle(for type: Hint.HintType) -> String {
        switch type {
        case .conceptual: return "Concepto"
        case .partial: return "Revelación Parcial"
        case .logical: return "Paso Lógico"
        case .error: return "Detectar Error"
        }
    }
    
    // MARK: - Completion Sheet
    private var completionSheet: some View {
        NavigationView {
            ZStack {
                Color.logosBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Success icon
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.accentGradient)
                    
                    VStack(spacing: 12) {
                        Text("¡Completado!")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.logosTextPrimary)
                        
                        Text("Has resuelto el puzzle correctamente")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.logosTextSecondary)
                    }
                    
                    // Stats
                    VStack(spacing: 16) {
                        statRow(icon: "clock.fill", label: "Tiempo", value: timeString)
                        statRow(icon: "lightbulb.fill", label: "Pistas usadas", value: "\(viewModel.puzzleEngine.usedHintsCount)")
                    }
                    .padding(20)
                    .liquidGlass()
                    .padding(.horizontal, 30)
                    
                    // Actions
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.logosTextSecondary)
                    }
                }
            }
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
                            Image(systemName: "square.grid.3x3.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(Color.primaryGradient)

                            Text("Cómo Jugar Nonogram")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.logosTextPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)

                        VStack(alignment: .leading, spacing: 16) {
                            instructionItem(
                                title: "Objetivo",
                                description: "Descubre la imagen oculta rellenando las celdas correctas según las pistas numéricas."
                            )

                            instructionItem(
                                title: "Pistas Numéricas",
                                description: "Los números en cada fila y columna indican cuántos grupos de celdas consecutivas deben rellenarse.\n\nEjemplo: [2, 1] significa 2 celdas juntas, luego al menos 1 espacio vacío, y después 1 celda."
                            )

                            instructionItem(
                                title: "Cómo Marcar",
                                description: "• Toca una celda una vez: Rellena (negro)\n• Toca dos veces: Marca con X (vacía)\n• Toca tres veces: Vuelve a vacío"
                            )

                            instructionItem(
                                title: "Estrategia",
                                description: "1. Comienza con las filas/columnas que tengan números grandes\n2. Si el número es igual al tamaño, rellena toda la fila/columna\n3. Marca con X las celdas que sabes que están vacías"
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
        NonogramGameView(
            viewModel: PuzzleViewModel(
                puzzleType: .constraints,
                difficulty: 1,
                userId: "preview-user"
            )
        )
    }
}
