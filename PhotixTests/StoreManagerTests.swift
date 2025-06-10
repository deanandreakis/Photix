//
//  StoreManagerTests.swift
//  PhotixTests
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import XCTest
import StoreKit
@testable import Photix

final class StoreManagerTests: XCTestCase {
    
    var storeManager: StoreManager!
    
    @MainActor
    override func setUp() {
        super.setUp()
        storeManager = StoreManager.shared
    }
    
    override func tearDown() {
        storeManager = nil
        super.tearDown()
    }
    
    @MainActor
    func testStoreManagerInitialization() {
        XCTAssertNotNil(storeManager, "StoreManager should initialize")
        XCTAssertNotNil(storeManager.products, "Products array should be initialized")
    }
    
    @MainActor
    func testProductIdentifiers() {
        let expectedProductIDs = ["tip99", "tip199", "tip499"]
        
        // Test that our product IDs are defined
        for productID in expectedProductIDs {
            // Test that we can check purchase status (should be false by default)
            let isPurchased = storeManager.isPurchased(productID)
            XCTAssertFalse(isPurchased, "Product \(productID) should not be purchased by default")
        }
    }
    
    @MainActor
    func testLoadProducts() {
        let expectation = self.expectation(description: "Load products")
        
        Task {
            await storeManager.loadProducts()
            // Products may or may not load in testing environment
            // Just test that the method doesn't crash
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
}