//
//  DataManager.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import Foundation
import CoreData

actor DataManager {
    static let shared = DataManager()
    
    private init() {}
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Photix")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // In a production app, you should handle this error appropriately
                print("Core Data error: \(error), \(error.userInfo)")
            }
        }
        
        // Enable automatic merging of changes from parent
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - Core Data Operations
    
    func save() async throws {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            try await context.perform {
                try context.save()
            }
        }
    }
    
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            persistentContainer.performBackgroundTask { context in
                do {
                    let result = try block(context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Database Management
    
    func initializeDatabase() async throws {
        try await performBackgroundTask { context in
            // Clear existing data if needed
            let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Photo")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            try context.execute(deleteRequest)
            try context.save()
        }
    }
    
    func prePopulateDatabase() async throws {
        // Add any default data here if needed
        try await save()
    }
    
    func isDatabaseEmpty() async throws -> Bool {
        return try await performBackgroundTask { context in
            let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Photo")
            request.fetchLimit = 1
            let count = try context.count(for: request)
            return count == 0
        }
    }
    
    // MARK: - Photo Operations (if needed for future features)
    
    func savePhoto(imageData: Data, filterType: String) async throws {
        try await performBackgroundTask { context in
            let photo = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: context)
            photo.setValue(imageData, forKey: "imageData")
            photo.setValue(filterType, forKey: "filterType")
            photo.setValue(Date(), forKey: "dateCreated")
            try context.save()
        }
    }
    
    func fetchPhotos() async throws -> [NSManagedObject] {
        return try await performBackgroundTask { context in
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Photo")
            request.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]
            return try context.fetch(request)
        }
    }
    
    func deletePhoto(_ photo: NSManagedObject) async throws {
        try await performBackgroundTask { context in
            let objectID = photo.objectID
            let photoToDelete = try context.existingObject(with: objectID)
            context.delete(photoToDelete)
            try context.save()
        }
    }
}