//
//  ModernInterfaceToggle.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import Foundation

@objc class ModernInterfaceToggle: NSObject {
    
    @objc static let shared = ModernInterfaceToggle()
    
    private let userDefaults = UserDefaults.standard
    private let modernInterfaceKey = "UseModernInterface"
    
    override init() {
        super.init()
    }
    
    @objc var isModernInterfaceEnabled: Bool {
        get {
            return userDefaults.bool(forKey: modernInterfaceKey)
        }
        set {
            userDefaults.set(newValue, forKey: modernInterfaceKey)
            userDefaults.synchronize()
        }
    }
    
    @objc func enableModernInterface() {
        isModernInterfaceEnabled = true
    }
    
    @objc func disableModernInterface() {
        isModernInterfaceEnabled = false
    }
    
    @objc func toggleModernInterface() {
        isModernInterfaceEnabled.toggle()
    }
}