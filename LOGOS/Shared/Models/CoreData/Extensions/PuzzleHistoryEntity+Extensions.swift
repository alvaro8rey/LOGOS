//
//  PuzzleHistoryEntity+Extensions.swift
//  Logos
//
//  Extensiones para PuzzleHistoryEntity
//

import CoreData
import Foundation

extension PuzzleHistoryEntity {
    
    /// Convierte a modelo de dominio
    func toDomainModel() -> PuzzleHistory? {
        guard
            let id = id,
            let userId = userId,
            let puzzleTypeString = puzzleType,
            let puzzleType = UserProgress.PuzzleType(rawValue: puzzleTypeString),
            let seed = seed,
            let completedAt = completedAt
        else {
            return nil
        }

        return PuzzleHistory(
            id: id,
            userId: userId,
            puzzleType: puzzleType,
            seed: seed,
            difficulty: Int(difficulty),
            completedAt: completedAt,
            timeSpent: timeSpent,
            hintsUsed: Int(hintsUsed),
            isSolved: isSolved
        )
    }

    
    /// Actualiza desde modelo de dominio
    func update(from history: PuzzleHistory) {
        self.id = history.id
        self.userId = history.userId
        self.puzzleType = history.puzzleType.rawValue
        self.seed = history.seed
        self.difficulty = Int32(history.difficulty)
        self.completedAt = history.completedAt
        self.timeSpent = history.timeSpent
        self.hintsUsed = Int32(history.hintsUsed)
        self.isSolved = history.isSolved
        self.lastModified = Date()
        self.needsSync = true
    }
    
    /// Crear historial
    static func create(
        history: PuzzleHistory,
        in context: NSManagedObjectContext
    ) -> PuzzleHistoryEntity {
        let entity = PuzzleHistoryEntity(context: context)
        entity.update(from: history)
        return entity
    }
    
    /// Obtener historial de un usuario
    static func fetchHistory(
        userId: String,
        limit: Int? = nil,
        in context: NSManagedObjectContext
    ) -> [PuzzleHistoryEntity] {
        let fetchRequest: NSFetchRequest<PuzzleHistoryEntity> = PuzzleHistoryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]
        
        if let limit = limit {
            fetchRequest.fetchLimit = limit
        }
        
        return (try? context.fetch(fetchRequest)) ?? []
    }
    
    /// Obtener historial que necesita sincronización
    static func fetchPendingSync(
        in context: NSManagedObjectContext
    ) -> [PuzzleHistoryEntity] {
        let fetchRequest: NSFetchRequest<PuzzleHistoryEntity> = PuzzleHistoryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "needsSync == YES")
        
        return (try? context.fetch(fetchRequest)) ?? []
    }
}
