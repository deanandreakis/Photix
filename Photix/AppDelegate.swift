//
//  AppDelegate.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Enable modern SwiftUI interface by default
        UserDefaults.standard.set(true, forKey: "UseModernInterface")
        UserDefaults.standard.synchronize()
        
        // Configure app appearance
        configureAppearance(for: application)
        
        return true
    }
    
    private func configureAppearance(for application: UIApplication) {
        // Set up app theming
        application.delegate?.window??.tintColor = .black
        UILabel.appearance().textColor = .black
    }
    
    // MARK: - Quick Actions (3D Touch / Haptic Touch)
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        // Handle shortcut actions
        let handled = handleShortcutItem(shortcutItem)
        completionHandler(handled)
    }
    
    private func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        // Handle quick actions - could be implemented to jump directly to camera or last photo
        switch shortcutItem.type {
        case "com.deanware.photix.camera":
            // Open camera directly
            return true
        case "com.deanware.photix.lastphoto":
            // Edit last photo
            return true
        default:
            return false
        }
    }
    
    // MARK: - Background Tasks
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Handle background tasks if needed
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Handle foreground transition if needed
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Handle app becoming active
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Handle app resigning active state
    }
}