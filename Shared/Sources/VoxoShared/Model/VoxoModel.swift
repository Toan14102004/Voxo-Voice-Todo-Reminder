//
//  VoxoModel.swift
//  VoxoShared
//
//  The Core Data model, built in code.
//
//  Why not an .xcdatamodeld: SwiftPM's command-line build never invokes `momc` — it copies the
//  bundle verbatim — so a visual model cannot be loaded by `swift test`.
//
//  PLAN.md §11: a schema change adds a NEW version below and migrates onto it. `version1` is
//  frozen; never edit it, or stores written by it stop migrating.
//

import CoreData
import Foundation

public enum VoxoModel {
    /// What the app opens today.
    public static let current = version2

    /// Oldest first. `StoreMigrator` walks this list to find the version a store was written with.
    public static let allVersions: [NSManagedObjectModel] = [version1, version2]

    // MARK: - Version 1 (frozen)

    public static let version1: NSManagedObjectModel = {
        let model = NSManagedObjectModel()
        model.entities = [makeTodoV1(), makeSyncOp(), makeProcessedOp()]
        return model
    }()

    // MARK: - Version 2 — Tidy spec (PLAN.md §4)

    /// Adds `priority`, `dueAt`, `listId`, `repeatRule` and `note` to `Todo`, plus `TodoList`.
    ///
    /// `note` was added after v2 was first written but before any device ever opened a v2 store,
    /// so amending in place was still safe. Once a build with v2 ships, this becomes frozen too.
    /// Purely additive, so Core Data can infer the mapping from version 1.
    public static let version2: NSManagedObjectModel = {
        let model = NSManagedObjectModel()
        model.entities = [makeTodoV2(), makeTodoList(), makeSyncOp(), makeProcessedOp()]
        return model
    }()

    // MARK: - Entities

    private static func todoBase() -> [NSAttributeDescription] {
        [
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
    }

    private static func makeTodoV1() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Todo"
        entity.managedObjectClassName = NSStringFromClass(TodoEntity.self)
        entity.properties = todoBase()
        entity.uniquenessConstraints = [["id"]]
        entity.indexes = [
            index(named: "byIsDone", on: entity, properties: ["isDone"]),
            index(named: "byDeletedAt", on: entity, properties: ["deletedAt"])
        ]
        return entity
    }

    private static func makeTodoV2() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Todo"
        entity.managedObjectClassName = NSStringFromClass(TodoEntity.self)
        entity.properties = todoBase() + [
            // 0 none · 1 low · 2 medium · 3 high — see TodoPriority.
            attribute("priority", .integer16AttributeType, defaultValue: Int16(0)),
            attribute("dueAt", .dateAttributeType, optional: true),
            attribute("listId", .UUIDAttributeType, optional: true),
            // "daily" / "weekly" / nil — how often the task itself recurs, which is not the same
            // as intervalOverride, the cadence of its reminders.
            attribute("repeatRule", .stringAttributeType, optional: true),
            // Free text under the title, shown on the detail screen and Quick add.
            attribute("note", .stringAttributeType, optional: true)
        ]
        entity.uniquenessConstraints = [["id"]]
        entity.indexes = [
            index(named: "byIsDone", on: entity, properties: ["isDone"]),
            index(named: "byDeletedAt", on: entity, properties: ["deletedAt"]),
            index(named: "byDueAt", on: entity, properties: ["dueAt"]),
            index(named: "byListId", on: entity, properties: ["listId"])
        ]
        return entity
    }

    /// PLAN.md §4, entity `TodoList`.
    private static func makeTodoList() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "TodoList"
        entity.managedObjectClassName = NSStringFromClass(TodoListEntity.self)
        entity.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("name", .stringAttributeType),
            attribute("colorHex", .stringAttributeType),
            // SF Symbol name. The design calls this "emoji", but the project ships SF Symbols
            // (see VoxoIcon), so a symbol name keeps one icon system.
            attribute("icon", .stringAttributeType),
            attribute("createdAt", .dateAttributeType),
            attribute("updatedAt", .dateAttributeType),
            attribute("deletedAt", .dateAttributeType, optional: true)
        ]
        entity.uniquenessConstraints = [["id"]]
        entity.indexes = [index(named: "byListDeletedAt", on: entity, properties: ["deletedAt"])]
        return entity
    }

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
