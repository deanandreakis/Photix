//
//  BackgroundProcessor.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import UIKit
import Combine

@MainActor
class BackgroundProcessor: ObservableObject {
    static let shared = BackgroundProcessor()
    
    @Published var activeProcessingJobs: [ProcessingJob] = []
    @Published var completedJobs: [ProcessingJob] = []
    @Published var processingProgress: Double = 0.0
    @Published var isProcessing = false
    
    private var jobCounter = 0
    
    private init() {}
    
    enum ProcessingPriority {
        case low, normal, high
        
        var taskPriority: TaskPriority {
            switch self {
            case .low: return .background
            case .normal: return .medium
            case .high: return .high
            }
        }
    }
    
    struct ProcessingJob: Identifiable, Equatable {
        let id: String
        let name: String
        let priority: ProcessingPriority
        let estimatedDuration: TimeInterval
        var progress: Double = 0.0
        var isCompleted = false
        var error: Error?
        
        static func == (lhs: ProcessingJob, rhs: ProcessingJob) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    // MARK: - Filter Processing
    
    func processFiltersInBackground(
        for image: UIImage,
        filterTypes: [FilterType],
        priority: ProcessingPriority = .normal
    ) async -> [FilteredImage] {
        let jobId = "filter_batch_\(jobCounter)"
        jobCounter += 1
        
        let job = ProcessingJob(
            id: jobId,
            name: "Processing \(filterTypes.count) filters",
            priority: priority,
            estimatedDuration: Double(filterTypes.count) * 0.5
        )
        
        await addJob(job)
        
        return await withTaskGroup(of: FilteredImage?.self) { group in
            let metalRenderer = MetalFilterRenderer()
            var results: [FilteredImage] = []
            
            for (index, filterType) in filterTypes.enumerated() {
                group.addTask(priority: priority.taskPriority) {
                    let filteredImage = await metalRenderer.renderFilterPreview(
                        image: image,
                        filterType: filterType,
                        intensity: 1.0
                    )
                    
                    // Update progress
                    let progress = Double(index + 1) / Double(filterTypes.count)
                    await self.updateJobProgress(jobId: jobId, progress: progress)
                    
                    if let filteredImage = filteredImage {
                        return FilteredImage(
                            image: filteredImage,
                            name: filterType.rawValue,
                            filterType: filterType
                        )
                    }
                    return nil
                }
            }
            
            for await result in group {
                if let filteredImage = result {
                    results.append(filteredImage)
                }
            }
            
            await completeJob(jobId: jobId)
            return results.sorted { $0.filterType.rawValue < $1.filterType.rawValue }
        }
    }
    
    // MARK: - Batch Image Processing
    
