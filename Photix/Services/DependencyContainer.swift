//
//  DependencyContainer.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import Foundation
import StoreKit

@MainActor
class DependencyContainer: ObservableObject {
    static let shared = DependencyContainer()
    
    // MARK: - Services
    
    lazy var dataManager: DataManager = {
        return DataManager.shared
    }()
    
    lazy var storeManager: StoreManager = {
        return StoreManager.shared
    }()
    
    lazy var photoManager: PhotoManager = {
        return PhotoManager()
    }()
    
    private init() {}
    
    // MARK: - Configuration
    
    func configure() {
        configureStoreManager()
        configureDatabase()
    }
    
    private func configureStoreManager() {
        // Configure with tip jar product identifiers from App Store Connect
        let productIdentifiers: Set<String> = [
            "tip99",   // Generous Tip $0.99
            "tip199",  // Massive Tip $1.99  
            "tip499"   // Amazing Tip $4.99
        ]
        
        storeManager.configure(with: productIdentifiers)
    }
    
    private func configureDatabase() {
        Task {
            do {
                let isEmpty = try await dataManager.isDatabaseEmpty()
                if isEmpty {
                    try await dataManager.prePopulateDatabase()
                }
            } catch {
                print("Database configuration error: \(error)")
            }
        }
    }
    
    // MARK: - Convenience Accessors
    
    var isStoreLoading: Bool {
        storeManager.isLoading
    }
    
    var storeProducts: [StoreKit.Product] {
        storeManager.products
    }
    
    var isPhotoProcessing: Bool {
        photoManager.isProcessing
    }
    
    // MARK: - Actions
    
    func purchaseProduct(_ product: StoreKit.Product) async -> Bool {
        return await storeManager.purchase(product)
    }
    
    func restorePurchases() async {
        await storeManager.restorePurchases()
    }
    
    func setSelectedImage(_ image: UIImage) {
        photoManager.setImage(image)
    }
    
    func selectFilter(_ filter: FilteredImage) {
        photoManager.selectFilter(filter)
    }
    
    func savePhoto(_ imageData: Data, filterType: String) async throws {
        // Save photo metadata to user defaults for simple tracking
        let photoId = UUID().uuidString
        let photoInfo = [
            "id": photoId,
            "filterType": filterType,
            "dateCreated": Date().timeIntervalSince1970
        ] as [String: Any]
        
        dataManager.saveAppSetting(key: "lastProcessedPhoto", value: photoInfo)
        print("Photo processed with \(filterType) filter")
    }
}