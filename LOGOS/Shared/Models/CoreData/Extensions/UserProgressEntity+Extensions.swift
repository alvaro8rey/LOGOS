//
//  UserProgressEntity+Extensions.swift
//  LOGOS
//
//  Extensiones Core Data para UserProgressEntity
//

import Foundation
import CoreData

extension UserProgressEntity {

    // MARK: - Core Data → Domain

    /// Convierte UserProgressEntity a UserProgress (modelo de dominio)
    func toDomainModel() -> UserProgress? {
        guard
            let id = id,
            let userId = userId,
            let puzzleTypeString = puzzleType,
            let puzzleType = UserProgress.PuzzleType(rawValue: puzzleTypeString)
        else {
            return nil
        }

        var progress = UserProgress(
            id: id,
            userId: userId,
            puzzleType: puzzleType
        )

        progress.completedCount = Int(completedCount)
        progress.currentDifficulty = Int(currentDifficulty)
        progress.bestTime = bestTime == 0 ? nil : bestTime
        progress.totalHintsUsed = Int(totalHintsUsed)
        progress.lastPlayedAt = lastPlayedAt
        progress.updatedAt = updatedAt!

        return progress
    }

    // MARK: - Domain → Core Data

    /// Actualiza la entidad desde el modelo de dominio
    func update(from progress: UserProgress) {
        self.id = progress.id
        self.userId = progress.userId
        self.puzzleType = progress.puzzleType.rawValue
        self.completedCount = Int32(progress.completedCount)
        self.currentDifficulty = Int32(progress.currentDifficulty)
        self.bestTime = progress.bestTime ?? 0
        self.totalHintsUsed = Int32(progress.totalHintsUsed)
        self.lastPlayedAt = progress.lastPlayedAt
        self.updatedAt = progress.updatedAt
        self.lastModified = Date()
        self.needsSync = true
    }

    // MARK: - Factory

    /// Crea o actualiza el progreso para un usuario y tipo de puzzle
    static func createOrUpdate(
        progress: UserProgress,
        in context: NSManagedObjectContext
    ) -> UserProgressEntity {

        let request: NSFetchRequest<UserProgressEntity> = UserProgressEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "userId == %@ AND puzzleType == %@",
            progress.userId,
            progress.puzzleType.rawValue
        )
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            existing.update(from: progress)
            return existing
        } else {
            let entity = UserProgressEntity(context: context)
            entity.update(from: progress)
            return entity
        }
    }

    // MARK: - Fetch helpers

    /// Obtiene el progreso de un usuario para un tipo de puzzle
    static func fetch(
        userId: String,
        puzzleType: UserProgress.PuzzleType,
        in context: NSManagedObjectContext
    ) -> UserProgressEntity? {

        let request: NSFetchRequest<UserProgressEntity> = UserProgressEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "userId == %@ AND puzzleType == %@",
            userId,
            puzzleType.rawValue
        )
        request.fetchLimit = 1

        return try? context.fetch(request).first
    }

    /// Obtiene todo el progreso de un usuario
    static func fetchAll(
        userId: String,
        in context: NSManagedObjectContext
    ) -> [UserProgressEntity] {

        let request: NSFetchRequest<UserProgressEntity> = UserProgressEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        request.sortDescriptors = [
            NSSortDescriptor(key: "puzzleType", ascending: true)
        ]

        return (try? context.fetch(request)) ?? []
    }

    /// Obtiene entidades pendientes de sincronización
    static func fetchPendingSync(
        in context: NSManagedObjectContext
    ) -> [UserProgressEntity] {

        let request: NSFetchRequest<UserProgressEntity> = UserProgressEntity.fetchRequest()
        request.predicate = NSPredicate(format: "needsSync == YES")

        return (try? context.fetch(request)) ?? []
    }
}
