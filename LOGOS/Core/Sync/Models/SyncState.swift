//
//  SyncState.swift
//  Logos
//
//  Estado de sincronización
//

import Foundation

enum SyncState: Equatable {
    case idle
    case syncing
    case success(Date)
    case error(String)
    
    var isSyncing: Bool {
        if case .syncing = self {
            return true
        }
        return false
    }
    
    var lastSyncDate: Date? {
        if case .success(let date) = self {
            return date
        }
        return nil
    }
    
    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }
}

struct SyncConflict {
    let entityType: String
    let entityId: String
    let localTimestamp: Date
    let remoteTimestamp: Date
    let resolution: ConflictResolution
    
    enum ConflictResolution {
        case useLocal
        case useRemote
        case merge
    }
}
