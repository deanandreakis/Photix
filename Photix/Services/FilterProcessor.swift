//
//  FilterProcessor.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import UIKit
import CoreImage
import PhotixFilter

@MainActor
protocol FilterProcessorDelegate: AnyObject {
    func filteringCompleted(_ filteredImages: [FilteredImage])
    func filteringFailed(_ error: FilterProcessorError)
}

enum FilterProcessorError: Error, LocalizedError {
    case invalidImage
    case processingFailed(String)
    case unsupportedFilter
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image provided for filtering"
        case .processingFailed(let details):
            return "Filter processing failed: \(details)"
        case .unsupportedFilter:
            return "Unsupported filter type"
        }
    }
}

actor FilterProcessor {
    weak var delegate: FilterProcessorDelegate?
    private let context = CIContext()
    private let maxImageDimension: CGFloat = 1000.0
    
    init(delegate: FilterProcessorDelegate? = nil) {
        self.delegate = delegate
    }
    
    func processFilters(for image: UIImage) async {
        do {
            let filteredImages = try await generateFilteredImages(from: image)
            await delegate?.filteringCompleted(filteredImages)
        } catch {
            await delegate?.filteringFailed(error as? FilterProcessorError ?? .processingFailed(error.localizedDescription))
        }
    }
    
    private func generateFilteredImages(from originalImage: UIImage) async throws -> [FilteredImage] {
        guard let cgImage = originalImage.cgImage else {
            throw FilterProcessorError.invalidImage
        }
        
        // Resize image if too large
        let processedImage = resizeImageIfNeeded(originalImage)
        let ciImage = CIImage(cgImage: processedImage.cgImage!)
        
        var filteredImages: [FilteredImage] = []
        
        // Add original image
        filteredImages.append(FilteredImage(
            image: processedImage,
            name: FilterType.original.rawValue,
            filterType: .original
        ))
        
        // Process Kuwahara (Oil Paint) filter
        if let oilPaintImage = try await processKuwaharaFilter(ciImage: ciImage, orientation: originalImage.imageOrientation) {
            filteredImages.append(FilteredImage(
                image: oilPaintImage,
                name: FilterType.oilPaint.rawValue,
                filterType: .oilPaint
            ))
        }
        
        // Process Core Image filters
        let coreImageFilters = try await processCoreImageFilters(ciImage: ciImage, orientation: originalImage.imageOrientation)
        filteredImages.append(contentsOf: coreImageFilters)
        
        return filteredImages
    }
    
    private func processKuwaharaFilter(ciImage: CIImage, orientation: UIImage.Orientation) async throws -> UIImage? {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let kuwaharaFilter = KuwaharaFilter()
                    kuwaharaFilter.inputImage = ciImage
                    
                    guard let outputImage = kuwaharaFilter.outputImage,
                          let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
                        continuation.resume(throwing: FilterProcessorError.processingFailed("Kuwahara filter failed"))
                        return
                    }
                    
                    let filteredImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
                    continuation.resume(returning: filteredImage)
                } catch {
                    continuation.resume(throwing: FilterProcessorError.processingFailed("Kuwahara filter error: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    private func processCoreImageFilters(ciImage: CIImage, orientation: UIImage.Orientation) async throws -> [FilteredImage] {
        var filteredImages: [FilteredImage] = []
        
        for filterType in FilterType.allCases {
            guard let coreImageFilterName = filterType.coreImageFilterName else { continue }
            
            do {
                if let filteredImage = try await applyCoreImageFilter(
                    filterName: coreImageFilterName,
                    to: ciImage,
                    filterType: filterType,
                    orientation: orientation
                ) {
                    filteredImages.append(filteredImage)
                }
            } catch {
                // Log error but continue processing other filters
                print("Failed to process filter \(filterType.rawValue): \(error)")
            }
        }
        
        return filteredImages
    }
    
    private func applyCoreImageFilter(
        filterName: String,
        to ciImage: CIImage,
        filterType: FilterType,
        orientation: UIImage.Orientation
    ) async throws -> FilteredImage? {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    guard let filter = CIFilter(name: filterName) else {
                        continuation.resume(throwing: FilterProcessorError.unsupportedFilter)
                        return
                    }
                    
                    filter.setValue(ciImage, forKey: kCIInputImageKey)
                    
                    // Special handling for vignette effect
                    if filterType == .vignette {
                        let centerX = ciImage.extent.size.width / 2.0
                        let centerY = ciImage.extent.size.height / 2.0
                        let center = CIVector(x: centerX, y: centerY)
                        filter.setValue(center, forKey: kCIInputCenterKey)
                        filter.setValue(1.0, forKey: "inputIntensity")
                        
                        let radius = min(centerX, centerY) * 0.8
                        filter.setValue(radius, forKey: "inputRadius")
                    }
                    
                    guard let outputImage = filter.outputImage,
                          let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
                        continuation.resume(throwing: FilterProcessorError.processingFailed("Core Image filter \(filterName) failed"))
                        return
                    }
                    
                    let filteredUIImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
                    let filteredImage = FilteredImage(
                        image: filteredUIImage,
                        name: filterType.rawValue,
                        filterType: filterType
                    )
                    
                    continuation.resume(returning: filteredImage)
                } catch {
                    continuation.resume(throwing: FilterProcessorError.processingFailed("Filter processing error: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let size = image.size
        
        guard size.width > maxImageDimension || size.height > maxImageDimension else {
            return image
        }
        
        let scaleFactor = min(maxImageDimension / size.width, maxImageDimension / size.height)
        let newSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
        return resizeImage(image, to: newSize)
    }
    
    private func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        let imageSize = image.size
        let widthRatio = targetSize.width / imageSize.width
        let heightRatio = targetSize.height / imageSize.height
        let ratio = min(widthRatio, heightRatio)
        
        let scaledSize = CGSize(
            width: imageSize.width * ratio,
            height: imageSize.height * ratio
        )
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { context in
            let x = (targetSize.width - scaledSize.width) / 2
            let y = (targetSize.height - scaledSize.height) / 2
            let rect = CGRect(x: x, y: y, width: scaledSize.width, height: scaledSize.height)
            image.draw(in: rect)
        }
    }
}