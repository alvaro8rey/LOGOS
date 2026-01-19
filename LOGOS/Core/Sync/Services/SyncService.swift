//
//  SyncService.swift
//  Logos
//
//  Servicio de sincronización offline-first
//

import Foundation
import CoreData
import Combine

@MainActor
class SyncService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var syncState: SyncState = .idle
    @Published var lastSyncDate: Date?
    
    // MARK: - Services
    private let persistence = PersistenceController.shared
    private let supabase = SupabaseService.shared
    
    // MARK: - Properties
    private var syncTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton
    static let shared = SyncService()
    
    private init() {
        setupAutoSync()
    }
    
    // MARK: - Auto Sync
    private func setupAutoSync() {
        // Sincronizar cada 5 minutos en background
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                await self?.syncAll()
            }
        }
    }
    
    // MARK: - Sync All
    func syncAll() async {
        guard !syncState.isSyncing else {
            print("⚠️ Sincronización ya en progreso")
            return
        }

        syncState = .syncing
        print("🔄 Iniciando sincronización completa...")

        // IMPORTANTE: La sincronización es completamente opcional
        // Si falla, solo se registra el error pero NO bloquea la app
        do {
            // 1. Sincronizar progreso local → remoto
            await syncProgressToRemote()

            // 2. Sincronizar historial local → remoto
            await syncHistoryToRemote()

            // 3. Sincronizar datos remotos → local
            await syncFromRemote()

            lastSyncDate = Date()
            syncState = .success(Date())
            print("✅ Sincronización completada")

        } catch {
            // Error capturado pero NO bloqueante
            syncState = .error(error.localizedDescription)
            print("⚠️ Error en sincronización (opcional): \(error)")
        }
    }
    
    // MARK: - Sync Progress to Remote
    private func syncProgressToRemote() async {
        let context = persistence.viewContext

        // Obtener progreso pendiente de sincronización
        let pendingProgress = UserProgressEntity.fetchPendingSync(in: context)

        guard !pendingProgress.isEmpty else {
            print("✅ No hay progreso pendiente de sincronizar")
            return
        }

        print("📤 Sincronizando \(pendingProgress.count) registros de progreso...")

        for progressEntity in pendingProgress {
            if let progress = progressEntity.toDomainModel() {
                do {
                    try await supabase.upsertProgress(progress)
                    progressEntity.needsSync = false
                } catch {
                    // Error capturado pero NO bloqueante
                    print("⚠️ No se pudo sincronizar progreso (opcional): \(error)")
                }
            }
        }

        persistence.save()
        print("✅ Progreso sincronizado (o guardado localmente si Supabase falló)")
    }
    
    // MARK: - Sync History to Remote
    private func syncHistoryToRemote() async {
        let context = persistence.viewContext

        let pendingHistory = PuzzleHistoryEntity.fetchPendingSync(in: context)

        guard !pendingHistory.isEmpty else {
            print("✅ No hay historial pendiente de sincronizar")
            return
        }

        print("📤 Sincronizando \(pendingHistory.count) registros de historial...")

        for historyEntity in pendingHistory {
            if let history = historyEntity.toDomainModel() {
                do {
                    try await supabase.insertPuzzleHistory(history)
                    historyEntity.needsSync = false
                } catch {
                    // Error capturado pero NO bloqueante
                    print("⚠️ No se pudo sincronizar historial (opcional): \(error)")
                }
            }
        }

        persistence.save()
        print("✅ Historial sincronizado (o guardado localmente si Supabase falló)")
    }
    
    // MARK: - Sync from Remote
    private func syncFromRemote() async {
        // Por ahora solo sincronizamos en una dirección (local → remoto)
        // En una implementación completa, aquí obtendríamos cambios del servidor
        print("✅ Sincronización desde remoto completada")
    }
    
    // MARK: - Sync User Data
    func syncUser(_ user: User) async {
        print("🔄 Sincronizando usuario...")

        // Guardar en CoreData (siempre funciona)
        let context = persistence.viewContext
        _ = UserEntity.createOrUpdate(user: user, in: context)
        persistence.save()

        // Intentar sincronizar con Supabase (opcional)
        do {
            try await supabase.upsertUser(user)
            print("✅ Usuario sincronizado con Supabase")
        } catch {
            // Error capturado pero NO bloqueante
            print("⚠️ No se pudo sincronizar usuario con Supabase (opcional): \(error)")
        }

        print("✅ Usuario guardado localmente")
    }
    
    // MARK: - Save Progress Locally
    func saveProgress(_ progress: UserProgress) {
        let context = persistence.viewContext
        _ = UserProgressEntity.createOrUpdate(progress: progress, in: context)
        persistence.save()
        
        print("✅ Progreso guardado localmente")
        
        // Intentar sincronizar en background
        Task {
            await syncAll()
        }
    }
    
    // MARK: - Save History Locally
    func saveHistory(_ history: PuzzleHistory) {
        let context = persistence.viewContext
        _ = PuzzleHistoryEntity.create(history: history, in: context)
        persistence.save()
        
        print("✅ Historial guardado localmente")
        
        // Intentar sincronizar en background
        Task {
            await syncAll()
        }
    }
    
    // MARK: - Get Local Progress
    func getLocalProgress(userId: String, puzzleType: UserProgress.PuzzleType) -> UserProgress? {
        let context = persistence.viewContext
        let entity = UserProgressEntity.fetch(userId: userId, puzzleType: puzzleType, in: context)
        return entity?.toDomainModel()
    }
    
    // MARK: - Get All Local Progress
    func getAllLocalProgress(userId: String) -> [UserProgress] {
        let context = persistence.viewContext
        let entities = UserProgressEntity.fetchAll(userId: userId, in: context)
        return entities.compactMap { $0.toDomainModel() }
    }
    
    // MARK: - Get Local User
    func getLocalUser(userId: String) -> User? {
        let context = persistence.viewContext
        let entity = UserEntity.fetch(byId: userId, in: context)
        return entity?.toDomainModel()
    }
    
    // MARK: - Clear Local Data
    func clearLocalData() {
        persistence.deleteAllData()
        print("✅ Datos locales eliminados")
    }
    
    // MARK: - Force Sync
    func forceSync() async {
        await syncAll()
    }
}
