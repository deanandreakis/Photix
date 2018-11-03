//
//  OilPaintPlusUITests.swift
//  OilPaintPlusUITests
//
//  Created by Dean Andreakis on 10/17/18.
//  Copyright © 2018 deanware. All rights reserved.
//

import XCTest

class OilPaintPlusUITests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        // XCUIApplication().launch()
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        //choose the album button on the front screen
        XCUIApplication().buttons["Album"].tap()
        //choose the camera roll from within the UIImagePickerController
        XCUIApplication().tables.cells.element(boundBy: 1).tap()
        //choose a picture from the camera roll within the UIImagePickerController
        XCUIApplication().collectionViews["PhotosGridView"].cells["Photo, Landscape, March 12, 2011, 6:17 PM"].tap()
        
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

}
