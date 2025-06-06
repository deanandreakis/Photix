//
//  PhotoPickerView.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import SwiftUI
import PhotosUI
import Photos

struct PhotoPickerView: View {
    @State private var photoLibraryManager = PhotoLibraryManager()
    @Environment(\.dismiss) private var dismiss
    
    let onPhotosSelected: ([UIImage]) -> Void
    let allowsMultipleSelection: Bool
    
    @State private var selectedAssets: Set<PHAsset> = []
    @State private var showingLivePhotoPreview = false
    @State private var selectedLivePhoto: PHLivePhoto?
    
    init(
        allowsMultipleSelection: Bool = false,
        onPhotosSelected: @escaping ([UIImage]) -> Void
    ) {
        self.allowsMultipleSelection = allowsMultipleSelection
        self.onPhotosSelected = onPhotosSelected
    }
    
    var body: some View {
        NavigationView {
            Group {
                if photoLibraryManager.hasPermission {
                    photoGridView
                } else {
                    permissionDeniedView
                }
            }
            .navigationTitle("Photos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if allowsMultipleSelection && !selectedAssets.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done (\(selectedAssets.count))") {
                            Task {
                                await processSelectedPhotos()
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingLivePhotoPreview) {
                if let livePhoto = selectedLivePhoto {
                    LivePhotoPreviewView(livePhoto: livePhoto) { useStillImage in
                        showingLivePhotoPreview = false
                        if useStillImage {
                            // Handle still image from live photo
                        }
                    }
                }
            }
        }
    }
    
    private var photoGridView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                ForEach(photoLibraryManager.recentPhotos, id: \.localIdentifier) { asset in
                    PhotoThumbnailView(
                        asset: asset,
                        isSelected: selectedAssets.contains(asset),
                        showLivePhotoBadge: asset.mediaSubtypes.contains(.photoLive)
                    ) {
                        handleAssetSelection(asset)
                    }
                }
            }
            .padding(.top, 1)
        }
        .refreshable {
            await photoLibraryManager.loadRecentPhotos()
        }
        .overlay {
            if photoLibraryManager.isLoading {
                LoadingView(message: "Loading photos...")
            }
        }
    }
    
    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Photo Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please allow access to your photo library to select images.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private func handleAssetSelection(_ asset: PHAsset) {
        if allowsMultipleSelection {
            if selectedAssets.contains(asset) {
                selectedAssets.remove(asset)
            } else {
                selectedAssets.insert(asset)
            }
        } else {
            // Single selection - process immediately
            Task {
                if asset.mediaSubtypes.contains(.photoLive) {
                    // Handle Live Photo
                    if let livePhoto = await photoLibraryManager.loadLivePhoto(from: asset) {
                        selectedLivePhoto = livePhoto
                        showingLivePhotoPreview = true
                    }
                }
                
                if let image = await photoLibraryManager.loadImage(from: asset) {
                    onPhotosSelected([image])
                    dismiss()
                }
            }
        }
    }
    
    private func processSelectedPhotos() async {
        var images: [UIImage] = []
        
        for asset in selectedAssets {
            if let image = await photoLibraryManager.loadImage(from: asset) {
                images.append(image)
            }
        }
        
        if !images.isEmpty {
            onPhotosSelected(images)
            dismiss()
        }
    }
}

struct PhotoThumbnailView: View {
    let asset: PHAsset
    let isSelected: Bool
    let showLivePhotoBadge: Bool
    let onTap: () -> Void
    
    @State private var thumbnailImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let image = thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: (UIScreen.main.bounds.width - 4) / 3, height: (UIScreen.main.bounds.width - 4) / 3)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: (UIScreen.main.bounds.width - 4) / 3, height: (UIScreen.main.bounds.width - 4) / 3)
                    .overlay {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
            }
            
            // Live Photo badge
            if showLivePhotoBadge {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "livephoto")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .padding(4)
                    }
                    Spacer()
                }
            }
            
            // Selection indicator
            if isSelected {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .background(Color.white, in: Circle())
                            .padding(4)
                    }
                    Spacer()
                }
            }
        }
        .onTapGesture {
            onTap()
        }
        .task {
            await loadThumbnail()
        }
    }
    
    private func loadThumbnail() async {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isSynchronous = false
        
        let targetSize = CGSize(
            width: (UIScreen.main.bounds.width - 4) / 3 * UIScreen.main.scale,
            height: (UIScreen.main.bounds.width - 4) / 3 * UIScreen.main.scale
        )
        
        let image = await withCheckedContinuation { continuation in
            manager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
        
        await MainActor.run {
            self.thumbnailImage = image
            self.isLoading = false
        }
    }
}

struct LivePhotoPreviewView: View {
    let livePhoto: PHLivePhoto
    let onDecision: (Bool) -> Void
    
    var body: some View {
        VStack {
            // Live Photo preview would go here
            // For now, showing still image
            if let stillImage = livePhoto.stillDisplayImage {
                Image(uiImage: stillImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            HStack(spacing: 20) {
                Button("Use Still Image") {
                    onDecision(true)
                }
                .buttonStyle(.bordered)
                
                Button("Use Live Photo") {
                    onDecision(false)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .background(Color.black)
    }
}

// Extension to get still image from Live Photo
extension PHLivePhoto {
    var stillDisplayImage: UIImage? {
        // This would need additional implementation to extract still image
        // For now, returning nil
        return nil
    }
}

#Preview {
    PhotoPickerView { images in
        print("Selected \(images.count) images")
    }
}