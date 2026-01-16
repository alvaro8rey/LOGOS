//
//  UserEntity+Extensions.swift
//  Logos
//
//  Extensiones para UserEntity
//

import CoreData
import Foundation

extension UserEntity {
    
    /// Convierte UserEntity a User (modelo de dominio)
    func toDomainModel() -> User {
        var user = User(
            id: id ?? "",
            email: email,
            displayName: displayName,
            isAnonymous: isAnonymous
        )
        
        user.createdAt = createdAt ?? Date()
        user.lastSyncAt = lastSyncAt
        user.hintsAvailable = Int(hintsAvailable)
        user.isPremium = isPremium
        
        if let subType = subscriptionType {
            user.subscriptionType = User.SubscriptionType(rawValue: subType)
        }
        
        user.subscriptionExpiresAt = subscriptionExpiresAt
        
        return user
    }
    
    /// Actualiza UserEntity desde User (modelo de dominio)
    func update(from user: User) {
        self.id = user.id
        self.email = user.email
        self.displayName = user.displayName
        self.isAnonymous = user.isAnonymous
        self.createdAt = user.createdAt
        self.lastSyncAt = user.lastSyncAt
        self.hintsAvailable = Int32(user.hintsAvailable)
        self.isPremium = user.isPremium
        self.subscriptionType = user.subscriptionType?.rawValue
        self.subscriptionExpiresAt = user.subscriptionExpiresAt
        self.lastModified = Date()
    }
    
    /// Crear o actualizar usuario
    static func createOrUpdate(
        user: User,
        in context: NSManagedObjectContext
    ) -> UserEntity {
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", user.id)
        
        if let existingUser = try? context.fetch(fetchRequest).first {
            existingUser.update(from: user)
            return existingUser
        } else {
            let newUser = UserEntity(context: context)
            newUser.update(from: user)
            return newUser
        }
    }
    
    /// Obtener usuario por ID
    static func fetch(
        byId id: String,
        in context: NSManagedObjectContext
    ) -> UserEntity? {
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        fetchRequest.fetchLimit = 1
        
        return try? context.fetch(fetchRequest).first
    }
}
