//
//  UserProgress.swift
//  Logos
//
//  Progreso del usuario por tipo de puzzle
//

import Foundation

struct UserProgress: Codable, Identifiable {

    let id: String
    let userId: String
    let puzzleType: PuzzleType

    var completedCount: Int
    var currentDifficulty: Int
    var bestTime: TimeInterval?
    var totalHintsUsed: Int
    var lastPlayedAt: Date?
    var updatedAt: Date

    // MARK: - Puzzle Type

    enum PuzzleType: String, Codable, CaseIterable {
        case constraints = "constraints"
        case graphs = "graphs"
        case binaryStates = "binary_states"
        case mathematical = "mathematical"
        case symmetry = "symmetry"
        case logic = "logic"

        var displayName: String {
            switch self {
            case .constraints: return "Restricciones"
            case .graphs: return "Grafos y Caminos"
            case .binaryStates: return "Estados Binarios"
            case .mathematical: return "Matemático"
            case .symmetry: return "Simetría"
            case .logic: return "Lógica Pura"
            }
        }

        var icon: String {
            switch self {
            case .constraints: return "square.grid.3x3"
            case .graphs: return "point.3.connected.trianglepath.dotted"
            case .binaryStates: return "circle.hexagongrid"
            case .mathematical: return "function"
            case .symmetry: return "square.split.diagonal"
            case .logic: return "square.grid.3x3.fill"
            }
        }
    }

    // MARK: - Initializers

    /// Init para progreso NUEVO (usuario empieza un puzzle)
    init(userId: String, puzzleType: PuzzleType) {
        self.id = UUID().uuidString
        self.userId = userId
        self.puzzleType = puzzleType
        self.completedCount = 0
        self.currentDifficulty = 1
        self.bestTime = nil
        self.totalHintsUsed = 0
        self.lastPlayedAt = nil
        self.updatedAt = Date()
    }

    /// Init para reconstruir desde Core Data / Backend
    init(
        id: String,
        userId: String,
        puzzleType: PuzzleType,
        completedCount: Int = 0,
        currentDifficulty: Int = 1,
        bestTime: TimeInterval? = nil,
        totalHintsUsed: Int = 0,
        lastPlayedAt: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.puzzleType = puzzleType
        self.completedCount = completedCount
        self.currentDifficulty = currentDifficulty
        self.bestTime = bestTime
        self.totalHintsUsed = totalHintsUsed
        self.lastPlayedAt = lastPlayedAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Supabase Mapping
extension UserProgress {

    func toSupabaseDict() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "user_id": userId,
            "puzzle_type": puzzleType.rawValue,
            "completed_count": completedCount,
            "current_difficulty": currentDifficulty,
            "total_hints_used": totalHintsUsed,
            "updated_at": ISO8601DateFormatter().string(from: updatedAt)
        ]

        if let bestTime = bestTime {
            dict["best_time"] = bestTime
        }

        if let lastPlayedAt = lastPlayedAt {
            dict["last_played_at"] = ISO8601DateFormatter().string(from: lastPlayedAt)
        }

        return dict
    }
}

