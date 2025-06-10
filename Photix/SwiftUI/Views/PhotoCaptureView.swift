//
//  PhotoCaptureView.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import SwiftUI
import PhotosUI
import Photos

struct PhotoCaptureView: View {
    @EnvironmentObject private var photoManager: PhotoManager
    @EnvironmentObject private var navigationState: NavigationState
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingSettings = false
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let isIPad = UIDevice.current.userInterfaceIdiom == .pad
            
            ZStack {
                // Background pattern
                PatternBackgroundView()
                
                if isLandscape {
                    // Landscape layout: side by side
                    HStack(spacing: isIPad ? 100 : 60) {
                        // Left side: Logo and title
                        VStack(spacing: isIPad ? 30 : 20) {
                            Image("General")
                                .resizable()
                                .scaledToFit()
                                .frame(width: isIPad ? 150 : 100, height: isIPad ? 150 : 100)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(radius: 8)
                            
                            Text("OilPaintPlus")
                                .font(isIPad ? .largeTitle : .title)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                        
                        // Right side: Action buttons
                        VStack(spacing: isIPad ? 24 : 16) {
                            ActionButton(
                                title: "Take Photo",
                                icon: "camera.fill",
                                action: {
                                    showingCamera = true
                                }
                            )
                            
                            PhotosPicker(
                                selection: $selectedPhotoItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                ActionButtonLabel(
                                    title: "Choose from Library",
                                    icon: "photo.on.rectangle"
                                )
                            }
                            
                            ActionButton(
                                title: "Edit Last Photo",
                                icon: "clock.arrow.circlepath",
                                action: {
                                    Task {
                                        await editLastPhoto()
                                    }
                                }
                            )
                        }
                        .frame(maxWidth: isIPad ? 400 : 280)
                    }
                } else {
                    // Portrait layout: vertical
                    VStack(spacing: isIPad ? 60 : 40) {
                        Spacer()
                        
                        // App title/logo area
                        VStack(spacing: isIPad ? 24 : 16) {
                            Image("General")
                                .resizable()
                                .scaledToFit()
                                .frame(width: isIPad ? 180 : 120, height: isIPad ? 180 : 120)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(radius: 8)
                            
                            Text("OilPaintPlus")
                                .font(isIPad ? .system(size: 48, weight: .bold) : .largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                        
                        Spacer()
                        
                        // Action buttons
                        VStack(spacing: isIPad ? 28 : 20) {
                            ActionButton(
                                title: "Take Photo",
                                icon: "camera.fill",
                                action: {
                                    showingCamera = true
                                }
                            )
                            
                            PhotosPicker(
                                selection: $selectedPhotoItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                ActionButtonLabel(
                                    title: "Choose from Library",
                                    icon: "photo.on.rectangle"
                                )
                            }
                            
                            ActionButton(
                                title: "Edit Last Photo",
                                icon: "clock.arrow.circlepath",
                                action: {
                                    Task {
                                        await editLastPhoto()
                                    }
                                }
                            )
                        }
                        .padding(.horizontal, isIPad ? 100 : 40)
                        .frame(maxWidth: isIPad ? 600 : .infinity)
                        
                        Spacer()
                    }
                }
                
                // Settings gear icon in top right
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .padding(.top, 50)
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView { image in
                photoManager.setImage(image)
                navigationState.navigateTo(.filters)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(StoreManager.shared)
                .environmentObject(DependencyContainer.shared)
        }
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                guard let newItem = newItem else { 
                    print("PhotoCaptureView: selectedPhotoItem is nil")
                    return 
                }
                
                print("PhotoCaptureView: Loading selected photo...")
                do {
                    if let data = try await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        print("PhotoCaptureView: Image loaded successfully, size: \(image.size)")
                        photoManager.setImage(image)
                        print("PhotoCaptureView: Navigating to filters...")
                        navigationState.navigateTo(.filters)
                        print("PhotoCaptureView: Navigation called")
                    } else {
                        print("PhotoCaptureView: Failed to convert data to image")
                    }
                } catch {
                    print("PhotoCaptureView: Failed to load image: \(error)")
                }
            }
        }
    }
    
    private func editLastPhoto() async {
        // Check photo library permission
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        let finalStatus: PHAuthorizationStatus
        if status == .authorized || status == .limited {
            finalStatus = status
        } else {
            // Request permission if not granted
            finalStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }
        
        guard finalStatus == .authorized || finalStatus == .limited else {
            print("Photo library access denied")
            return
        }
        
        // Fetch the most recent photo
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        guard let lastAsset = fetchResult.firstObject else {
            print("No photos found in library")
            return
        }
        
        // Request the image from the asset
        let imageManager = PHImageManager.default()
        let targetSize = CGSize(width: 1024, height: 1024) // Good size for processing
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        
        await withCheckedContinuation { continuation in
            imageManager.requestImage(for: lastAsset, targetSize: targetSize, contentMode: .aspectFit, options: options) { image, info in
                guard let image = image else {
                    print("Failed to load image from asset")
                    continuation.resume()
                    return
                }
                
                DispatchQueue.main.async {
                    print("EditLastPhoto: Image loaded successfully, size: \(image.size)")
                    self.photoManager.setImage(image)
                    self.navigationState.navigateTo(.filters)
                    continuation.resume()
                }
            }
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ActionButtonLabel(title: title, icon: icon)
        }
    }
}

struct ActionButtonLabel: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 24)
            
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(
            LinearGradient(
                colors: [Color.green, Color.green.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

struct PatternBackgroundView: View {
    var body: some View {
        Image("Pattern")
            .resizable(resizingMode: .tile)
            .ignoresSafeArea()
            .opacity(0.1)
    }
}

#Preview {
    ContentView()
        .environmentObject(PhotoManager())
        .environmentObject(StoreManager.shared)
}