    func processBatchImages(
        images: [UIImage],
        filterType: FilterType,
        priority: ProcessingPriority = .normal
    ) async -> [UIImage] {
        let jobId = "batch_images_\(jobCounter)"
        jobCounter += 1
        
        let job = ProcessingJob(
            id: jobId,
            name: "Processing \(images.count) images",
            priority: priority,
            estimatedDuration: Double(images.count) * 1.0
        )
        
        await addJob(job)
        
        return await withTaskGroup(of: (Int, UIImage?).self) { group in
            let metalRenderer = MetalFilterRenderer()
            
            for (index, image) in images.enumerated() {
                group.addTask(priority: priority.taskPriority) {
                    let result = await metalRenderer.renderFilterPreview(
                        image: image,
                        filterType: filterType,
                        intensity: 1.0
                    )
                    
                    // Update progress
                    let progress = Double(index + 1) / Double(images.count)
                    await self.updateJobProgress(jobId: jobId, progress: progress)
                    
                    return (index, result)
                }
            }
            
            var results: [(Int, UIImage)] = []
            for await (index, image) in group {
                if let image = image {
                    results.append((index, image))
                }
            }
            
            await completeJob(jobId: jobId)
            
            // Sort by original index to maintain order
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
    
    // MARK: - Thumbnail Generation
    
    func generateThumbnails(
        for images: [UIImage],
        targetSize: CGSize,
        priority: ProcessingPriority = .low
    ) async -> [UIImage] {
        let jobId = "thumbnails_\(jobCounter)"
        jobCounter += 1
        
        let job = ProcessingJob(
            id: jobId,
            name: "Generating \(images.count) thumbnails",
            priority: priority,
            estimatedDuration: Double(images.count) * 0.1
        )
        
        await addJob(job)
        
        return await withTaskGroup(of: (Int, UIImage?).self) { group in
            for (index, image) in images.enumerated() {
                group.addTask(priority: priority.taskPriority) {
                    let thumbnail = await self.generateThumbnail(image: image, targetSize: targetSize)
                    
                    // Update progress
                    let progress = Double(index + 1) / Double(images.count)
                    await self.updateJobProgress(jobId: jobId, progress: progress)
                    
                    return (index, thumbnail)
                }
            }
            
            var results: [(Int, UIImage)] = []
            for await (index, thumbnail) in group {
                if let thumbnail = thumbnail {
                    results.append((index, thumbnail))
                }
            }
            
            await completeJob(jobId: jobId)
            
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
    
    private func generateThumbnail(image: UIImage, targetSize: CGSize) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            Task.detached {
                let renderer = UIGraphicsImageRenderer(size: targetSize)
                let thumbnail = renderer.image { context in
                    let aspectRatio = image.size.width / image.size.height
                    let targetAspectRatio = targetSize.width / targetSize.height
                    
                    var drawRect: CGRect
                    if aspectRatio > targetAspectRatio {
                        // Image is wider
                        let height = targetSize.height
                        let width = height * aspectRatio
                        drawRect = CGRect(x: (targetSize.width - width) / 2, y: 0, width: width, height: height)
                    } else {
                        // Image is taller
                        let width = targetSize.width
                        let height = width / aspectRatio
                        drawRect = CGRect(x: 0, y: (targetSize.height - height) / 2, width: width, height: height)
                    }
                    
                    image.draw(in: drawRect)
                }
                continuation.resume(returning: thumbnail)
            }
        }
    }
    
    // MARK: - Job Management
    
    private func addJob(_ job: ProcessingJob) async {
        activeProcessingJobs.append(job)
        updateProcessingState()
    }
    
    private func updateJobProgress(jobId: String, progress: Double) async {
        if let index = activeProcessingJobs.firstIndex(where: { $0.id == jobId }) {
            activeProcessingJobs[index].progress = progress
            updateOverallProgress()
        }
    }
    
    private func completeJob(jobId: String, error: Error? = nil) async {
        if let index = activeProcessingJobs.firstIndex(where: { $0.id == jobId }) {
            var job = activeProcessingJobs[index]
            job.isCompleted = true
            job.progress = 1.0
            job.error = error
            
            activeProcessingJobs.remove(at: index)
            completedJobs.append(job)
            
            // Keep only recent completed jobs
            if completedJobs.count > 20 {
                completedJobs.removeFirst(completedJobs.count - 20)
            }
            
            updateProcessingState()
        }
    }
    
    private func updateProcessingState() {
        isProcessing = !activeProcessingJobs.isEmpty
        updateOverallProgress()
    }
    
    private func updateOverallProgress() {
        if activeProcessingJobs.isEmpty {
            processingProgress = 0.0
        } else {
            let totalProgress = activeProcessingJobs.reduce(0.0) { $0 + $1.progress }
            processingProgress = totalProgress / Double(activeProcessingJobs.count)
        }
    }
    
    // MARK: - Public Interface
    
    func cancelAllJobs() {
        activeProcessingJobs.removeAll()
        updateProcessingState()
    }
    
    func getJobStatus(id: String) -> ProcessingJob? {
        return activeProcessingJobs.first { $0.id == id } ?? 
               completedJobs.first { $0.id == id }
    }
    
    func clearCompletedJobs() {
        completedJobs.removeAll()
    }
}