//
//  PhotixTests.swift
//  PhotixTests
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import XCTest
import UIKit
@testable import Photix

final class PhotixTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    static func waitForCompletion(timeoutSeconds: TimeInterval) -> Bool {
        let timeoutDate = Date().addingTimeInterval(timeoutSeconds)
        
        repeat {
            RunLoop.current.run(mode: .default, before: timeoutDate)
            if timeoutDate.timeIntervalSinceNow < 0.0 {
                break
            }
        } while true
        
        return true
    }
    
    static func doesActionSheetExist() -> Bool {
        for window in UIApplication.shared.windows {
            let subviews = window.subviews
            if !subviews.isEmpty {
                // Note: UIActionSheet is deprecated, modern apps use UIAlertController
                if subviews[0].isKind(of: UIAlertController.self) {
                    return true
                }
            }
        }
        return false
    }
    
    static func dismissAlertViews() {
        for window in UIApplication.shared.windows {
            let subviews = window.subviews
            if !subviews.isEmpty {
                if let alertController = subviews[0] as? UIAlertController {
                    alertController.dismiss(animated: false)
                }
            }
        }
    }
    
    // MARK: - Basic Tests
    
    func testAppLaunch() {
        // Test that the app can launch without crashing
        let dependencies = DependencyContainer.shared
        XCTAssertNotNil(dependencies)
        XCTAssertNotNil(dependencies.photoManager)
        XCTAssertNotNil(dependencies.storeManager)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
}