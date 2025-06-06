//
//  PhotoLibraryManager.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import Photos
import UIKit
import SwiftUI
import Combine

@MainActor
class PhotoLibraryManager: NSObject, ObservableObject {
    @Published var hasPermission = false
    @Published var recentPhotos: [PHAsset] = []
    @Published var isLoading = false
    @Published var error: PhotoLibraryError?
    
    private let imageManager = PHImageManager.default()
    private let fetchOptions: PHFetchOptions = {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = 50
        return options
    }()
    
    enum PhotoLibraryError: Error, LocalizedError {
        case permissionDenied
        case fetchFailed
        case imageLoadFailed
        case assetNotFound
        
        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Photo library access denied"
            case .fetchFailed:
                return "Failed to fetch photos"
            case .imageLoadFailed:
                return "Failed to load image"
            case .assetNotFound:
                return "Photo not found"
            }
        }
    }
    
    override init() {
        super.init()
        Task {
            await requestPermission()
        }
    }
    
    func requestPermission() async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            hasPermission = true
            await loadRecentPhotos()
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            hasPermission = newStatus == .authorized || newStatus == .limited
            if hasPermission {
                await loadRecentPhotos()
            }
        case .denied, .restricted:
            hasPermission = false
            error = .permissionDenied
        @unknown default:
            hasPermission = false
            error = .permissionDenied
        }
    }
    
    func loadRecentPhotos() async {
        guard hasPermission else { return }
        
        isLoading = true
        error = nil
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        recentPhotos = assets
        isLoading = false
    }
    
    func loadLastPhoto() async -> UIImage? {
        guard hasPermission else { return nil }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        guard let lastAsset = fetchResult.firstObject else { return nil }
        
        return await loadImage(from: lastAsset, targetSize: PHImageManagerMaximumSize)
    }
    
    func loadImage(from asset: PHAsset, targetSize: CGSize = PHImageManagerMaximumSize) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                continuation.resume(returning: image)
            }
        }
    }
    
    func loadLivePhoto(from asset: PHAsset) async -> PHLivePhoto? {
        guard asset.mediaSubtypes.contains(.photoLive) else { return nil }
        
        return await withCheckedContinuation { continuation in
            let options = PHLivePhotoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            
            imageManager.requestLivePhoto(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { livePhoto, info in
                continuation.resume(returning: livePhoto)
            }
        }
    }
    
    func saveImage(_ image: UIImage) async -> Bool {
        guard hasPermission else { return false }
        
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetCreationRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if let error = error {
                    print("Error saving image: \(error)")
                }
                continuation.resume(returning: success)
            }
        }
    }
    
    func deleteAsset(_ asset: PHAsset) async -> Bool {
        guard hasPermission else { return false }
        
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets([asset] as NSArray)
            }) { success, error in
                if let error = error {
                    print("Error deleting asset: \(error)")
                }
                continuation.resume(returning: success)
            }
        }
    }
}