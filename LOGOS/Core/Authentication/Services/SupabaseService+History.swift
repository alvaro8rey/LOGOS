//
//  SupabaseService+History.swift
//  Logos
//
//  Historial de puzzles en Supabase
//

import Foundation
import Supabase

// MARK: - DTO para Supabase

private struct PuzzleHistoryDTO: Codable {
    let id: String
    let user_id: String
    let puzzle_type: String
    let seed: String
    let difficulty: Int
    let completed_at: String
    let time_spent: Double
    let hints_used: Int
    let is_solved: Bool
}

// MARK: - History Operations

extension SupabaseService {

    /// Insertar historial de puzzle
    func insertPuzzleHistory(_ history: PuzzleHistory) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        let dto = PuzzleHistoryDTO(
            id: history.id,
            user_id: history.userId,
            puzzle_type: history.puzzleType.rawValue,   // enum → String
            seed: history.seed,
            difficulty: history.difficulty,
            completed_at: ISO8601DateFormatter().string(from: history.completedAt),
            time_spent: history.timeSpent,
            hints_used: history.hintsUsed,
            is_solved: history.isSolved
        )

        do {
            try await client
                .from("puzzle_history")
                .insert(dto)
                .execute()
        } catch {
            print("❌ Error insertando historial: \(error)")
            throw SupabaseError.insertFailed
        }
    }

    /// Obtener historial de puzzles de un usuario
    func fetchPuzzleHistory(
        userId: String,
        limit: Int = 50
    ) async throws -> [PuzzleHistory] {

        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        do {
            let response = try await client
                .from("puzzle_history")
                .select()
                .eq("user_id", value: userId)
                .order("completed_at", ascending: false)
                .limit(limit)
                .execute()

            let decoder = JSONDecoder()
            let dtos = try decoder.decode([PuzzleHistoryDTO].self, from: response.data)

            return dtos.map {
                PuzzleHistory(
                    id: $0.id,
                    userId: $0.user_id,
                    puzzleType: UserProgress.PuzzleType(rawValue: $0.puzzle_type) ?? .constraints,
                    seed: $0.seed,
                    difficulty: $0.difficulty,
                    completedAt: ISO8601DateFormatter().date(from: $0.completed_at) ?? Date(),
                    timeSpent: $0.time_spent,
                    hintsUsed: $0.hints_used,
                    isSolved: $0.is_solved
                )
            }

        } catch {
            print("❌ Error obteniendo historial: \(error)")
            throw SupabaseError.fetchFailed
        }
    }
}
