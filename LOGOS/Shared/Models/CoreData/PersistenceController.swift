//
//  PersistenceController.swift
//  Logos
//
//  Core Data Stack Controller
//

import CoreData
import Foundation

class PersistenceController: ObservableObject {
    
    // MARK: - Singleton
    static let shared = PersistenceController()
    
    // MARK: - Preview (para SwiftUI Previews)
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        // Crear datos de ejemplo
        let user = UserEntity(context: viewContext)
        user.id = "preview-user"
        user.email = "preview@logos.com"
        user.displayName = "Preview User"
        user.isAnonymous = false
        user.createdAt = Date()
        user.hintsAvailable = 10
        user.isPremium = true
        user.lastModified = Date()
        
        do {
            try viewContext.save()
        } catch {
            print("❌ Error creating preview data: \(error)")
        }
        
        return controller
    }()
    
    // MARK: - Container
    let container: NSPersistentContainer
    
    // MARK: - Context
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    // MARK: - Initialization
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "LogosDataModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Configuración del contenedor
        container.persistentStoreDescriptions.first?.setOption(
            true as NSNumber,
            forKey: NSPersistentHistoryTrackingKey
        )
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("❌ Error loading Core Data: \(error)")
            }
            print("✅ Core Data cargado: \(description)")
        }
        
        // Configurar contexto
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        print("✅ PersistenceController inicializado")
    }
    
    // MARK: - Save Context
    func save() {
        let context = container.viewContext
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            print("✅ Contexto guardado")
        } catch {
            print("❌ Error guardando contexto: \(error)")
        }
    }
    
    // MARK: - Background Context
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Delete All Data
    func deleteAllData() {
        let context = container.viewContext
        
        let entities = ["UserEntity", "UserProgressEntity", "PuzzleHistoryEntity"]
        
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
                print("✅ Datos de \(entityName) eliminados")
            } catch {
                print("❌ Error eliminando \(entityName): \(error)")
            }
        }
        
        save()
    }
}
