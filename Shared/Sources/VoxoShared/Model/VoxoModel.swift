//
//  VoxoModel.swift
//  VoxoShared
//
//  The Core Data model, built in code.
//
//  Why not an .xcdatamodeld: SwiftPM's command-line build never invokes `momc` — it copies the
//  bundle verbatim — so a visual model cannot be loaded by `swift test` on macOS. Defining it here
//  keeps one source of truth that both apps and the tests load identically.
//
//  PLAN.md §11 still applies: a schema change means adding a NEW version builder below and
//  migrating onto it, never editing `version1` in place once anything has shipped.
//

import CoreData
import Foundation

public enum VoxoModel {
    public static let current = version1

    public static let version1: NSManagedObjectModel = {
        let model = NSManagedObjectModel()
        model.entities = [makeTodo(), makeSyncOp(), makeProcessedOp()]
        return model
    }()

    // MARK: - Entities

    /// PLAN.md §4, entity `Todo`.
    private static func makeTodo() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Todo"
        entity.managedObjectClassName = NSStringFromClass(TodoEntity.self)
        entity.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("title", .stringAttributeType),
            attribute("isDone", .booleanAttributeType, defaultValue: false),
            attribute("createdAt", .dateAttributeType),
            attribute("updatedAt", .dateAttributeType),
            attribute("completedAt", .dateAttributeType, optional: true),
            attribute("deletedAt", .dateAttributeType, optional: true),
            attribute("intervalOverride", .integer32AttributeType, defaultValue: Int32(0)),
            attribute("nextRemindAt", .dateAttributeType, optional: true),
            attribute("lastRemindedAt", .dateAttributeType, optional: true),
            attribute("originDevice", .stringAttributeType)
        ]
        // `id` is the sync key, so a duplicate insert must merge rather than fork.
        entity.uniquenessConstraints = [["id"]]
        entity.indexes = [
            index(named: "byIsDone", on: entity, properties: ["isDone"]),
            index(named: "byDeletedAt", on: entity, properties: ["deletedAt"])
        ]
        return entity
    }

    /// PLAN.md §4, entity `SyncOp` — only ever populated on the Watch.
    private static func makeSyncOp() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "SyncOp"
        entity.managedObjectClassName = NSStringFromClass(SyncOpEntity.self)
        entity.properties = [
            attribute("opId", .UUIDAttributeType),
            attribute("todoId", .UUIDAttributeType),
            attribute("type", .stringAttributeType),
            attribute("payload", .binaryDataAttributeType),
            attribute("createdAt", .dateAttributeType)
        ]
        entity.uniquenessConstraints = [["opId"]]
        entity.indexes = [index(named: "byCreatedAt", on: entity, properties: ["createdAt"])]
        return entity
    }

    /// Dedupe ledger for the phone. Not in PLAN.md §4 — see `ProcessedOpEntity`.
    private static func makeProcessedOp() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "ProcessedOp"
        entity.managedObjectClassName = NSStringFromClass(ProcessedOpEntity.self)
        entity.properties = [
            attribute("opId", .UUIDAttributeType),
            attribute("processedAt", .dateAttributeType)
        ]
        entity.uniquenessConstraints = [["opId"]]
        return entity
    }

    // MARK: - Builders

    private static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        optional: Bool = false,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        attribute.defaultValue = defaultValue
        return attribute
    }

    private static func index(
        named name: String,
        on entity: NSEntityDescription,
        properties: [String]
    ) -> NSFetchIndexDescription {
        let elements = properties.compactMap { propertyName -> NSFetchIndexElementDescription? in
            guard let property = entity.properties.first(where: { $0.name == propertyName }) else { return nil }
            return NSFetchIndexElementDescription(property: property, collationType: .binary)
        }
        return NSFetchIndexDescription(name: name, elements: elements)
    }
}
