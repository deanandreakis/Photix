//
//  FilterSelectionView.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import SwiftUI

// Wrapper view for modal presentation from Objective-C
struct FilterSelectionViewWrapper: View {
    let photoManager: PhotoManager
    let dependencies: DependencyContainer
    let navigationState: NavigationState
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            FilterSelectionViewModal(onDismiss: onDismiss)
                .environmentObject(photoManager)
                .environmentObject(dependencies)
                .environmentObject(dependencies.storeManager)
                .environmentObject(navigationState)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// Modal version of FilterSelectionView with proper navigation handling
struct FilterSelectionViewModal: View {
    @EnvironmentObject private var photoManager: PhotoManager
    let onDismiss: () -> Void
    @State private var showingPhotoEdit = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Main image display
                MainImageDisplayView(
                    image: photoManager.filteredImage,
                    isProcessing: photoManager.isProcessing
                )
                .frame(height: geometry.size.height * 0.65)
                
                // Filter selection carousel
                FilterCarouselView(
                    filters: photoManager.availableFilters,
                    selectedIndex: .constant(0),
                    onFilterSelected: { filter in
                        photoManager.selectFilter(filter)
                    }
                )
                .frame(height: geometry.size.height * 0.25)
                
                // Navigation controls - more prominent
                VStack(spacing: 8) {
                    Text("SwiftUI Filter Selection")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.bold)
                    
                    ModalNavigationControlsView(
                        isNextEnabled: photoManager.selectedFilter != nil,
                        onStartOver: {
                            photoManager.clearSelection()
                            onDismiss()
                        },
                        onNext: {
                            // Navigate to photo edit screen
                            print("Next tapped - showing photo edit modal")
                            showingPhotoEdit = true
                        }
                    )
                }
                .frame(height: 80)
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle("Choose Filter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    onDismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Next") {
                    showingPhotoEdit = true
                }
                .disabled(photoManager.selectedFilter == nil)
            }
        }
        .onAppear {
            // Auto-select the first filter (Original) if available
            if let firstFilter = photoManager.availableFilters.first {
                photoManager.selectFilter(firstFilter)
            }
            print("FilterSelectionViewModal appeared")
            print("Available filters: \(photoManager.availableFilters.count)")
            print("Selected filter: \(photoManager.selectedFilter?.name ?? "None")")
            print("PhotoManager.selectedImage exists: \(photoManager.selectedImage != nil)")
            print("PhotoManager.filteredImage exists: \(photoManager.filteredImage != nil)")
            if let selectedImage = photoManager.selectedImage {
                print("SelectedImage size: \(selectedImage.size)")
            }
            if let filteredImage = photoManager.filteredImage {
                print("FilteredImage size: \(filteredImage.size)")
            }
        }
        .fullScreenCover(isPresented: $showingPhotoEdit) {
            if let image = photoManager.filteredImage ?? photoManager.selectedImage {
                PhotoEditModalView(image: image) {
                    showingPhotoEdit = false
                    onDismiss()
                }
            }
        }
    }
}

struct FilterSelectionView: View {
    @EnvironmentObject private var photoManager: PhotoManager
    @EnvironmentObject private var navigationState: NavigationState
    @State private var selectedFilterIndex: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Main image display
                MainImageDisplayView(
                    image: photoManager.filteredImage,
                    isProcessing: photoManager.isProcessing
                )
                .frame(height: geometry.size.height * 0.7)
                
                // Filter selection carousel
                FilterCarouselView(
                    filters: photoManager.availableFilters,
                    selectedIndex: $selectedFilterIndex,
                    onFilterSelected: { filter in
                        photoManager.selectFilter(filter)
                    }
                )
                .frame(height: geometry.size.height * 0.25)
                
                // Navigation controls at bottom (fallback for when toolbar is not visible)
                NavigationControlsView(
                    isNextEnabled: photoManager.selectedFilter != nil,
                    onStartOver: {
                        photoManager.clearSelection()
                        navigationState.navigateToRoot()
                    },
                    onNext: {
                        navigationState.navigateTo(.photoEdit)
                    }
                )
                .frame(height: geometry.size.height * 0.05)
            }
        }
        .navigationTitle("Filters")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Start Over") {
                    photoManager.clearSelection()
                    navigationState.navigateToRoot()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Next") {
                    navigationState.navigateTo(.photoEdit)
                }
                .disabled(photoManager.selectedFilter == nil)
            }
        }
        .onAppear {
            print("FilterSelectionView: onAppear called")
            print("FilterSelectionView: selectedImage exists: \(photoManager.selectedImage != nil)")
            print("FilterSelectionView: filteredImage exists: \(photoManager.filteredImage != nil)")
            print("FilterSelectionView: Available filters: \(photoManager.availableFilters.count)")
            
            // Auto-select the first filter (Original) if available
            if let firstFilter = photoManager.availableFilters.first {
                print("FilterSelectionView: Auto-selecting first filter: \(firstFilter.name)")
                photoManager.selectFilter(firstFilter)
                selectedFilterIndex = 0
            } else {
                print("FilterSelectionView: No filters available to auto-select")
            }
            print("FilterSelectionView: Selected filter: \(photoManager.selectedFilter?.name ?? "None")")
        }
    }
}

