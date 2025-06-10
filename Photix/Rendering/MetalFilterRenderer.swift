//
//  MetalFilterRenderer.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import Metal
import MetalKit
import CoreImage
import UIKit
import Combine
import PhotixFilter

@MainActor
class MetalFilterRenderer: NSObject, ObservableObject {
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var ciContext: CIContext?
    private var textureLoader: MTKTextureLoader?
    
    @Published var isInitialized = false
    @Published var error: MetalError?
    
    enum MetalError: Error, LocalizedError {
        case deviceNotAvailable
        case commandQueueCreationFailed
        case textureCreationFailed
        case renderingFailed
        
        var errorDescription: String? {
            switch self {
            case .deviceNotAvailable:
                return "Metal device not available"
            case .commandQueueCreationFailed:
                return "Failed to create Metal command queue"
            case .textureCreationFailed:
                return "Failed to create Metal texture"
            case .renderingFailed:
                return "Metal rendering failed"
            }
        }
    }
    
    override init() {
        super.init()
        setupMetal()
    }
    
    private func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            error = .deviceNotAvailable
            return
        }
        
        self.device = device
        
        guard let commandQueue = device.makeCommandQueue() else {
            error = .commandQueueCreationFailed
            return
        }
        
        self.commandQueue = commandQueue
        self.textureLoader = MTKTextureLoader(device: device)
        
        // Create CIContext with Metal device for better performance
        self.ciContext = CIContext(mtlDevice: device, options: [
            .workingColorSpace: CGColorSpace(name: CGColorSpace.displayP3) as Any,
            .cacheIntermediates: true
        ])
        
        isInitialized = true
    }
    
    func renderFilterPreview(
        image: UIImage,
        filterType: FilterType,
        intensity: Float = 1.0
    ) async -> UIImage? {
        guard isInitialized,
              let device = device,
              let commandQueue = commandQueue,
              let ciContext = ciContext else {
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            Task.detached {
                do {
                    let ciImage = CIImage(image: image) ?? CIImage.empty()
                    let filteredImage = try await self.applyMetalFilter(
                        to: ciImage,
                        filterType: filterType,
                        intensity: intensity,
                        context: ciContext
                    )
                    
                    let cgImage = ciContext.createCGImage(filteredImage, from: filteredImage.extent)
                    let uiImage = cgImage.map { UIImage(cgImage: $0) }
                    
                    await MainActor.run {
                        continuation.resume(returning: uiImage)
                    }
                } catch {
                    await MainActor.run {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }
    
    private func applyMetalFilter(
        to image: CIImage,
        filterType: FilterType,
        intensity: Float,
        context: CIContext
    ) async throws -> CIImage {
        
        switch filterType {
        case .original:
            return image
            
        case .oilPaint:
            // Use existing Kuwahara filter with Metal acceleration
            return try await applyKuwaharaFilter(to: image, intensity: intensity)
            
        case .blur:
            return try await applyMetalBlur(to: image, intensity: intensity)
            
        case .sepia:
            return try await applyMetalSepia(to: image, intensity: intensity)
            
        case .vignette:
            return try await applyMetalVignette(to: image, intensity: intensity)
            
        default:
            // Fall back to Core Image for other filters
            return try await applyCoreImageFilter(to: image, filterType: filterType, intensity: intensity)
        }
    }
    
    private func applyKuwaharaFilter(to image: CIImage, intensity: Float) async throws -> CIImage {
        let kuwaharaFilter = KuwaharaFilter()
        kuwaharaFilter.inputImage = image
        kuwaharaFilter.inputRadius = CGFloat(15.0 * intensity)
        
        guard let outputImage = kuwaharaFilter.outputImage else {
            throw MetalError.renderingFailed
        }
        
        return outputImage
    }
    
    private func applyMetalBlur(to image: CIImage, intensity: Float) async throws -> CIImage {
        guard let filter = CIFilter(name: "CIGaussianBlur") else {
            throw MetalError.renderingFailed
        }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(intensity * 10.0, forKey: kCIInputRadiusKey)
        
        guard let outputImage = filter.outputImage else {
            throw MetalError.renderingFailed
        }
        
        return outputImage
    }
    
    private func applyMetalSepia(to image: CIImage, intensity: Float) async throws -> CIImage {
        guard let filter = CIFilter(name: "CISepiaTone") else {
            throw MetalError.renderingFailed
        }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(intensity, forKey: kCIInputIntensityKey)
        
        guard let outputImage = filter.outputImage else {
            throw MetalError.renderingFailed
        }
        
        return outputImage
    }
    
    private func applyMetalVignette(to image: CIImage, intensity: Float) async throws -> CIImage {
        guard let filter = CIFilter(name: "CIVignetteEffect") else {
            throw MetalError.renderingFailed
        }
        
        let centerX = image.extent.size.width / 2.0
        let centerY = image.extent.size.height / 2.0
        let center = CIVector(x: centerX, y: centerY)
        let radius = min(centerX, centerY) * 0.8 * CGFloat(intensity)
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(center, forKey: kCIInputCenterKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        filter.setValue(intensity, forKey: kCIInputIntensityKey)
        
        guard let outputImage = filter.outputImage else {
            throw MetalError.renderingFailed
        }
        
        return outputImage
    }
    
    private func applyCoreImageFilter(
        to image: CIImage,
        filterType: FilterType,
        intensity: Float
    ) async throws -> CIImage {
        guard let filterName = filterType.coreImageFilterName,
              let filter = CIFilter(name: filterName) else {
            throw MetalError.renderingFailed
        }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        
        // Apply intensity where applicable
        if filter.inputKeys.contains(kCIInputIntensityKey) {
            filter.setValue(intensity, forKey: kCIInputIntensityKey)
        }
        
        guard let outputImage = filter.outputImage else {
            throw MetalError.renderingFailed
        }
        
        return outputImage
    }
    
    // MARK: - Batch Processing
    
    func renderMultipleFilters(
        image: UIImage,
        filterTypes: [FilterType]
    ) async -> [FilterType: UIImage] {
        guard isInitialized else { return [:] }
        
        return await withTaskGroup(of: (FilterType, UIImage?).self) { group in
            for filterType in filterTypes {
                group.addTask {
                    let result = await self.renderFilterPreview(image: image, filterType: filterType)
                    return (filterType, result)
                }
            }
            
            var results: [FilterType: UIImage] = [:]
            for await (filterType, image) in group {
                if let image = image {
                    results[filterType] = image
                }
            }
            return results
        }
    }
    
    // MARK: - Memory Management
    
    func clearCache() {
        ciContext?.clearCaches()
    }
    
    func memoryWarningReceived() {
        clearCache()
    }
}