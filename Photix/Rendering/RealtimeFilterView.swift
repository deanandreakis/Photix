//
//  RealtimeFilterView.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import SwiftUI
import MetalKit
import Metal

struct RealtimeFilterView: View {
    let image: UIImage
    @Binding var selectedFilter: FilterType
    @Binding var filterIntensity: Float
    
    @State private var metalRenderer = MetalFilterRenderer()
    @State private var filteredImage: UIImage?
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main filtered image display
            ZStack {
                Color.black
                
                if let displayImage = filteredImage ?? filteredImage {
                    Image(uiImage: displayImage)
                        .resizable()
                        .scaledToFit()
                        .animation(.easeInOut(duration: 0.3), value: filteredImage)
                } else {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
                
                if isProcessing {
                    Color.black.opacity(0.3)
                        .overlay {
                            ProgressView()
                                .scaleEffect(1.2)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                }
            }
            .frame(maxHeight: .infinity)
            
            // Filter intensity slider
            if selectedFilter != .original {
                VStack(spacing: 12) {
                    HStack {
                        Text("Intensity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(filterIntensity * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    
                    Slider(value: $filterIntensity, in: 0...1) {
                        Text("Filter Intensity")
                    }
                    .accentColor(.blue)
                    .onChange(of: filterIntensity) { newValue in
                        Task {
                            await updateFilterPreview()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
            }
        }
        .task {
            await updateFilterPreview()
        }
        .onChange(of: selectedFilter) { _ in
            Task {
                await updateFilterPreview()
            }
        }
    }
    
    @MainActor
    private func updateFilterPreview() async {
        isProcessing = true
        
        let newImage = await metalRenderer.renderFilterPreview(
            image: image,
            filterType: selectedFilter,
            intensity: filterIntensity
        )
        
        filteredImage = newImage
        isProcessing = false
    }
}

struct MetalPreviewView: UIViewRepresentable {
    let image: UIImage
    let filterType: FilterType
    let intensity: Float
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.framebufferOnly = false
        mtkView.colorPixelFormat = .bgra8Unorm
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.updateImage(image, filterType: filterType, intensity: intensity)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        private var renderer: MetalFilterRenderer?
        private var currentImage: UIImage?
        private var currentFilter: FilterType = .original
        private var currentIntensity: Float = 1.0
        
        override init() {
            super.init()
            Task { @MainActor in
                renderer = MetalFilterRenderer()
            }
        }
        
        func updateImage(_ image: UIImage, filterType: FilterType, intensity: Float) {
            currentImage = image
            currentFilter = filterType
            currentIntensity = intensity
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Handle resize if needed
        }
        
        func draw(in view: MTKView) {
            guard let image = currentImage,
                  let renderer = renderer else { return }
            
            Task {
                let filteredImage = await renderer.renderFilterPreview(
                    image: image,
                    filterType: currentFilter,
                    intensity: currentIntensity
                )
                
                // Update the MTKView with the filtered image
                // This would require additional Metal texture handling
            }
        }
    }
}

#Preview {
    RealtimeFilterView(
        image: UIImage(systemName: "photo") ?? UIImage(),
        selectedFilter: .constant(.sepia),
        filterIntensity: .constant(0.8)
    )
}