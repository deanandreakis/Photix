//
//  UIImage+Extensions.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import UIKit

extension UIImage {
    
    /// Returns a normalized version of the image with correct orientation
    /// This fixes issues with photos taken in different orientations
    func normalizedImage() -> UIImage {
        // If image is already correctly oriented, return as-is
        if imageOrientation == .up {
            return self
        }
        
        // Create a graphics context and redraw the image with correct orientation
        let renderer = UIGraphicsImageRenderer(size: size)
        let normalizedImage = renderer.image { context in
            draw(in: CGRect(origin: .zero, size: size))
        }
        
        return normalizedImage
    }
    
    /// Alternative modern approach using Core Graphics
    func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        
        guard let cgImage = cgImage else { return self }
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// Resize image to target size while maintaining aspect ratio
    func resized(to targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let scaledSize = CGSize(
            width: size.width * ratio,
            height: size.height * ratio
        )
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { context in
            let x = (targetSize.width - scaledSize.width) / 2
            let y = (targetSize.height - scaledSize.height) / 2
            let rect = CGRect(x: x, y: y, width: scaledSize.width, height: scaledSize.height)
            draw(in: rect)
        }
    }
}