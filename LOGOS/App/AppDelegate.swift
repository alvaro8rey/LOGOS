//
//  AppDelegate.swift
//  Logos
//
//  App Delegate para configuración de Firebase
//

import UIKit
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        
        // Configurar Firebase
        FirebaseApp.configure()
        print("✅ Firebase configurado")
        
        return true
    }
}