struct MainImageDisplayView: View {
    let image: UIImage?
    let isProcessing: Bool
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text("No Image")
                            .foregroundColor(.secondary)
                    )
            }
            
            if isProcessing {
                Color.black.opacity(0.3)
                    .overlay(
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            
                            Text("Processing Filters...")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                    )
            }
        }
        .background(Color.black)
    }
}

struct FilterCarouselView: View {
    let filters: [FilteredImage]
    @Binding var selectedIndex: Int
    let onFilterSelected: (FilteredImage) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if !filters.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(Array(filters.enumerated()), id: \.element.id) { index, filter in
                            FilterThumbnailView(
                                filter: filter,
                                isSelected: index == selectedIndex
                            )
                            .onTapGesture {
                                selectedIndex = index
                                onFilterSelected(filter)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .frame(height: 120)
            } else {
                VStack {
                    ProgressView()
                    Text("Loading filters...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(.systemBackground))
    }
}

struct FilterThumbnailView: View {
    let filter: FilteredImage
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(uiImage: filter.image)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
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
            
            Text(filter.name)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .blue : .primary)
                .lineLimit(1)
                .frame(width: 80)
        }
    }
}

struct NavigationControlsView: View {
    let isNextEnabled: Bool
    let onStartOver: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Button("Start Over") {
                onStartOver()
            }
            .foregroundColor(.red)
            .font(.headline)
            
            Spacer()
            
            Button("Next") {
                onNext()
            }
            .foregroundColor(isNextEnabled ? .blue : .gray)
            .font(.headline)
            .fontWeight(.semibold)
            .disabled(!isNextEnabled)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .border(Color(.systemGray4), width: 0.5)
    }
}

struct ModalNavigationControlsView: View {
    let isNextEnabled: Bool
    let onStartOver: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            Button("START OVER") {
                onStartOver()
            }
            .foregroundColor(.white)
            .font(.title2)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Button("NEXT →") {
                onNext()
            }
            .foregroundColor(.white)
            .font(.title2)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isNextEnabled ? Color.blue : Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(!isNextEnabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: -2)
    }
}

// Simple test modal to debug blank screen issue
struct SimpleTestModalView: View {
    let image: UIImage
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("TEST MODAL WORKING!")
                    .font(.title)
                    .foregroundColor(.green)
                    .fontWeight(.bold)
                
                Text("Image size: \(Int(image.size.width)) x \(Int(image.size.height))")
                    .font(.headline)
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipped()
                
                Button("DISMISS") {
                    onDismiss()
                }
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Spacer()
            }
            .padding()
            .navigationTitle("Test Modal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
        .onAppear {
            print("SimpleTestModalView appeared")
        }
    }
}

// Simple Photo Edit Modal for saving/sharing
struct PhotoEditModalView: View {
    let image: UIImage
    let onDismiss: () -> Void
    @State private var showingShareSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Display the filtered image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipped()
                    .background(Color.black)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button("Save to Photos") {
                        saveImageToPhotos()
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button("Share") {
                        showingShareSheet = true
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button("Start Over - New Photo") {
                        onDismiss()
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Edit Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [image])
        }
        .alert("Photo Saved", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveImageToPhotos() {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        alertMessage = "Photo has been saved to your Photos library"
        showingAlert = true
    }
}


#Preview {
    NavigationStack {
        FilterSelectionView()
            .environmentObject({
                let manager = PhotoManager()
                // Mock some filters for preview
                manager.availableFilters = [
                    FilteredImage(image: UIImage(systemName: "photo")!, name: "Original", filterType: .original),
                    FilteredImage(image: UIImage(systemName: "photo.fill")!, name: "Oil Paint", filterType: .oilPaint),
                    FilteredImage(image: UIImage(systemName: "photo")!, name: "Sepia", filterType: .sepia)
                ]
                return manager
            }())
    }
}