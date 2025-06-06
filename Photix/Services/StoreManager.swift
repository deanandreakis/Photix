//
//  StoreManager.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import Foundation
import StoreKit
import Combine

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    private(set) var products: [Product] = []
    private(set) var purchasedIdentifiers: Set<String> = []
    private(set) var isLoading = false
    private(set) var error: StoreError?
    
    private var productIdentifiers: Set<String> = []
    private var updateListenerTask: Task<Void, Error>?
    
    // Notifications for backward compatibility with Objective-C code
    static let productPurchasedNotification = NSNotification.Name("IAPHelperProductPurchasedNotification")
    static let transactionFailedNotification = NSNotification.Name("IAPHelperTransactionFailedNotification")
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Load previously purchased products from UserDefaults for backward compatibility
        loadPreviousPurchases()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    enum StoreError: Error, LocalizedError {
        case failedVerification
        case networkError(Error)
        case productNotFound
        case purchaseFailed(Error)
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .failedVerification:
                return "Transaction verification failed"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .productNotFound:
                return "Product not found"
            case .purchaseFailed(let error):
                return "Purchase failed: \(error.localizedDescription)"
            case .unknown:
                return "Unknown error occurred"
            }
        }
    }
    
    // MARK: - Public Methods
    
    func configure(with productIdentifiers: Set<String>) {
        self.productIdentifiers = productIdentifiers
        Task {
            await loadProducts()
        }
    }
    
    func loadProducts() async {
        isLoading = true
        error = nil
        
        do {
            let products = try await Product.products(for: productIdentifiers)
            await MainActor.run {
                self.products = products
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = .networkError(error)
                self.isLoading = false
            }
        }
    }
    
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                
                await MainActor.run {
                    self.purchasedIdentifiers.insert(product.id)
                    self.savePurchaseToUserDefaults(product.id)
                    self.postPurchaseNotification(product.id)
                }
                
                return true
                
            case .userCancelled:
                return false
                
            case .pending:
                return false
                
            @unknown default:
                return false
            }
            
        } catch {
            await MainActor.run {
                self.error = .purchaseFailed(error)
                self.postFailureNotification(product.id)
            }
            return false
        }
    }
    
    func isPurchased(_ productIdentifier: String) -> Bool {
        return purchasedIdentifiers.contains(productIdentifier)
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            await MainActor.run {
                self.error = .networkError(error)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    await MainActor.run {
                        self.purchasedIdentifiers.insert(transaction.productID)
                        self.savePurchaseToUserDefaults(transaction.productID)
                        self.postPurchaseNotification(transaction.productID)
                    }
                    
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    private func loadPreviousPurchases() {
        for identifier in productIdentifiers {
            if UserDefaults.standard.bool(forKey: identifier) {
                purchasedIdentifiers.insert(identifier)
            }
        }
    }
    
    private func savePurchaseToUserDefaults(_ productIdentifier: String) {
        UserDefaults.standard.set(true, forKey: productIdentifier)
        UserDefaults.standard.synchronize()
    }
    
    private func postPurchaseNotification(_ productIdentifier: String) {
        NotificationCenter.default.post(
            name: Self.productPurchasedNotification,
            object: productIdentifier
        )
    }
    
    private func postFailureNotification(_ productIdentifier: String) {
        NotificationCenter.default.post(
            name: Self.transactionFailedNotification,
            object: productIdentifier
        )
    }
    
    // MARK: - Backward Compatibility Methods (for Objective-C bridge)
    
    @objc func productPurchased(_ productIdentifier: String) -> Bool {
        return isPurchased(productIdentifier)
    }
    
    @objc func buyProduct(_ product: Any) {
        // This would need to be bridged from SKProduct to Product
        // For now, keeping the method signature for compatibility
        Task {
            // Implementation would need product conversion
        }
    }
    
    @objc func restoreCompletedTransactions() {
        Task {
            await restorePurchases()
        }
    }
}