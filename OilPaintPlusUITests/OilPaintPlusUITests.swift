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
        //snapshot("01MainScreen")
        
        //choose the album button on the front screen
        XCUIApplication().buttons["Album"].tap()
        //choose the camera roll from within the UIImagePickerController
        XCUIApplication().tables.cells.element(boundBy: 1).tap()
        //choose a picture from the camera roll within the UIImagePickerController
        XCUIApplication().collectionViews["PhotosGridView"].cells["Photo, Landscape, March 12, 2011, 6:17 PM"].tap()
        
        if (XCUIApplication().scrollViews.children(matching: .button).element(boundBy: 1).waitForExistence(timeout: 100))
        {
            //snapshot("02FilterScreenBefore")
            XCUIApplication().scrollViews.children(matching: .button).element(boundBy: 1).tap()
            //snapshot("03FilterScreenAfter")
            XCUIApplication().navigationBars["DNWFilterView"].buttons["Next"].tap()
            //snapshot("04PictureScreen")
        }
    }
    
    func testCoder() {
        let app = XCUIApplication()
        app.scrollViews.children(matching: .button).element(boundBy: 1).tap()
        app.navigationBars["DNWFilterView"].buttons["Next"].tap()
        app.toolbars["Toolbar"].buttons["Share"].tap()
        app.buttons["Cancel"].tap()
        app.navigationBars["DNWPictureView"].buttons["Done"].tap()
    }

}
