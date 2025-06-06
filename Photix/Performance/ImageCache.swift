//
//  ImageCache.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import UIKit
import Combine

@MainActor
class ImageCache: ObservableObject {
    static let shared = ImageCache()
    
    private var cache = NSCache<NSString, UIImage>()
    private var diskCache: DiskCache
    private var memoryWarningObserver: NSObjectProtocol?
    
    @Published var cacheHitRate: Double = 0.0
    @Published var totalRequests: Int = 0
    @Published var cacheHits: Int = 0
    
    private init() {
        // Configure memory cache
        cache.countLimit = 50 // Limit number of images
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB memory limit
        
        // Setup disk cache
        diskCache = DiskCache()
        
        // Handle memory warnings
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearMemoryCache()
        }
    }
    
    deinit {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func image(for key: String) -> UIImage? {
        totalRequests += 1
        
        // Check memory cache first
        if let image = cache.object(forKey: key as NSString) {
            cacheHits += 1
            updateHitRate()
            return image
        }
        
        // For disk cache, we'll need to load asynchronously
        // This method only returns memory cached images for synchronous access
        updateHitRate()
        return nil
    }
    
    func imageAsync(for key: String) async -> UIImage? {
        totalRequests += 1
        
        // Check memory cache first
        if let image = cache.object(forKey: key as NSString) {
            cacheHits += 1
            updateHitRate()
            return image
        }
        
        // Check disk cache
        if let imageData = await diskCache.data(for: key),
           let image = UIImage(data: imageData) {
            // Store in memory cache for faster access
            setImage(image, for: key, memoryOnly: true)
            cacheHits += 1
            updateHitRate()
            return image
        }
        
        updateHitRate()
        return nil
    }
    
    func setImage(_ image: UIImage, for key: String, memoryOnly: Bool = false) {
        // Calculate cost based on image size
        let cost = Int(image.size.width * image.size.height * 4) // RGBA bytes
        cache.setObject(image, forKey: key as NSString, cost: cost)
        
        // Also save to disk cache unless memoryOnly is true
        if !memoryOnly {
            Task.detached {
                if let data = image.jpegData(compressionQuality: 0.8) {
                    await self.diskCache.setData(data, for: key)
                }
            }
        }
    }
    
    func removeImage(for key: String) {
        cache.removeObject(forKey: key as NSString)
        Task.detached {
            await self.diskCache.removeData(for: key)
        }
    }
    
    func clearMemoryCache() {
        cache.removeAllObjects()
    }
    
    func clearAllCache() {
        cache.removeAllObjects()
        Task.detached {
            await self.diskCache.clearAll()
        }
    }
    
    private func updateHitRate() {
        cacheHitRate = totalRequests > 0 ? Double(cacheHits) / Double(totalRequests) : 0.0
    }
    
    // MARK: - Cache Statistics
    
    func getCacheStatistics() -> CacheStatistics {
        let memoryUsage = cache.totalCostLimit > 0 ? Double(cache.totalCostLimit) / 1024 / 1024 : 0
        
        return CacheStatistics(
            hitRate: cacheHitRate,
            totalRequests: totalRequests,
            cacheHits: cacheHits,
            memoryUsageMB: memoryUsage,
            itemCount: cache.countLimit
        )
    }
}

struct CacheStatistics {
    let hitRate: Double
    let totalRequests: Int
    let cacheHits: Int
    let memoryUsageMB: Double
    let itemCount: Int
}

// MARK: - Disk Cache

actor DiskCache {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxDiskSize: Int = 100 * 1024 * 1024 // 100MB
    
    init() {
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cacheDir.appendingPathComponent("FilteredImages")
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Start cleanup task
        Task {
            await cleanupOldFiles()
        }
    }
    
    func data(for key: String) -> Data? {
        let url = cacheDirectory.appendingPathComponent(key.md5)
        return try? Data(contentsOf: url)
    }
    
    func setData(_ data: Data, for key: String) {
        let url = cacheDirectory.appendingPathComponent(key.md5)
        try? data.write(to: url)
        
        // Check if we need to cleanup
        Task {
            await cleanupIfNeeded()
        }
    }
    
    func removeData(for key: String) {
        let url = cacheDirectory.appendingPathComponent(key.md5)
        try? fileManager.removeItem(at: url)
    }
    
    func clearAll() {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        
        for case let fileURL as URL in enumerator {
            try? fileManager.removeItem(at: fileURL)
        }
    }
    
    private func cleanupIfNeeded() async {
        let size = calculateDirectorySize()
        if size > maxDiskSize {
            await cleanupOldFiles()
        }
    }
    
    private func cleanupOldFiles() {
        guard let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return }
        
        var files: [(URL, Date)] = []
        
        for case let fileURL as URL in enumerator {
            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let modificationDate = attributes[.modificationDate] as? Date {
                files.append((fileURL, modificationDate))
            }
        }
        
        // Sort by modification date (oldest first)
        files.sort { $0.1 < $1.1 }
        
        // Remove oldest files until we're under the limit
        var currentSize = calculateDirectorySize()
        let targetSize = maxDiskSize * 3 / 4 // Clean up to 75% of max size
        
        for (fileURL, _) in files {
            if currentSize <= targetSize { break }
            
            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let fileSize = attributes[.size] as? Int {
                try? fileManager.removeItem(at: fileURL)
                currentSize -= fileSize
            }
        }
    }
    
    private func calculateDirectorySize() -> Int {
        guard let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }
        
        var totalSize = 0
        
        for case let fileURL as URL in enumerator {
            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let fileSize = attributes[.size] as? Int {
                totalSize += fileSize
            }
        }
        
        return totalSize
    }
}

// MARK: - String MD5 Extension

extension String {
    var md5: String {
        // Simple hash implementation for cache keys
        let hashValue = abs(self.hashValue)
        return String(hashValue, radix: 16)
    }
}