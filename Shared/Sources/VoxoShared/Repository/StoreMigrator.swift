//
//  StoreMigrator.swift
//  VoxoShared
//

import CoreData
import Foundation

/// Migrates an existing store onto the current model.
///
/// Core Data's automatic lightweight migration cannot be used here. It finds the *source* model by
/// searching the bundle's compiled `.momd` for one matching the hashes recorded in the store — and
/// this project builds its models in code, so there is no `.momd` to search. The store would simply
/// fail to open with "model used to open the store is incompatible".
///
/// So the source model is located by hand: compare the store's metadata against each known version
/// in `VoxoModel.allVersions`, then run an inferred mapping for each step up to the current one.
public enum StoreMigrator {
    public enum MigrationError: Error, CustomStringConvertible {
        case unknownStoreVersion
        case noInferredMapping(from: Int, to: Int)

        public var description: String {
            switch self {
            case .unknownStoreVersion:
                "Store không khớp phiên bản model nào đã biết — có thể được tạo bởi bản app mới hơn."
            case let .noInferredMapping(from, to):
                "Không suy ra được mapping từ version \(from) sang \(to); cần mapping model viết tay."
            }
        }
    }

    /// Brings the store at `storeURL` up to `VoxoModel.current`.
    ///
    /// Does nothing when the file does not exist yet (a fresh install) or is already current.
    public static func migrateIfNeeded(
        storeURL: URL,
        versions: [NSManagedObjectModel] = VoxoModel.allVersions,
        type: NSPersistentStore.StoreType = .sqlite
    ) throws {
        guard FileManager.default.fileExists(atPath: storeURL.path) else { return }

        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
            type: type,
            at: storeURL
        )

        guard let target = versions.last else { return }
        if target.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) { return }

        guard let sourceIndex = versions.firstIndex(where: {
            $0.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        }) else {
            throw MigrationError.unknownStoreVersion
        }

        // One step at a time, so a future v2 -> v3 only has to describe that single hop.
        for step in sourceIndex..<(versions.count - 1) {
            try migrate(storeURL: storeURL, from: versions[step], to: versions[step + 1], step: step, type: type)
        }
    }

    private static func migrate(
        storeURL: URL,
        from source: NSManagedObjectModel,
        to destination: NSManagedObjectModel,
        step: Int,
        type: NSPersistentStore.StoreType
    ) throws {
        let mapping: NSMappingModel
        do {
            mapping = try NSMappingModel.inferredMappingModel(forSourceModel: source, destinationModel: destination)
        } catch {
            throw MigrationError.noInferredMapping(from: step + 1, to: step + 2)
        }

        let manager = NSMigrationManager(sourceModel: source, destinationModel: destination)
        let temporaryURL = storeURL
            .deletingLastPathComponent()
            .appendingPathComponent("migration-\(UUID().uuidString).sqlite")

        try manager.migrateStore(
            from: storeURL,
            type: type,
            options: nil,
            mapping: mapping,
            to: temporaryURL,
            type: type,
            options: nil
        )

        // Swap the migrated file in only after the migration succeeded, so a failure leaves the
        // original store untouched rather than half-converted.
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: destination)
        try coordinator.replacePersistentStore(
            at: storeURL,
            withPersistentStoreFrom: temporaryURL,
            type: type
        )
        try? coordinator.destroyPersistentStore(at: temporaryURL, type: type)
    }
}
