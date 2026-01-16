//
//  BinaryGameView.swift
//  LOGOS
//
//  Vista del puzzle de Estados Binarios: Binary
//

import SwiftUI

struct BinaryGameView: View {
    @StateObject var viewModel: BinaryPuzzleViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.logosBackground
                .ignoresSafeArea()

            VStack(spacing: 20) {
                headerView

                ScrollView {
                    VStack(spacing: 20) {
                        if let puzzle = viewModel.puzzleEngine.currentPuzzle {
                            binaryGrid(puzzle: puzzle)
                        }

                        controlsView
                    }
                    .padding()
                }
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
        .sheet(isPresented: $viewModel.showingCompletionSheet) {
            completionSheet
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Binary")
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

    // MARK: - Binary Grid
    private func binaryGrid(puzzle: BinaryPuzzle) -> some View {
        let cellSize: CGFloat = getCellSize(gridSize: puzzle.gridSize)

        return VStack(spacing: 2) {
            ForEach(0..<puzzle.gridSize, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<puzzle.gridSize, id: \.self) { col in
                        cellView(row: row, col: col, size: cellSize, puzzle: puzzle)
                    }
                }
            }
        }
        .padding(20)
        .liquidGlass()
    }

    // MARK: - Cell View
    private func cellView(row: Int, col: Int, size: CGFloat, puzzle: BinaryPuzzle) -> some View {
        let state = viewModel.puzzleEngine.userGrid[row][col]
        let isInitial = viewModel.puzzleEngine.isCellInitial(row: row, col: col)

        return ZStack {
            Rectangle()
                .fill(cellColor(for: state, isInitial: isInitial))
                .frame(width: size, height: size)

            if state != .empty {
                Text(state == .zero ? "0" : "1")
                    .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
                    .foregroundColor(isInitial ? .white : .logosTextPrimary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isInitial {
                viewModel.puzzleEngine.toggleCell(row: row, col: col)
            }
        }
    }

    // MARK: - Cell Color
    private func cellColor(for state: BinaryPuzzle.CellState, isInitial: Bool) -> Color {
        if isInitial {
            return state == .zero ? Color.logosPrimary.opacity(0.8) : Color.logosSecondary.opacity(0.8)
        }

        switch state {
        case .empty:
            return Color.logosCard
        case .zero:
            return Color.logosPrimary.opacity(0.3)
        case .one:
            return Color.logosSecondary.opacity(0.3)
        }
    }

    // MARK: - Get Cell Size
    private func getCellSize(gridSize: Int) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 80
        let maxCellSize: CGFloat = 40
        let calculatedSize = availableWidth / CGFloat(gridSize)
        return min(calculatedSize, maxCellSize)
    }

    // MARK: - Controls
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

                        Text("Has completado el puzzle binario correctamente")
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
}
