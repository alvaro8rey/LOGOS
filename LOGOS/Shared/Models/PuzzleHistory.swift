//
//  PuzzleHistory.swift
//  Logos
//
//  Historial de puzzles completados
//

import Foundation

struct PuzzleHistory: Encodable, Identifiable {
    
    // MARK: - Properties
    let id: String
    let userId: String
    let puzzleType: UserProgress.PuzzleType
    let seed: String
    let difficulty: Int
    let completedAt: Date
    let timeSpent: TimeInterval
    let hintsUsed: Int
    let isSolved: Bool
    
    // MARK: - Init para crear historial NUEVO (juego terminado)
    init(
        userId: String,
        puzzleType: UserProgress.PuzzleType,
        seed: String,
        difficulty: Int,
        timeSpent: TimeInterval,
        hintsUsed: Int,
        isSolved: Bool
    ) {
        self.id = UUID().uuidString
        self.userId = userId
        self.puzzleType = puzzleType
        self.seed = seed
        self.difficulty = difficulty
        self.completedAt = Date()
        self.timeSpent = timeSpent
        self.hintsUsed = hintsUsed
        self.isSolved = isSolved
    }
    
    // MARK: - Init para reconstruir desde CoreData / Supabase
    init(
        id: String,
        userId: String,
        puzzleType: UserProgress.PuzzleType,
        seed: String,
        difficulty: Int,
        completedAt: Date,
        timeSpent: TimeInterval,
        hintsUsed: Int,
        isSolved: Bool
    ) {
        self.id = id
        self.userId = userId
        self.puzzleType = puzzleType
        self.seed = seed
        self.difficulty = difficulty
        self.completedAt = completedAt
        self.timeSpent = timeSpent
        self.hintsUsed = hintsUsed
        self.isSolved = isSolved
    }
}
