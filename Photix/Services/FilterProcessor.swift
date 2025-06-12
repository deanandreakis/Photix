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
        
        // Ensure image has correct orientation and resize if too large
        let normalizedImage = originalImage.normalizedImage()
        let processedImage = resizeImageIfNeeded(normalizedImage)
        let ciImage = CIImage(cgImage: processedImage.cgImage!)
        
        var filteredImages: [FilteredImage] = []
        
        // Add original image (already normalized)
        filteredImages.append(FilteredImage(
            image: processedImage,
            name: FilterType.original.rawValue,
            filterType: .original
        ))
        
        // Process Kuwahara (Oil Paint) filter
        if let oilPaintImage = try await processKuwaharaFilter(ciImage: ciImage) {
            filteredImages.append(FilteredImage(
                image: oilPaintImage,
                name: FilterType.oilPaint.rawValue,
                filterType: .oilPaint
            ))
        }
        
        // Process Core Image filters
        let coreImageFilters = try await processCoreImageFilters(ciImage: ciImage)
        filteredImages.append(contentsOf: coreImageFilters)
        
        return filteredImages
    }
    
    private func processKuwaharaFilter(ciImage: CIImage) async throws -> UIImage? {
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
                    
                    // Create UIImage with .up orientation since we've already normalized the input
                    let filteredImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
                    continuation.resume(returning: filteredImage)
                } catch {
                    continuation.resume(throwing: FilterProcessorError.processingFailed("Kuwahara filter error: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    private func processCoreImageFilters(ciImage: CIImage) async throws -> [FilteredImage] {
        var filteredImages: [FilteredImage] = []
        
        for filterType in FilterType.allCases {
            guard let coreImageFilterName = filterType.coreImageFilterName else { continue }
            
            do {
                if let filteredImage = try await applyCoreImageFilter(
                    filterName: coreImageFilterName,
                    to: ciImage,
                    filterType: filterType
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
        filterType: FilterType
    ) async throws -> FilteredImage? {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    guard let filter = CIFilter(name: filterName) else {
                        continuation.resume(throwing: FilterProcessorError.unsupportedFilter)
                        return
                    }
                    
                    filter.setValue(ciImage, forKey: kCIInputImageKey)
                    
                    // Special parameter handling for filters that need it
                    switch filterType {
                    case .vignette:
                        let centerX = ciImage.extent.size.width / 2.0
                        let centerY = ciImage.extent.size.height / 2.0
                        let center = CIVector(x: centerX, y: centerY)
                        filter.setValue(center, forKey: kCIInputCenterKey)
                        filter.setValue(1.0, forKey: "inputIntensity")
                        let radius = min(centerX, centerY) * 0.8
                        filter.setValue(radius, forKey: "inputRadius")
                        
                    case .cool:
                        // Cool temperature effect
                        filter.setValue(CIVector(x: -1000, y: 0), forKey: "inputNeutral")
                        filter.setValue(CIVector(x: -1000, y: 0), forKey: "inputTargetNeutral")
                        
                    case .warm:
                        // Warm temperature effect
                        filter.setValue(CIVector(x: 1000, y: 0), forKey: "inputNeutral")
                        filter.setValue(CIVector(x: 1000, y: 0), forKey: "inputTargetNeutral")
                        
                    case .sharpen:
                        filter.setValue(0.4, forKey: "inputSharpness")
                        
                    case .softFocus:
                        filter.setValue(2.0, forKey: "inputRadius")
                        
                    case .vibrant:
                        filter.setValue(1.0, forKey: "inputAmount")
                        
                    case .sketch:
                        filter.setValue(0.7, forKey: "inputNRNoiseLevel")
                        filter.setValue(0.02, forKey: "inputNRSharpness")
                        filter.setValue(1.0, forKey: "inputEdgeIntensity")
                        
                    case .comic:
                        // CIComicEffect doesn't have adjustable parameters
                        break
                        
                    case .crystallize:
                        filter.setValue(20.0, forKey: "inputRadius")
                        let centerX = ciImage.extent.size.width / 2.0
                        let centerY = ciImage.extent.size.height / 2.0
                        let center = CIVector(x: centerX, y: centerY)
                        filter.setValue(center, forKey: kCIInputCenterKey)
                        
                    case .edges:
                        filter.setValue(1.0, forKey: "inputIntensity")
                        
                    case .pixelate:
                        filter.setValue(8.0, forKey: "inputScale")
                        
                    case .kaleidoscope:
                        // CITriangleKaleidoscope doesn't use inputCenter, only inputPoint
                        let centerX = ciImage.extent.size.width / 2.0
                        let centerY = ciImage.extent.size.height / 2.0
                        let center = CIVector(x: centerX, y: centerY)
                        filter.setValue(center, forKey: "inputPoint")
                        filter.setValue(6.0, forKey: "inputSize")
                        filter.setValue(0.0, forKey: "inputDecay")
                        
                    case .blur:
                        filter.setValue(10.0, forKey: "inputRadius")
                        
                    default:
                        break
                    }
                    
                    guard let outputImage = filter.outputImage,
                          let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
                        continuation.resume(throwing: FilterProcessorError.processingFailed("Core Image filter \(filterName) failed"))
                        return
                    }
                    
                    // Create UIImage with .up orientation since we've already normalized the input
                    let filteredUIImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
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