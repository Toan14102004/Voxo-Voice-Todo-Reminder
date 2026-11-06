//
//  PersistenceStack.swift
//  VoxoShared
//

import CoreData
import Foundation

/// Core Data stack for one device.
///
/// PLAN.md §2: each device keeps its own store. The `.sqlite` file is never shared between
/// Watch and iPhone — they reconcile through WCSession, not through a common file.
public final class PersistenceStack {
    public let container: NSPersistentContainer

    private static let modelName = "VoxoModel"

    public init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: Self.modelName, managedObjectModel: VoxoModel.current)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError {
            fatalError("Không mở được store: \(loadError)")
        }

        // Uniqueness constraints on id/opId turn a duplicate insert into a merge instead of a crash.
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
