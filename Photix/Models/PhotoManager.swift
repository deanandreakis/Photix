//
//  PhotoManager.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import UIKit
import Combine

@MainActor
class PhotoManager: ObservableObject, FilterProcessorDelegate {
    @Published var selectedImage: UIImage?
    @Published var filteredImage: UIImage?
    @Published var availableFilters: [FilteredImage] = []
    @Published var selectedFilter: FilteredImage?
    @Published var isProcessing = false
    @Published var processingError: FilterProcessorError?
    
    private var filterProcessor: FilterProcessor?
    
    init() {
        self.filterProcessor = FilterProcessor(delegate: self)
    }
    
    func setImage(_ image: UIImage) {
        selectedImage = image
        filteredImage = image
        selectedFilter = nil
        availableFilters = []
        processingError = nil
        
        Task {
            await processFilters(for: image)
        }
    }
    
    func selectFilter(_ filter: FilteredImage) {
        selectedFilter = filter
        filteredImage = filter.image
    }
    
    func clearSelection() {
        selectedImage = nil
        filteredImage = nil
        selectedFilter = nil
        availableFilters = []
        processingError = nil
        isProcessing = false
    }
    
    private func processFilters(for image: UIImage) async {
        isProcessing = true
        processingError = nil
        
        await filterProcessor?.processFilters(for: image)
    }
    
    // MARK: - FilterProcessorDelegate
    
    func filteringCompleted(_ filteredImages: [FilteredImage]) {
        self.availableFilters = filteredImages
        self.isProcessing = false
        
        // Auto-select original image
        if let originalFilter = filteredImages.first(where: { $0.filterType == .original }) {
            selectFilter(originalFilter)
        }
    }
    
    func filteringFailed(_ error: FilterProcessorError) {
        self.processingError = error
        self.isProcessing = false
        print("Filter processing failed: \(error.localizedDescription)")
    }
}