//
//  AppConstants.swift
//  LOGOS
//
//  Created by alvaro on 16/1/26.
//

import Foundation

struct AppConstants {
    
    // MARK: - App Info
    static let appName = "Logos"
    static let appVersion = "1.0.0"
    
    // MARK: - Firebase
    struct Firebase {
        static let projectId = "Logos" // Cambiar por tu proyecto
    }
    
    // MARK: - Supabase
    struct Supabase {
        static let url = "https://earjxgwqthusrgvfvlpw.supabase.co" // https://xxxxx.supabase.co
        static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVhcmp4Z3dxdGh1c3JndmZ2bHB3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1Njc4NjAsImV4cCI6MjA4NDE0Mzg2MH0.3rHf4aENfmJ8RTw5y8lFxHGYd0QVdttjfpqPXetryJI"
    }
    
    // MARK: - Hints
    struct Hints {
        static let freeHintsPerPuzzle = 1
        static let hintPackSizes = [5, 10, 25, 50]
        static let hintPrices = [0.99, 1.99, 3.99, 6.99] // USD
    }
    
    // MARK: - Subscription
    struct Subscription {
        static let monthlyProductId = "com.logos.subscription.monthly"
        static let annualProductId = "com.logos.subscription.annual"
    }
    
    // MARK: - Puzzles
    struct Puzzles {
        static let difficultyLevels = ["Fácil", "Medio", "Difícil", "Experto", "Maestro"]
        static let puzzleTypes = 5
    }
}
