//
//  Constants.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import UIKit

struct AppConstants {
    
    // MARK: - Colors
    static func colorFromRGB(_ rgbValue: UInt32) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0xFF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
    
    // MARK: - API Keys
    static let crashlyticsKey = "2eaad7ad1fecfce6c414905676a8175bb2a1c253"
    static let admobKey = "ca-app-pub-1222083832444594/7907782064"
    static let admobTestKey = "ca-app-pub-3940256099942544/2934735716"
    
    // MARK: - StoreKit Product IDs
    struct ProductIDs {
        static let generous99 = "tip99"
        static let massive199 = "tip199"
        static let amazing499 = "tip499"
    }
    
    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        static let userPurchasedTip = "user_purchased_tip"
        static let useModernInterface = "UseModernInterface"
    }
}

// MARK: - App Delegate Access
extension UIApplication {
    var appDelegate: AppDelegate? {
        return delegate as? AppDelegate
    }
}