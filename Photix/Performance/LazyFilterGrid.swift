//
//  LazyFilterGrid.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import SwiftUI

struct LazyFilterGrid: View {
    let originalImage: UIImage
    let filterTypes: [FilterType]
    let selectedFilter: FilterType?
    let onFilterSelected: (FilterType) -> Void
    
    @State private var imageCache = ImageCache.shared
    @State private var metalRenderer = MetalFilterRenderer()
    @State private var visibleRange: Range<Int> = 0..<0
    
    private let itemSize: CGFloat = 80
    private let spacing: CGFloat = 10
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: spacing) {
                ForEach(Array(filterTypes.enumerated()), id: \.element) { index, filterType in
                    LazyFilterThumbnail(
                        originalImage: originalImage,
                        filterType: filterType,
                        isSelected: filterType == selectedFilter,
                        size: itemSize,
                        shouldLoad: visibleRange.contains(index)
                    ) {
                        onFilterSelected(filterType)
                        HapticManager.shared.impact(.light)
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: VisibleRangePreferenceKey.self, value: geometry.frame(in: .global))
                }
            )
        }
        .frame(height: itemSize + 40) // Extra space for labels
        .onPreferenceChange(VisibleRangePreferenceKey.self) { frame in
            updateVisibleRange(frame)
        }
    }
    
    private func updateVisibleRange(_ frame: CGRect) {
        let screenWidth = UIScreen.main.bounds.width
        let totalWidth = CGFloat(filterTypes.count) * (itemSize + spacing) - spacing
        
        // Calculate which items are visible or about to be visible
        let startX = max(0, -frame.minX - itemSize)
        let endX = min(totalWidth, -frame.minX + screenWidth + itemSize)
        
        let startIndex = max(0, Int(startX / (itemSize + spacing)))
        let endIndex = min(filterTypes.count, Int(endX / (itemSize + spacing)) + 1)
        
        visibleRange = startIndex..<endIndex
    }
}

struct LazyFilterThumbnail: View {
    let originalImage: UIImage
    let filterType: FilterType
    let isSelected: Bool
    let size: CGFloat
    let shouldLoad: Bool
    let onTap: () -> Void
    
    @State private var filteredImage: UIImage?
    @State private var isLoading = false
    @State private var loadTask: Task<Void, Never>?
    
    private var cacheKey: String {
        "filter_\(filterType.rawValue)_\(originalImage.hashValue)_\(Int(size))"
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Thumbnail image
                Group {
                    if let image = filteredImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else if isLoading {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                    } else {
                        Image(uiImage: originalImage)
                            .resizable()
                            .scaledToFill()
                            .opacity(0.3)
                    }
                }
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? Color.blue : Color.clear,
                            lineWidth: 3
                        )
                )
                .shadow(
                    color: isSelected ? .blue.opacity(0.3) : .black.opacity(0.2),
                    radius: isSelected ? 4 : 2,
                    x: 0,
                    y: 2
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            
            // Filter name label
            Text(filterType.rawValue)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .blue : .primary)
                .lineLimit(1)
                .frame(width: size)
        }
        .onTapGesture {
            onTap()
        }
        .onAppear {
            if shouldLoad {
                loadFilteredImage()
            }
        }
        .onChange(of: shouldLoad) { newValue in
            if newValue {
                loadFilteredImage()
            } else {
                cancelLoading()
            }
        }
        .onDisappear {
            cancelLoading()
        }
    }
    
    private func loadFilteredImage() {
        // Check cache first
        if let cachedImage = ImageCache.shared.image(for: cacheKey) {
            filteredImage = cachedImage
            return
        }
        
        // Cancel existing load task
        loadTask?.cancel()
        
        // Start new load task
        loadTask = Task { @MainActor in
            isLoading = true
            
            // Resize original image for thumbnail
            let thumbnailImage = await resizeImageForThumbnail(originalImage, targetSize: size)
            
            // Apply filter
            let metalRenderer = MetalFilterRenderer()
            if let filtered = await metalRenderer.renderFilterPreview(
                image: thumbnailImage,
                filterType: filterType,
                intensity: 1.0
            ) {
                // Cache the result
                ImageCache.shared.setImage(filtered, for: cacheKey)
                
                if !Task.isCancelled {
                    filteredImage = filtered
                }
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
        }
    }
    
    private func cancelLoading() {
        loadTask?.cancel()
        loadTask = nil
        isLoading = false
    }
    
    private func resizeImageForThumbnail(_ image: UIImage, targetSize: CGFloat) async -> UIImage {
        return await withCheckedContinuation { continuation in
            Task.detached {
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: targetSize, height: targetSize))
                let resizedImage = renderer.image { context in
                    image.draw(in: CGRect(x: 0, y: 0, width: targetSize, height: targetSize))
                }
                continuation.resume(returning: resizedImage)
            }
        }
    }
}

// MARK: - Preference Key for Visible Range

struct VisibleRangePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - Haptic Manager

@MainActor
class HapticManager {
    static let shared = HapticManager()
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()
    
    private init() {
        // Prepare generators for immediate response
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selection.prepare()
        notification.prepare()
    }
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:
            impactLight.impactOccurred()
            impactLight.prepare()
        case .medium:
            impactMedium.impactOccurred()
            impactMedium.prepare()
        case .heavy:
            impactHeavy.impactOccurred()
            impactHeavy.prepare()
        @unknown default:
            impactMedium.impactOccurred()
            impactMedium.prepare()
        }
    }
    
    func selectionChanged() {
        selection.selectionChanged()
        selection.prepare()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notification.notificationOccurred(type)
        notification.prepare()
    }
}

#Preview {
    LazyFilterGrid(
        originalImage: UIImage(systemName: "photo") ?? UIImage(),
        filterTypes: FilterType.allCases,
        selectedFilter: .original
    ) { _ in }
}