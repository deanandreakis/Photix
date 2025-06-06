//
//  AppDelegateExtension.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import UIKit
import SwiftUI

// MARK: - App Delegate Extension for Swift Services

extension DNWAppDelegate {
    
    @objc func initializeSwiftServices() {
        // Initialize dependency container
        let dependencies = DependencyContainer.shared
        dependencies.configure()
        
        // Set up observers for app lifecycle
        setupAppLifecycleObservers()
    }
    
    private func setupAppLifecycleObservers() {
        // Memory warning observer
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            ImageCache.shared.clearMemoryCache()
            BackgroundProcessor.shared.cancelAllJobs()
        }
        
        // Background observer
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task {
                // End any active Live Activities
                if #available(iOS 16.1, *) {
                    await LiveActivityManager.shared.endActivity()
                }
            }
        }
        
        // Foreground observer
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Refresh photo library permissions if needed
            let photoManager = DependencyContainer.shared.photoManager
            Task {
                await PhotoLibraryManager().requestPermission()
            }
        }
    }
}

// MARK: - Swift-to-Objective-C Bridge Methods

extension DNWAppDelegate {
    
    @objc func presentSwiftUICamera(from viewController: UIViewController) {
        SwiftUIBridge.presentPhotoCapture(from: viewController)
    }
    
    @objc func presentSwiftUIFilters(from viewController: UIViewController, with image: UIImage) {
        SwiftUIBridge.presentFilterSelection(from: viewController, with: image)
    }
    
    @objc func presentSwiftUISettings(from viewController: UIViewController) {
        SwiftUIBridge.presentSettings(from: viewController)
    }
}