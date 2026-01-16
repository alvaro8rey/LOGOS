//
//  User.swift
//  Logos
//
//  Modelo de usuario
//

import Foundation

struct User: Codable, Identifiable {
    let id: String // Firebase UID
    var email: String?
    var displayName: String?
    var isAnonymous: Bool
    var createdAt: Date
    var lastSyncAt: Date?
    
    // Datos de juego
    var hintsAvailable: Int
    var isPremium: Bool
    var subscriptionType: SubscriptionType?
    var subscriptionExpiresAt: Date?
    
    enum SubscriptionType: String, Codable {
        case monthly
        case annual
    }
    
    init(
        id: String,
        email: String? = nil,
        displayName: String? = nil,
        isAnonymous: Bool = true
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.isAnonymous = isAnonymous
        self.createdAt = Date()
        self.hintsAvailable = 0
        self.isPremium = false
    }
}

// MARK: - Supabase Mapping
extension User {
    
    /// Convierte a formato para Supabase
    func toSupabaseDict() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "is_anonymous": isAnonymous,
            "created_at": ISO8601DateFormatter().string(from: createdAt),
            "hints_available": hintsAvailable,
            "is_premium": isPremium
        ]
        
        if let email = email {
            dict["email"] = email
        }
        
        if let displayName = displayName {
            dict["display_name"] = displayName
        }
        
        if let lastSyncAt = lastSyncAt {
            dict["last_sync_at"] = ISO8601DateFormatter().string(from: lastSyncAt)
        }
        
        if let subscriptionType = subscriptionType {
            dict["subscription_type"] = subscriptionType.rawValue
        }
        
        if let subscriptionExpiresAt = subscriptionExpiresAt {
            dict["subscription_expires_at"] = ISO8601DateFormatter().string(from: subscriptionExpiresAt)
        }
        
        return dict
    }
}
