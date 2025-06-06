//
//  DependencyContainer.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import Foundation

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
        // Configure with your actual product identifiers
        let productIdentifiers: Set<String> = [
            "com.deanware.photix.tip",
            "com.deanware.photix.premium"
            // Add your actual product IDs here
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
        try await dataManager.savePhoto(imageData: imageData, filterType: filterType)
    }
}