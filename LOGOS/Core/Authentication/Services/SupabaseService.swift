//
//  SupabaseService.swift
//  Logos
//
//  Servicio de base de datos con Supabase (CORREGIDO)
//

import Foundation
import Supabase

enum SupabaseError: LocalizedError {
    case notConfigured
    case insertFailed
    case updateFailed
    case fetchFailed
    case deleteFailed
    case unauthorized
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase no está configurado"
        case .insertFailed:
            return "Error al insertar datos"
        case .updateFailed:
            return "Error al actualizar datos"
        case .fetchFailed:
            return "Error al obtener datos"
        case .deleteFailed:
            return "Error al eliminar datos"
        case .unauthorized:
            return "No autorizado"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

@MainActor
class SupabaseService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = SupabaseService()
    
    // MARK: - Properties
    private(set) var client: SupabaseClient?
    @Published var isConfigured = false
    
    private init() {
        configure()
    }
    
    // MARK: - Configuration
    private func configure() {
        guard AppConstants.Supabase.url != "YOUR_SUPABASE_URL" else {
            print("⚠️ Supabase no configurado. Actualiza las credenciales en AppConstants.swift")
            return
        }
        
        guard let url = URL(string: AppConstants.Supabase.url) else {
            print("❌ URL de Supabase inválida")
            return
        }
        
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: AppConstants.Supabase.anonKey
        )
        isConfigured = true
        print("✅ Supabase configurado correctamente")
    }
    
    // MARK: - User Operations
    
    /// Crear o actualizar usuario en Supabase
    func upsertUser(_ user: User) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        
        do {
            let userData = user.toSupabaseDict()
            
            try await client
                .from("users")
                .upsert(user)
                .execute()
            
            print("✅ Usuario guardado en Supabase: \(user.id)")
        } catch {
            print("❌ Error al guardar usuario: \(error)")
            throw SupabaseError.insertFailed
        }
    }
    
    /// Obtener usuario desde Supabase
    func fetchUser(userId: String) async throws -> User? {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        
        do {
            let response: [User] = try await client
                .from("users")
                .select()
                .eq("id", value: userId)
                .execute()
                .value
            
            return response.first
        } catch {
            print("❌ Error al obtener usuario: \(error)")
            throw SupabaseError.fetchFailed
        }
    }
    
    /// Eliminar usuario de Supabase
    func deleteUser(userId: String) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        
        do {
            try await client
                .from("users")
                .delete()
                .eq("id", value: userId)
                .execute()
            
            print("✅ Usuario eliminado de Supabase: \(userId)")
        } catch {
            print("❌ Error al eliminar usuario: \(error)")
            throw SupabaseError.deleteFailed
        }
    }
    
    // MARK: - Progress Operations

    // DTO para progreso (evita problemas de conversión de tipos)
    private struct UserProgressDTO: Codable {
        let id: String
        let user_id: String
        let puzzle_type: String
        let completed_count: Int
        let current_difficulty: Int
        let best_time: Double?
        let total_hints_used: Int
        let last_played_at: String?
        let updated_at: String
    }

    /// Guardar progreso del usuario
    func upsertProgress(_ progress: UserProgress) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        do {
            let dto = UserProgressDTO(
                id: progress.id,
                user_id: progress.userId,
                puzzle_type: progress.puzzleType.rawValue,
                completed_count: progress.completedCount,
                current_difficulty: progress.currentDifficulty,
                best_time: progress.bestTime,
                total_hints_used: progress.totalHintsUsed,
                last_played_at: progress.lastPlayedAt.map { ISO8601DateFormatter().string(from: $0) },
                updated_at: ISO8601DateFormatter().string(from: progress.updatedAt)
            )

            try await client
                .from("user_progress")
                .upsert(dto)
                .execute()

            print("✅ Progreso guardado: \(progress.puzzleType.rawValue)")
        } catch {
            print("❌ Error al guardar progreso: \(error)")
            throw SupabaseError.insertFailed
        }
    }
    
    /// Obtener todo el progreso de un usuario
    func fetchUserProgress(userId: String) async throws -> [UserProgress] {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        
        do {
            let response: [UserProgress] = try await client
                .from("user_progress")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            return response
        } catch {
            print("❌ Error al obtener progreso: \(error)")
            throw SupabaseError.fetchFailed
        }
    }
    
    /// Obtener progreso específico por tipo de puzzle
    func fetchProgress(userId: String, puzzleType: UserProgress.PuzzleType) async throws -> UserProgress? {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }
        
        do {
            let response: [UserProgress] = try await client
                .from("user_progress")
                .select()
                .eq("user_id", value: userId)
                .eq("puzzle_type", value: puzzleType.rawValue)
                .execute()
                .value
            
            return response.first
        } catch {
            print("❌ Error al obtener progreso específico: \(error)")
            throw SupabaseError.fetchFailed
        }
    }
    
    // MARK: - Batch Operations

    /// Guardar múltiples progresos a la vez
    func batchUpsertProgress(_ progressList: [UserProgress]) async throws {
        guard let client = client else {
            throw SupabaseError.notConfigured
        }

        do {
            let dtos = progressList.map { progress in
                UserProgressDTO(
                    id: progress.id,
                    user_id: progress.userId,
                    puzzle_type: progress.puzzleType.rawValue,
                    completed_count: progress.completedCount,
                    current_difficulty: progress.currentDifficulty,
                    best_time: progress.bestTime,
                    total_hints_used: progress.totalHintsUsed,
                    last_played_at: progress.lastPlayedAt.map { ISO8601DateFormatter().string(from: $0) },
                    updated_at: ISO8601DateFormatter().string(from: progress.updatedAt)
                )
            }

            try await client
                .from("user_progress")
                .upsert(dtos)
                .execute()

            print("✅ \(progressList.count) registros de progreso guardados")
        } catch {
            print("❌ Error al guardar múltiples progresos: \(error)")
            throw SupabaseError.insertFailed
        }
    }
}
