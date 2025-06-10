//
//  PhotoEditView.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import SwiftUI
import Photos

struct PhotoEditView: View {
    @EnvironmentObject private var photoManager: PhotoManager
    @EnvironmentObject private var navigationState: NavigationState
    @EnvironmentObject private var dependencies: DependencyContainer
    
    @State private var showingShareSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Main image display
                imageDisplayView
                    .frame(height: geometry.size.height * 0.8)
                
                // Action buttons
                actionButtonsView
                    .frame(height: geometry.size.height * 0.2)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    navigationState.navigateToRoot()
                }
                .foregroundStyle(.primary)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = photoManager.filteredImage {
                ShareSheet(items: [resizedImageForSharing(image)])
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var imageDisplayView: some View {
        ZStack {
            Color.white
            
            if let image = photoManager.filteredImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipped()
            } else {
                Text("No Image Selected")
                    .foregroundColor(.black)
                    .font(.headline)
            }
        }
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 16) {
            // Top row - main actions
            HStack(spacing: 20) {
                // Save to Photos
                EditActionButton(
                    title: "Save to Photos",
                    icon: "square.and.arrow.down",
                    backgroundColor: .green
                ) {
                    saveToPhotos()
                }
                
                // Share
                EditActionButton(
                    title: "Share",
                    icon: "square.and.arrow.up",
                    backgroundColor: .green
                ) {
                    showingShareSheet = true
                }
            }
            .padding(.horizontal, 20)
            
            // Review App button - smaller
            Button(action: {
                reviewApp()
            }) {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.caption)
                    Text("Review App")
                        .font(.caption)
                }
                .foregroundStyle(.green)
                .frame(height: 30)
            }
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    private func saveToPhotos() {
        guard let image = photoManager.filteredImage else { return }
        
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    UIImageWriteToSavedPhotosAlbum(
                        image,
                        nil,
                        nil,
                        nil
                    )
                    
                    alertTitle = "Oil Painting Complete!"
                    alertMessage = "Oil Painting has been saved to the camera roll."
                    showingAlert = true
                    
                case .denied, .restricted:
                    alertTitle = "Permission Required"
                    alertMessage = "Please allow access to Photos in Settings to save your image."
                    showingAlert = true
                    
                case .notDetermined:
                    break
                    
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func reviewApp() {
        let reviewURL = "itms-apps://itunes.apple.com/app/id827491007"
        if let url = URL(string: reviewURL) {
            UIApplication.shared.open(url)
        }
    }
    
    private func resizedImageForSharing(_ image: UIImage) -> UIImage {
        let targetSize = CGSize(width: 640, height: 640)
        return resizeImage(image, to: targetSize)
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

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct EditActionButton: View {
    let title: String
    let icon: String
    let backgroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: backgroundColor.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}

#Preview {
    NavigationStack {
        PhotoEditView()
            .environmentObject({
                let manager = PhotoManager()
                manager.filteredImage = UIImage(systemName: "photo.fill")
                return manager
            }())
            .environmentObject(DependencyContainer.shared)
    }
}