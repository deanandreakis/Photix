//
//  PhotoCaptureView.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import SwiftUI
import PhotosUI

struct PhotoCaptureView: View {
    @EnvironmentObject private var photoManager: PhotoManager
    @EnvironmentObject private var navigationState: NavigationState
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background pattern
                PatternBackgroundView()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // App title/logo area
                    VStack(spacing: 16) {
                        Image("General")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 8)
                        
                        Text("Photix")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 20) {
                        // Take Photo Button
                        ActionButton(
                            title: "Take Photo",
                            icon: "camera.fill",
                            action: {
                                showingCamera = true
                            }
                        )
                        
                        // Choose Existing Button
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
                        
                        // Edit Last Photo Button
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
                    .padding(.horizontal, 40)
                    
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
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                guard let newItem = newItem else { return }
                do {
                    if let data = try await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        photoManager.setImage(image)
                        navigationState.navigateTo(.filters)
                    }
                } catch {
                    print("Failed to load image: \(error)")
                }
            }
        }
    }
    
    private func editLastPhoto() async {
        // Implementation to get the last photo from Photos library
        // This would require PHPhotoLibrary access
        print("Edit last photo functionality would be implemented here")
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
                colors: [Color.blue, Color.blue.opacity(0.8)],
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