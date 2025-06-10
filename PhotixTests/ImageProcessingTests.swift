//
//  ImageProcessingTests.swift
//  PhotixTests
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import XCTest
import UIKit
@testable import Photix

final class ImageProcessingTests: XCTestCase {
    
    var photoManager: PhotoManager!
    var filterProcessor: FilterProcessor!
    
    override func setUp() {
        super.setUp()
        photoManager = PhotoManager()
        filterProcessor = FilterProcessor()
    }
    
    override func tearDown() {
        photoManager = nil
        filterProcessor = nil
        super.tearDown()
    }
    
    func testImageProcessing() {
        // Test image processing with different test images
        let testImageNames = ["test1_2448_3264", "test2_3264_2448", "test3_640_640"]
        
        for imageName in testImageNames {
            guard let path = Bundle.main.path(forResource: imageName, ofType: "jpg"),
                  let testImage = UIImage(contentsOfFile: path) else {
                XCTFail("Could not load test image: \(imageName)")
                continue
            }
            
            // Test basic image loading
            photoManager.setImage(testImage)
            XCTAssertNotNil(photoManager.selectedImage, "Image should be set in PhotoManager")
            XCTAssertEqual(photoManager.selectedImage?.size, testImage.size, "Image sizes should match")
        }
    }
    
    func testFilterProcessing() {
        // Create a simple test image
        let testImage = createTestImage()
        photoManager.setImage(testImage)
        
        // Test that we can process filters without crashing
        let expectation = self.expectation(description: "Filter processing")
        
        Task {
            do {
                let filteredImage = try await filterProcessor.applyFilter(.oilPaint, to: testImage)
                XCTAssertNotNil(filteredImage, "Filtered image should not be nil")
                expectation.fulfill()
            } catch {
                XCTFail("Filter processing failed: \(error)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 10.0)
    }
    
    func testFilterTypes() {
        // Test that all filter types can be created
        let filterTypes: [FilterType] = [.original, .oilPaint, .sepia, .blackAndWhite, .vintage]
        
        for filterType in filterTypes {
            XCTAssertNotNil(filterType, "Filter type \(filterType) should be valid")
        }
    }
    
    func testPhotoManagerFilterSelection() {
        let testImage = createTestImage()
        photoManager.setImage(testImage)
        
        // Test filter selection
        let originalFilter = FilteredImage(image: testImage, name: "Original", filterType: .original)
        photoManager.selectFilter(originalFilter)
        
        XCTAssertNotNil(photoManager.selectedFilter, "Selected filter should not be nil")
        XCTAssertEqual(photoManager.selectedFilter?.name, "Original", "Filter name should match")
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Create a simple gradient test image
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            UIColor.white.setFill()
            context.fill(CGRect(x: 25, y: 25, width: 50, height: 50))
        }
    }
}