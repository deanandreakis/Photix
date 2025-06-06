//
//  ObjectiveCBridge.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import UIKit
import SwiftUI

// MARK: - SwiftUI to UIKit Bridge

@MainActor
@objc class SwiftUIBridge: NSObject {
    
    // Bridge to present SwiftUI views from Objective-C
    @objc(presentPhotoCaptureFromViewController:)
    static func presentPhotoCapture(from viewController: UIViewController) {
        Task { @MainActor in
            let photoManager = PhotoManager()
            let dependencies = DependencyContainer.shared
            
            let swiftUIView = ContentView()
                .environmentObject(dependencies)
                .environmentObject(photoManager)
                .environmentObject(dependencies.storeManager)
            
            let hostingController = UIHostingController(rootView: swiftUIView)
            hostingController.modalPresentationStyle = .fullScreen
            
            viewController.present(hostingController, animated: true)
        }
    }
    
    @objc(presentFilterSelectionFromViewController:withImage:)
    static func presentFilterSelection(
        from viewController: UIViewController,
        with image: UIImage
    ) {
        print("SwiftUIBridge.presentFilterSelection called with image size: \(image.size)")
        let photoManager = PhotoManager()
        photoManager.setImage(image)
        print("PhotoManager.setImage called, selectedImage now exists: \(photoManager.selectedImage != nil)")
        
        let dependencies = DependencyContainer.shared
        let navigationState = NavigationState()
        
        let filterView = FilterSelectionViewWrapper(
            photoManager: photoManager,
            dependencies: dependencies,
            navigationState: navigationState,
            onDismiss: {
                viewController.dismiss(animated: true)
            }
        )
        
        let hostingController = UIHostingController(rootView: filterView)
        hostingController.modalPresentationStyle = .fullScreen
        
        viewController.present(hostingController, animated: true)
    }
    
    @objc static func presentSettings(from viewController: UIViewController) {
        let dependencies = DependencyContainer.shared
        
        let settingsView = SettingsView()
            .environmentObject(dependencies.storeManager)
            .environmentObject(dependencies)
        
        let hostingController = UIHostingController(rootView: NavigationView { settingsView })
        
        viewController.present(hostingController, animated: true)
    }
}

// MARK: - UIKit to SwiftUI Data Bridge

@objc class PhotoDataBridge: NSObject {
    
    @objc static func processImageWithFilters(
        _ image: UIImage,
        completion: @escaping ([UIImage], [String]) -> Void
    ) {
        // Simplified bridge - for full functionality use PhotoManager directly
        DispatchQueue.main.async {
            completion([], [])
        }
    }
    
    @objc static func createFilteredImageModel(
        image: UIImage,
        name: String
    ) -> DNWFilteredImageModel {
        let model = DNWFilteredImageModel()
        model.filteredImage = image
        model.imageName = name
        return model
    }
}

// MARK: - Store Bridge for Objective-C

@MainActor
@objc class StoreBridge: NSObject {
    
    @objc static let shared = StoreBridge()
    
    private override init() {
        super.init()
    }
    
    @objc func isProductPurchased(_ productIdentifier: String) -> Bool {
        return StoreManager.shared.isPurchased(productIdentifier)
    }
    
    @objc func purchaseProduct(
        with identifier: String,
        completion: @escaping (Bool) -> Void
    ) {
        Task { @MainActor in
            // Find product by identifier
            let product = StoreManager.shared.products.first { $0.id == identifier }
            
            guard let product = product else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            let success = await StoreManager.shared.purchase(product)
            
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    @objc func restorePurchases(completion: @escaping () -> Void) {
        Task { @MainActor in
            await StoreManager.shared.restorePurchases()
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}

// MARK: - Navigation Bridge

@MainActor
@objc class NavigationBridge: NSObject {
    
    @objc static func pushSwiftUIView(
        _ view: String,
        to navigationController: UINavigationController,
        with data: [String: Any]? = nil
    ) {
        Task { @MainActor in
            let dependencies = DependencyContainer.shared
            
            let hostingController: UIHostingController<AnyView>
            
            switch view {
            case "PhotoCapture":
                let swiftUIView = PhotoCaptureView()
                    .environmentObject(dependencies.photoManager)
                    .environmentObject(dependencies)
                hostingController = UIHostingController(rootView: AnyView(swiftUIView))
                
            case "FilterSelection":
                let swiftUIView = FilterSelectionView()
                    .environmentObject(dependencies.photoManager)
                    .environmentObject(dependencies)
                hostingController = UIHostingController(rootView: AnyView(swiftUIView))
                
            case "PhotoEdit":
                let swiftUIView = PhotoEditView()
                    .environmentObject(dependencies.photoManager)
                    .environmentObject(dependencies)
                hostingController = UIHostingController(rootView: AnyView(swiftUIView))
                
            case "Settings":
                let swiftUIView = SettingsView()
                    .environmentObject(dependencies.storeManager)
                    .environmentObject(dependencies)
                hostingController = UIHostingController(rootView: AnyView(swiftUIView))
                
            default:
                return
            }
            
            navigationController.pushViewController(hostingController, animated: true)
        }
    }
}