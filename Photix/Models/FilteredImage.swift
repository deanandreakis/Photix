//
//  FilteredImage.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import UIKit

struct FilteredImage: Identifiable, Equatable {
    let id = UUID()
    let image: UIImage
    let name: String
    let filterType: FilterType
    
    static func == (lhs: FilteredImage, rhs: FilteredImage) -> Bool {
        lhs.id == rhs.id
    }
}

enum FilterType: String, CaseIterable, Identifiable {
    case original = "Original"
    case oilPaint = "Oil Paint"
    case colorMono = "Color Mono"
    case blur = "Blur"
    case chrome = "Chrome"
    case faded = "Faded"
    case instant = "Instant"
    case bwMono = "B&W Mono"
    case noir = "Noir"
    case vintageCool = "Vintage Cool"
    case tonal = "Tonal"
    case transfer = "Transfer"
    case sepia = "Sepia"
    case posterize = "Posterize"
    case invert = "Invert"
    case falseColor = "False"
    case gloom = "Gloom"
    case eightBitRetro = "8-bit Retro"
    case vignette = "Vignette"
    
    // New popular filters
    case dramatic = "Dramatic"
    case vintage = "Vintage"
    case cool = "Cool"
    case warm = "Warm"
    case sharpen = "Sharpen"
    case softFocus = "Soft Focus"
    case vibrant = "Vibrant"
    case sketch = "Sketch"
    case comic = "Comic"
    case crystallize = "Crystallize"
    case edges = "Edges"
    case pixelate = "Mosaic"
    case kaleidoscope = "Kaleidoscope"
    
    var id: String { rawValue }
    
    var coreImageFilterName: String? {
        switch self {
        case .original, .oilPaint:
            return nil
        case .colorMono:
            return "CIColorMonochrome"
        case .blur:
            return "CIGaussianBlur"
        case .chrome:
            return "CIPhotoEffectChrome"
        case .faded:
            return "CIPhotoEffectFade"
        case .instant:
            return "CIPhotoEffectInstant"
        case .bwMono:
            return "CIPhotoEffectMono"
        case .noir:
            return "CIPhotoEffectNoir"
        case .vintageCool:
            return "CIPhotoEffectProcess"
        case .tonal:
            return "CIPhotoEffectTonal"
        case .transfer:
            return "CIPhotoEffectTransfer"
        case .sepia:
            return "CISepiaTone"
        case .posterize:
            return "CIColorPosterize"
        case .invert:
            return "CIColorInvert"
        case .falseColor:
            return "CIFalseColor"
        case .gloom:
            return "CIGloom"
        case .eightBitRetro:
            return "CIPixellate"
        case .vignette:
            return "CIVignetteEffect"
        case .dramatic:
            return "CIPhotoEffectDramatic"
        case .vintage:
            return "CIPhotoEffectVintage"
        case .cool:
            return "CITemperatureAndTint"
        case .warm:
            return "CITemperatureAndTint"
        case .sharpen:
            return "CISharpenLuminance"
        case .softFocus:
            return "CIGaussianBlur"
        case .vibrant:
            return "CIVibrance"
        case .sketch:
            return "CILineOverlay"
        case .comic:
            return "CIComicEffect"
        case .crystallize:
            return "CICrystallize"
        case .edges:
            return "CIEdges"
        case .pixelate:
            return "CIPixellate"
        case .kaleidoscope:
            return "CITriangleKaleidoscope"
        }
    }
}