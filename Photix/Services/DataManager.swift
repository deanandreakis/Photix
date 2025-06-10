//
//  DataManager.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import Foundation

actor DataManager {
    static let shared = DataManager()
    
    private init() {}
    
    // MARK: - Simple Data Management
    // Note: This app primarily works with photos from the photo library
    // and doesn't need complex persistent storage
    
    // Store app preferences and settings
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Database Management (Simplified)
    
    func initializeDatabase() async throws {
        // Initialize any app settings or preferences
        print("DataManager: Initializing app data")
    }
    
    func prePopulateDatabase() async throws {
        // Set up any default preferences
        print("DataManager: Setting up default preferences")
    }
    
    func isDatabaseEmpty() async throws -> Bool {
        // For a photo filtering app, we don't need to track this
        // Always return false (not empty) to skip pre-population
        return false
    }
    
    // MARK: - App Settings Management
    
    nonisolated func saveAppSetting(key: String, value: Any) {
        userDefaults.set(value, forKey: key)
    }
    
    nonisolated func getAppSetting(key: String) -> Any? {
        return userDefaults.object(forKey: key)
    }
    
    nonisolated func getBoolSetting(key: String, defaultValue: Bool = false) -> Bool {
        return userDefaults.bool(forKey: key)
    }
    
    nonisolated func getIntSetting(key: String, defaultValue: Int = 0) -> Int {
        return userDefaults.integer(forKey: key)
    }
    
    nonisolated func getStringSetting(key: String, defaultValue: String = "") -> String {
        return userDefaults.string(forKey: key) ?? defaultValue
    }
}