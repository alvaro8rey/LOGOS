//
//  SyncViewModel.swift
//  Logos
//
//  ViewModel para gestión de sincronización
//

import Foundation
import Combine

@MainActor
class SyncViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var syncState: SyncState = .idle
    @Published var lastSyncDate: Date?
    @Published var isSyncing = false
    @Published var syncProgress: Double = 0.0
    
    // MARK: - Services
    private let syncService = SyncService.shared
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    // MARK: - Setup Bindings
    private func setupBindings() {
        syncService.$syncState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.syncState = state
                self?.isSyncing = state.isSyncing
            }
            .store(in: &cancellables)
        
        syncService.$lastSyncDate
            .receive(on: DispatchQueue.main)
            .assign(to: &$lastSyncDate)
    }
    
    // MARK: - Actions
    func sync() async {
        await syncService.syncAll()
    }
    
    func forceSync() async {
        await syncService.forceSync()
    }
    
    // MARK: - Formatted Last Sync
    var formattedLastSync: String {
        guard let date = lastSyncDate else {
            return "Nunca"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
