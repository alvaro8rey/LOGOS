//
//  Puzzle.swift
//  LOGOS
//
//  Created by alvaro on 16/1/26.
//


//
//  Puzzle.swift
//  Logos
//
//  Modelo base para puzzles
//

import Foundation

protocol Puzzle: Codable, Identifiable {
    var id: String { get }
    var seed: String { get }
    var puzzleType: UserProgress.PuzzleType { get }
    var difficulty: Int { get }
    var createdAt: Date { get }
    
    func isValid() -> Bool
    func isSolved(with solution: Any) -> Bool
}

// MARK: - Puzzle State
struct PuzzleState: Codable {
    let puzzleId: String
    let userId: String
    var startedAt: Date
    var currentProgress: Data // Serialized puzzle-specific data
    var hintsUsed: Int
    var isCompleted: Bool
    var completedAt: Date?
    var elapsedTime: TimeInterval
    
    init(puzzleId: String, userId: String) {
        self.puzzleId = puzzleId
        self.userId = userId
        self.startedAt = Date()
        self.currentProgress = Data()
        self.hintsUsed = 0
        self.isCompleted = false
        self.elapsedTime = 0
    }
}

// MARK: - Hint
struct Hint: Identifiable, Codable {
    let id: String
    let type: HintType
    let message: String
    let specificData: [String: String]? // Datos específicos del puzzle
    
    enum HintType: String, Codable {
        case conceptual // Explica el concepto general
        case partial    // Muestra parte de la solución
        case logical    // Da un paso lógico
        case error      // Detecta un error
    }
    
    init(type: HintType, message: String, specificData: [String: String]? = nil) {
        self.id = UUID().uuidString
        self.type = type
        self.message = message
        self.specificData = specificData
    }
}
